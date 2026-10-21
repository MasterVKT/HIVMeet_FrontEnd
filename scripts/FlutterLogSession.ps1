# scripts/FlutterLogSession.ps1
# ---------------------------------------------------------------------------
# Bounded, dual-output log capture shared by run_device.ps1 / run_emulator.ps1.
#
# Goals:
#   * Echo every kept line to the terminal (Write-Host) AND to the log file,
#     so execution logs are visible live *and* persisted.
#   * Never let the log file grow to astronomical sizes on long runs: the
#     active file is capped (MaxBytes) and rotated into numbered backups
#     (MaxBackups), e.g. device_run.md -> device_run.1.md -> device_run.2.md.
#   * Optionally filter out well-known benign Android OS/logcat chatter that
#     floods `flutter run` output, so the persisted log stays useful.
#
# The numbered backups (<stem>.1.md, <stem>.2.md, ...) match the existing
# .gitignore patterns (/device_run*.md, /emulator_run*.md).
# ---------------------------------------------------------------------------

# Default bytes per active log file before rotation (keep below the ~100k line
# problem: ~2 MB is roughly 25-35k lines of typical logcat output).
$script:FlutterLogDefaultMaxBytes = 2MB

# Default number of rotated backups kept next to the active file.
$script:FlutterLogDefaultMaxBackups = 3

# Well-known benign, high-volume Android OS/system chatter. These lines are
# not produced by the Flutter/Dart application and are safe to drop. Real app
# logs and error/crash lines (flutter:, FATAL, Exception, ...) are never
# matched by these patterns.
$script:FlutterLogDefaultNoisePatterns = @(
    'EGL_emulation',
    'RemoteConfig:MainPageConfig',
    'PowerManagerService',
    'osfingersense',
    'libprocessgroup',
    'BtGdModule'
)

# Builds a single case-insensitive regex from a list of plain-text patterns.
function New-FlutterNoiseRegex {
    param([string[]]$Patterns)

    if (-not $Patterns -or $Patterns.Count -eq 0) { return $null }

    $escaped = $Patterns | Where-Object { $_ } | ForEach-Object { [regex]::Escape($_) }
    if (-not $escaped -or @($escaped).Count -eq 0) { return $null }

    return [regex]::new((@($escaped) -join '|'), [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
}

# Creates a log session: an open (truncated) StreamWriter plus the state needed
# for size tracking, filtering and rotation. Returns a hashtable (reference
# type) that is mutated by Write-FlutterLogLine / Invoke-FlutterLogRotation.
function New-FlutterLogSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [long]$MaxBytes = $script:FlutterLogDefaultMaxBytes,
        [int]$MaxBackups = $script:FlutterLogDefaultMaxBackups,
        [switch]$NoFilter,
        [string[]]$NoisePatterns
    )

    if (-not $NoisePatterns -or $NoisePatterns.Count -eq 0) {
        $NoisePatterns = $script:FlutterLogDefaultNoisePatterns
    }
    if ($MaxBackups -lt 0) { $MaxBackups = 0 }

    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $writer = [System.IO.StreamWriter]::new($Path, $false, [System.Text.UTF8Encoding]::new($true))
    $writer.AutoFlush = $true

    return @{
        Path       = $Path
        MaxBytes   = [long]$MaxBytes
        MaxBackups = [int]$MaxBackups
        Filter     = (-not $NoFilter)
        NoiseRegex = New-FlutterNoiseRegex -Patterns $NoisePatterns
        Writer     = $writer
        Bytes      = [long]0
        Written    = 0
        Filtered   = 0
        Rotations  = 0
    }
}

# Splits a log path into "stem"/"extension" so backups are named
# <stem>.<n><ext> (e.g. device_run.md -> device_run.1.md).
function Get-FlutterLogBackupPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Index
    )

    $root = Split-Path -Parent $Path
    $ext = [System.IO.Path]::GetExtension($Path)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($Path)
    $name = "$stem.$Index$ext"
    if ($root) { return (Join-Path $root $name) }
    return $name
}

# Closes the active file, shifts backups, then reopens a fresh active file.
function Invoke-FlutterLogRotation {
    param([Parameter(Mandatory = $true)][hashtable]$Session)

    try { $Session.Writer.Flush() } catch { }
    try { $Session.Writer.Dispose() } catch { }

    if ($Session.MaxBackups -gt 0) {
        # Drop the oldest backup.
        $oldest = Get-FlutterLogBackupPath -Path $Session.Path -Index $Session.MaxBackups
        if (Test-Path -LiteralPath $oldest) {
            Remove-Item -LiteralPath $oldest -Force -ErrorAction SilentlyContinue
        }

        # Shift <stem>.<n> -> <stem>.<n+1> (from the highest index down).
        for ($i = $Session.MaxBackups - 1; $i -ge 1; $i--) {
            $src = Get-FlutterLogBackupPath -Path $Session.Path -Index $i
            if (Test-Path -LiteralPath $src) {
                $dst = Get-FlutterLogBackupPath -Path $Session.Path -Index ($i + 1)
                Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction SilentlyContinue
            }
        }

        # Active file -> backup .1
        if (Test-Path -LiteralPath $Session.Path) {
            $first = Get-FlutterLogBackupPath -Path $Session.Path -Index 1
            Move-Item -LiteralPath $Session.Path -Destination $first -Force -ErrorAction SilentlyContinue
        }
    }

    $Session.Writer = [System.IO.StreamWriter]::new($Session.Path, $false, [System.Text.UTF8Encoding]::new($true))
    $Session.Writer.AutoFlush = $true
    $Session.Bytes = [long]0
    $Session.Rotations++
}

# Writes one line to the terminal and to the log file (subject to the noise
# filter), then rotates the file if the size cap has been reached.
# Logging must never break the run, so all file I/O errors are swallowed.
function Write-FlutterLogLine {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Session,
        [AllowEmptyString()][string]$Line
    )

    if ($null -eq $Line) { $Line = '' }

    if ($Session.Filter -and $Session.NoiseRegex -and $Session.NoiseRegex.IsMatch($Line)) {
        $Session.Filtered++
        return
    }

    Write-Host $Line

    try {
        $Session.Writer.WriteLine($Line)
        $Session.Bytes += [System.Text.Encoding]::UTF8.GetByteCount($Line) + 2
        $Session.Written++
    }
    catch {
        # Never let a logging failure abort `flutter run`.
    }

    if ($Session.MaxBytes -gt 0 -and $Session.Bytes -ge $Session.MaxBytes) {
        Invoke-FlutterLogRotation -Session $Session
    }
}

# Flushes and closes the active log file. Safe to call more than once.
function Close-FlutterLogSession {
    param([Parameter(Mandatory = $true)][hashtable]$Session)

    try { $Session.Writer.Flush() } catch { }
    try { $Session.Writer.Dispose() } catch { }
}

# Prints a short end-of-run recap (file path + kept/filtered line counts).
function Write-FlutterLogSummary {
    param([Parameter(Mandatory = $true)][hashtable]$Session)

    Write-Host ''
    Write-Host ('-' * 64)
    Write-Host ("Log file       : {0}" -f $Session.Path)
    Write-Host ("Lines written  : {0}" -f $Session.Written)
    Write-Host ("Lines filtered : {0}" -f $Session.Filtered)
    Write-Host ("Rotations      : {0}" -f $Session.Rotations)
    Write-Host ('-' * 64)
}
