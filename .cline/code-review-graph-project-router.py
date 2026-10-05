"""Routeur fail-closed et adaptateur de protocole MCP pour code-review-graph.

Ce script est utilise comme commande MCP dans la configuration globale Cline.
Il identifie le workspace actif de l'extension host VS Code et ne demarre le
serveur code-review-graph que si le workspace appartient explicitement a la
liste allowlist des projets autorises.

De plus, code-review-graph expose un transport stdio base sur du NDJSON
(une ligne JSON par message), tandis que les clients MCP standards (Cline,
SDK officiel) utilisent le format binaire "Content-Length: N\r\n\r\n<json>".
Ce script fait la traduction bidirectionnelle entre les deux formats.

Si l'identification n'est pas unique ou si le workspace n'est pas autorise,
le routeur sort avec un code d'erreur sans demarrer de serveur (fail-closed).
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
import threading
from pathlib import Path
from urllib.parse import unquote, urlparse


# Liste allowlist des projets autorises.
PROJECTS = (
    (
        Path(r"D:\Projets\HIVMeet\hivmeet").resolve(),
        Path(r"D:\Projets\HIVMeet\hivmeet\.venv\Scripts\code-review-graph.exe"),
    ),
    (
        Path(r"D:\Projets\HIVMeet\env\hivmeet_backend").resolve(),
        Path(r"D:\Projets\HIVMeet\env\hivmeet_backend\.venv\Scripts\code-review-graph.exe"),
    ),
)


def is_within(candidate: Path, root: Path) -> bool:
    candidate_norm = os.path.normcase(str(candidate.resolve()))
    root_norm = os.path.normcase(str(root.resolve()))
    try:
        return os.path.commonpath((candidate_norm, root_norm)) == root_norm
    except ValueError:
        return False


def file_uri_to_path(value: str) -> Path | None:
    parsed = urlparse(value)
    if parsed.scheme != "file" or parsed.netloc not in ("", "localhost"):
        return None
    decoded = unquote(parsed.path)
    if os.name == "nt" and re.match(r"^/[A-Za-z]:/", decoded):
        decoded = decoded[1:]
    return Path(decoded.replace("/", os.sep))


def vscode_data_roots() -> tuple[Path, ...]:
    home = Path.home()
    if os.name == "nt":
        appdata = os.environ.get("APPDATA")
        if not appdata:
            return ()
        base = Path(appdata)
    elif sys.platform == "darwin":
        base = home / "Library" / "Application Support"
    else:
        base = Path(os.environ.get("XDG_CONFIG_HOME", home / ".config"))
    return tuple(base / name for name in ("Code", "Code - Insiders", "VSCodium"))


def workspace_from_extension_host(parent_pid: int) -> Path | None:
    pid_pattern = re.compile(
        rf"Extension host with pid\s+{re.escape(str(parent_pid))}\s+started",
        re.IGNORECASE,
    )
    storage_pattern = re.compile(
        r"workspaceStorage[\\/]([0-9a-f]{32})(?:[\\/.]|$)",
        re.IGNORECASE,
    )

    candidates: list[tuple[float, Path, Path]] = []
    for code_root in vscode_data_roots():
        logs_root = code_root / "logs"
        storage_root = code_root / "User" / "workspaceStorage"
        if not logs_root.is_dir() or not storage_root.is_dir():
            continue
        for log_path in logs_root.glob("*/window*/exthost/exthost.log"):
            candidates.append((log_path.stat().st_mtime, log_path, storage_root))

    for _, log_path, storage_root in sorted(candidates, reverse=True):
        try:
            text = log_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        if not pid_pattern.search(text):
            continue
        storage_ids = storage_pattern.findall(text)
        if not storage_ids:
            return None
        metadata_path = storage_root / storage_ids[-1] / "workspace.json"
        try:
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            return None
        folder_uri = metadata.get("folder")
        if not isinstance(folder_uri, str):
            return None
        return file_uri_to_path(folder_uri)
    return None


def identify_project() -> tuple[Path, Path] | None:
    for candidate in (Path.cwd(), workspace_from_extension_host(os.getppid())):
        if candidate is None:
            continue
        matches = [entry for entry in PROJECTS if is_within(candidate, entry[0])]
        if len(matches) == 1:
            return matches[0]
    return None



# ---------------------------------------------------------------------------
# Adaptateur de protocole MCP
# ---------------------------------------------------------------------------


def read_content_length_message(stream) -> bytes | None:
    """Lit un message MCP au format Content-Length depuis un flux binaire."""
    headers = b""
    while True:
        byte = stream.read(1)
        if not byte:
            return None
        headers += byte
        if headers.endswith(b"\r\n\r\n"):
            break

    length_match = re.search(rb"Content-Length:\s*(\d+)", headers, re.IGNORECASE)
    if not length_match:
        raise ValueError(f"En-tete Content-Length manquant : {headers!r}")
    length = int(length_match.group(1))
    payload = stream.read(length)
    if len(payload) != length:
        raise ValueError(f"Payload tronquee : attendu {length}, recu {len(payload)}")
    return payload


def write_content_length_message(stream, payload: bytes) -> None:
    """Ecrit un message MCP au format Content-Length dans un flux binaire."""
    header = f"Content-Length: {len(payload)}\r\n\r\n".encode("utf-8")
    stream.write(header + payload)
    stream.flush()


def forward_ndjson_to_content_length(src, dst, shutdown_event: threading.Event) -> None:
    """Lit des lignes NDJSON depuis src et les reecrit au format Content-Length."""
    while not shutdown_event.is_set():
        try:
            line = src.readline()
        except OSError:
            break
        if not line:
            break
        if not line.strip():
            continue
        payload = line.rstrip(b"\n").rstrip(b"\r")
        try:
            write_content_length_message(dst, payload)
        except OSError:
            break


def forward_content_length_to_ndjson(src, dst, shutdown_event: threading.Event) -> None:
    """Lit des messages Content-Length depuis src et les reecrit en NDJSON."""
    while not shutdown_event.is_set():
        try:
            payload = read_content_length_message(src)
        except ValueError as exc:
            print(f"[crg-router] Erreur lecture parent : {exc}", file=sys.stderr)
            break
        if payload is None:
            break
        try:
            dst.write(payload + b"\n")
            dst.flush()
        except OSError:
            break


def forward_stream(src, dst, shutdown_event: threading.Event) -> None:
    """Forward un flux binaire brut (typiquement stderr)."""
    while not shutdown_event.is_set():
        try:
            chunk = src.read(4096)
        except OSError:
            break
        if not chunk:
            break
        try:
            dst.write(chunk)
            dst.flush()
        except OSError:
            break


def bridge_mcp_process(process: subprocess.Popen) -> int:
    """Pont entre le parent (Content-Length) et le serveur CRG (NDJSON)."""
    shutdown = threading.Event()

    parent_stdin = sys.stdin.buffer
    parent_stdout = sys.stdout.buffer
    parent_stderr = sys.stderr.buffer

    server_stdin = process.stdin
    server_stdout = process.stdout
    server_stderr = process.stderr

    threads = [
        threading.Thread(
            target=forward_content_length_to_ndjson,
            args=(parent_stdin, server_stdin, shutdown),
            daemon=True,
        ),
        threading.Thread(
            target=forward_ndjson_to_content_length,
            args=(server_stdout, parent_stdout, shutdown),
            daemon=True,
        ),
        threading.Thread(
            target=forward_stream,
            args=(server_stderr, parent_stderr, shutdown),
            daemon=True,
        ),
    ]
    for t in threads:
        t.start()

    try:
        return_code = process.wait()
    except KeyboardInterrupt:
        process.terminate()
        try:
            return_code = process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            return_code = process.wait()
    finally:
        shutdown.set()
        for t in threads:
            t.join(timeout=2)
        try:
            process.stdin.close()
        except Exception:
            pass
        if process.poll() is None:
            process.kill()

    return return_code



def main() -> int:
    project = identify_project()
    if project is None:
        print(
            "Routeur refuse : aucun workspace autorise unique n'a ete identifie.",
            file=sys.stderr,
            flush=True,
        )
        return 2

    root, executable = project
    if not executable.is_file():
        print(f"Executable introuvable : {executable}", file=sys.stderr, flush=True)
        return 3

    environment = os.environ.copy()
    environment.update(
        {
            "PYTHONUTF8": "1",
            "CRG_REPO_ROOT": str(root),
            "CRG_DATA_DIR": str(root / ".code-review-graph"),
        }
    )
    process = subprocess.Popen(
        (str(executable), "serve", "--repo", str(root)),
        cwd=root,
        env=environment,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return bridge_mcp_process(process)


if __name__ == "__main__":
    raise SystemExit(main())

