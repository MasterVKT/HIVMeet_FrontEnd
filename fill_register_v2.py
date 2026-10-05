"""Fill the HIVMeet registration form via ADB.
Uses single-quoted shell commands to handle special characters in passwords.
"""
import subprocess
import time
import re

DEVICE = "emulator-5554"

def adb_shell(cmd_str):
    r = subprocess.run(["adb", "-s", DEVICE, "shell", cmd_str], capture_output=True, text=True, timeout=30)
    return r.stdout

def adb(*args):
    subprocess.run(["adb", "-s", DEVICE] + list(args), timeout=30)

def dump_ui():
    adb("shell", "uiautomator", "dump", "/sdcard/ui_dump.xml")
    r = subprocess.run(["adb", "-s", DEVICE, "shell", "cat", "/sdcard/ui_dump.xml"], capture_output=True, text=True, timeout=10)
    return r.stdout

# Password with & as special char (in the allowed list [@$!%*?&])
PASSWORD = "Alice2026&"

# Step 1: Check current screen
xml = dump_ui()
descs = re.findall(r'content-desc="([^"]{3,})"', xml)
print("Current screen:", descs[:5])

# If on login, click S'inscrire
if any("Bon retour" in d for d in descs):
    print("Clicking S'inscrire...")
    adb("shell", "input", "tap", "765", "1977")
    time.sleep(3)
elif any("Cr" in d and "compte" in d for d in descs):
    print("Already on register page")
else:
    print("Unknown screen, trying S'inscrire...")
    adb("shell", "input", "tap", "765", "1977")
    time.sleep(3)

# Get fresh EditText positions
xml = dump_ui()
nodes = re.findall(r'class="android\.widget\.EditText"[^>]*bounds="(\[\d+,\d+\]\[\d+,\d+\])"', xml)
print(f"EditTexts: {nodes}")

# Fill email
if nodes:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', nodes[0])
    x = (int(m.group(1)) + int(m.group(3))) // 2
    y = (int(m.group(2)) + int(m.group(4))) // 2
    print(f"Email at ({x},{y})")
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(0.3)
    adb("shell", "input", "text", "alice.hivmeet")
    adb("shell", "input", "keyevent", "KEYCODE_AT")
    adb("shell", "input", "text", "test.local")
    time.sleep(0.3)

# Fill password with & using single-quoted shell command
if len(nodes) >= 2:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', nodes[1])
    x = (int(m.group(1)) + int(m.group(3))) // 2
    y = (int(m.group(2)) + int(m.group(4))) // 2
    print(f"Password at ({x},{y})")
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(0.3)
    # KEY FIX: single quotes on Android shell to pass & literally
    adb_shell("input text 'Alice2026&'")
    time.sleep(0.3)

# Fill confirm password
if len(nodes) >= 3:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', nodes[2])
    x = (int(m.group(1)) + int(m.group(3))) // 2
    y = (int(m.group(2)) + int(m.group(4))) // 2
    print(f"Confirm at ({x},{y})")
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(0.3)
    adb_shell("input text 'Alice2026&'")
    time.sleep(0.3)

# Fill display name
if len(nodes) >= 4:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', nodes[3])
    x = (int(m.group(1)) + int(m.group(3))) // 2
    y = (int(m.group(2)) + int(m.group(4))) // 2
    print(f"Name at ({x},{y})")
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(0.3)
    adb("shell", "input", "text", "Alice")
    time.sleep(0.3)

# Verify
xml = dump_ui()
texts = re.findall(r'text="([^"]{2,})"', xml)
descs = re.findall(r'content-desc="([^"]{3,})"', xml)
print(f"\nTexts: {texts[:5]}")
print(f"Descs: {descs[:15]}")
errors = [d for d in descs if any(k in d.lower() for k in ["erreur", "invalid", "correspondent", "requi"])]
if errors:
    print(f"Errors: {errors}")
else:
    print("No errors!")

print("\nDone!")