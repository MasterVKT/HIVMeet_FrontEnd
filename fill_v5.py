"""Fill registration form - v5: clean start, TAB navigation, file-based password."""
import subprocess, time, re, sys

D = "emulator-5554"

def sh(*args):
    return subprocess.run(["adb", "-s", D] + list(args), capture_output=True, text=True, timeout=30)

def shell(cmd):
    return subprocess.run(["adb", "-s", D, "shell", cmd], capture_output=True, text=True, timeout=30)

def dump():
    sh("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    return sh("shell", "cat", "/sdcard/ui.xml").stdout

def descs():
    return re.findall(r'content-desc="([^"]{3,})"', dump())

def texts():
    return re.findall(r'text="([^"]+)"', dump())

# 1. Click S'inscrire
print("[1] Click S'inscrire...")
sh("shell", "input", "tap", "765", "1977")
time.sleep(3)
d = descs()
print(f"    Screen: {d[:4]}")
if not any("compte" in x for x in d):
    print("    ERROR: Not on register page!")
    sys.exit(1)

# 2. Get EditText positions
xml = dump()
nodes = re.findall(r'EditText[^>]*?bounds="(\[\d+,\d+\]\[\d+,\d+\])"', xml)
print(f"[2] Fields: {nodes}")
if not nodes:
    print("    ERROR: No fields found!")
    sys.exit(1)

def ctr(b):
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', b)
    return (int(m.group(1))+int(m.group(3)))//2, (int(m.group(2))+int(m.group(4)))//2

# 3. Write password to a file on the device (with & char)
print("[3] Writing password file...")
shell("printf 'Alice2026&' > /sdcard/_pwd.txt")
pwd_on_device = shell("cat /sdcard/_pwd.txt").stdout.strip()
print(f"    File content: '{pwd_on_device}' (len={len(pwd_on_device)})")

# 4. Tap email field, type email
x, y = ctr(nodes[0])
print(f"[4] Email at ({x},{y})...")
sh("shell", "input", "tap", str(x), str(y))
time.sleep(0.5)
sh("shell", "input", "text", "alice.hivmeet")
sh("shell", "input", "keyevent", "KEYCODE_AT")
sh("shell", "input", "text", "test.local")
time.sleep(0.3)
t = texts()
print(f"    Texts after email: {t[:3]}")

# 5. TAB to password, type password using file substitution
print("[5] TAB -> password...")
sh("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
# Use $(cat /sdcard/_pwd.txt) on the Android shell to pass the password with &
shell("input text \"$(cat /sdcard/_pwd.txt)\"")
time.sleep(0.3)
t = texts()
print(f"    Texts after password: {t[:3]}")

# 6. TAB to confirm, type same password
print("[6] TAB -> confirm...")
sh("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
shell("input text \"$(cat /sdcard/_pwd.txt)\"")
time.sleep(0.3)
t = texts()
print(f"    Texts after confirm: {t[:5]}")

# 7. TAB to display name, type Alice
print("[7] TAB -> name...")
sh("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
sh("shell", "input", "text", "Alice")
time.sleep(0.3)

# 8. Verify
print("\n[8] Final verification:")
t = texts()
d = descs()
print(f"    Texts: {t}")
print(f"    Descs: {d[:12]}")
errors = [x for x in d if any(k in x.lower() for k in ["erreur","invalid","correspondent","requi"])]
if errors:
    print(f"    ERRORS: {errors}")
else:
    print("    No errors!")
print(f"\n    Total text fields with content: {len(t)}")

# Cleanup
shell("rm /sdcard/_pwd.txt")
print("\nDone!")