"""Fill HIVMeet registration form via ADB using TAB navigation between fields.
This solves the Flutter focus issue where adb input tap doesn't change focus.
"""
import subprocess
import time
import re
import sys

DEVICE = "emulator-5554"
PASSWORD = "Alice2026&"

def adb(*args, timeout=30):
    return subprocess.run(["adb", "-s", DEVICE] + list(args), capture_output=True, text=True, timeout=timeout)

def adb_shell(cmd, timeout=30):
    return subprocess.run(["adb", "-s", DEVICE, "shell", cmd], capture_output=True, text=True, timeout=timeout)

def dump_ui():
    adb("shell", "uiautomator", "dump", "/sdcard/ui_dump.xml")
    r = adb("shell", "cat", "/sdcard/ui_dump.xml")
    return r.stdout

def get_fields_info():
    xml = dump_ui()
    texts = re.findall(r'text="([^"]{2,})"', xml)
    descs = re.findall(r'content-desc="([^"]{3,})"', xml)
    nodes = re.findall(r'class="android\.widget\.EditText"[^>]*bounds="(\[\d+,\d+\]\[\d+,\d+\])"[^>]*password="(\w+)"', xml)
    return texts, descs, nodes

def center(bounds_str):
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', bounds_str)
    if m:
        return (int(m.group(1)) + int(m.group(3))) // 2, (int(m.group(2)) + int(m.group(4))) // 2
    return None, None

# Step 0: Force-stop and relaunch app for clean state
print("=" * 50)
print("B1-01: Inscription ALICE")
print("=" * 50)

print("\n[0] Force-stopping app...")
adb("shell", "am", "force-stop", "com.hivmeet.hivmeet")
time.sleep(2)

print("[0b] Launching app...")
adb("shell", "am", "start", "-n", "com.hivmeet.hivmeet/.MainActivity")
time.sleep(10)

# Step 1: Check screen
print("\n[1] Checking screen...")
texts, descs, nodes = get_fields_info()
print(f"    Descs: {descs[:5]}")

# Navigate to register page if on login
if any("Bon retour" in d for d in descs):
    print("    On login page -> clicking S'inscrire")
    adb("shell", "input", "tap", "765", "1977")
    time.sleep(3)
elif any("Cr" in d and "compte" in d for d in descs):
    print("    Already on register page")
else:
    # Try clicking S'inscrire anyway
    print("    Unknown screen -> trying S'inscrire")
    adb("shell", "input", "tap", "765", "1977")
    time.sleep(3)

# Step 2: Get fresh field positions
print("\n[2] Getting field positions...")
texts, descs, nodes = get_fields_info()
print(f"    Fields: {nodes}")
if not nodes:
    print("    ERROR: No EditText fields found!")
    sys.exit(1)

# Step 3: Fill email (first field)
x, y = center(nodes[0][0])
print(f"\n[3] Filling email at ({x},{y})...")
adb("shell", "input", "tap", str(x), str(y))
time.sleep(0.5)
# Clear any existing text
adb("shell", "input", "keyevent", "KEYCODE_MOVE_END")
for _ in range(30):
    adb("shell", "input", "keyevent", "KEYCODE_DEL")
time.sleep(0.2)
# Type email - use input text for the parts, KEYCODE_AT for @
adb("shell", "input", "text", "alice.hivmeet")
adb("shell", "input", "keyevent", "KEYCODE_AT")
adb("shell", "input", "text", "test.local")
time.sleep(0.3)

# Verify email was typed
texts, descs, _ = get_fields_info()
print(f"    After email - texts: {texts[:3]}")

# Step 4: Navigate to password field using TAB
print(f"\n[4] Navigating to password field via TAB...")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)

# Fill password using single-quoted shell command for the & character
print(f"    Filling password 'Alice2026&'...")
adb("shell", "input", "text", "Alice2026")
time.sleep(0.2)
# Use shell single-quotes to pass & literally
subprocess.run(["adb", "-s", DEVICE, "shell", "input text 'Alice2026&'"], 
               capture_output=True, text=True, timeout=10, shell=False)
# Hmm, that won't work. Let's try: adb shell "input text 'Alice2026&'"
r = subprocess.run('adb -s emulator-5554 shell "input text \'Alice2026&\'"', 
                   capture_output=True, text=True, timeout=10, shell=True)
print(f"    Password result: stdout='{r.stdout}' stderr='{r.stderr}'")
time.sleep(0.3)

# Step 5: Navigate to confirm password via TAB
print(f"\n[5] Navigating to confirm password via TAB...")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
# Type the same password
adb("shell", "input", "text", "Alice2026")
time.sleep(0.2)
r = subprocess.run('adb -s emulator-5554 shell "input text \'Alice2026&\'"', 
                   capture_output=True, text=True, timeout=10, shell=True)
time.sleep(0.3)

# Step 6: Navigate to display name via TAB
print(f"\n[6] Navigating to display name via TAB...")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
adb("shell", "input", "text", "Alice")
time.sleep(0.3)

# Step 7: Verify the form
print(f"\n[7] Verifying form...")
texts, descs, _ = get_fields_info()
print(f"    Texts: {texts[:5]}")
print(f"    Descs: {descs[:15]}")

# Check for errors
errors = [d for d in descs if any(k in d.lower() for k in ["erreur", "invalid", "correspondent", "requi"])]
if errors:
    print(f"    ERRORS: {errors}")
else:
    print("    No errors found!")

# Count password dots
pwd_texts = [t for t in texts if '\u2022' in t or '\u25cf' in t or 'â€¢' in t]
print(f"    Password fields: {pwd_texts}")

print("\n" + "=" * 50)
print("Done!")