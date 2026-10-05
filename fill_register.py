"""Fill the HIVMeet registration form via ADB.
Uses a file on the device to pass the password with special characters reliably.
"""
import subprocess
import time
import sys

DEVICE = "emulator-5554"

def adb(*args, capture=False):
    cmd = ["adb", "-s", DEVICE, "shell"] + list(args)
    if capture:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return r.stdout
    else:
        subprocess.run(cmd, timeout=10)

def adb_shell(cmd_str, capture=False):
    """Run a raw shell command on the device."""
    full = ["adb", "-s", DEVICE, "shell", cmd_str]
    if capture:
        r = subprocess.run(full, capture_output=True, text=True, timeout=10)
        return r.stdout
    else:
        subprocess.run(full, timeout=10)

def dump_ui():
    adb("uiautomator", "dump", "/sdcard/ui_dump.xml")
    return adb("cat", "/sdcard/ui_dump.xml", capture=True)

def get_texts():
    import re
    xml = dump_ui()
    texts = re.findall(r'text="([^"]{2,})"', xml)
    descs = re.findall(r'content-desc="([^"]{3,})"', xml)
    return texts, descs

def get_edittexts():
    import re
    xml = dump_ui()
    # Find all EditText nodes with their bounds
    nodes = re.findall(r'class="android\.widget\.EditText"[^>]*bounds="(\[\d+,\d+\]\[\d+,\d+\])"', xml)
    return nodes

# Step 0: Force-stop and relaunch the app for a clean state
print("Step 0: Force-stopping app...")
subprocess.run(["adb", "-s", DEVICE, "shell", "am", "force-stop", "com.hivmeet.hivmeet"], timeout=10)
time.sleep(2)

print("Step 0b: Relaunching app...")
subprocess.run(["adb", "-s", DEVICE, "shell", "am", "start", "-n", "com.hivmeet.hivmeet/.MainActivity"], timeout=10)
time.sleep(8)  # Wait for Firebase init and UI to load

# Step 1: Wait for login page and click "S'inscrire"
print("Step 1: Clicking S'inscrire...")
texts, descs = get_texts()
print(f"  Current descs: {descs[:5]}")
adb("input", "tap", "765", "1977")  # S'inscrire button
time.sleep(3)

texts, descs = get_texts()
print(f"  After tap descs: {descs[:5]}")

# Check if we're on the register page
if "Cr" not in descs[0] if descs else True:
    print("  Not on register page, retrying...")
    adb("input", "tap", "765", "1977")
    time.sleep(3)
    texts, descs = get_texts()
    print(f"  Descs after retry: {descs[:5]}")

# Step 2: Get fresh EditText positions
print("Step 2: Getting EditText positions...")
edittexts = get_edittexts()
print(f"  EditTexts: {edittexts}")

# Step 3: Write the password to a file on the device
# Using & as the special character (it's in the allowed list [@$!%*?&])
PASSWORD = "Alice2026&"
print(f"Step 3: Writing password to device file...")
# Use printf to write the exact bytes to a file (no shell interpretation)
adb_shell(f"printf '%s' '{PASSWORD}' > /sdcard/_pwd.txt")
# Verify the file content
content = adb_shell("cat /sdcard/_pwd.txt", capture=True).strip()
print(f"  File content: '{content}' (len={len(content)})")

# Step 4: Fill email field
print("Step 4: Filling email...")
# Parse first EditText bounds
import re
if edittexts:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', edittexts[0])
    if m:
        x = (int(m.group(1)) + int(m.group(3))) // 2
        y = (int(m.group(2)) + int(m.group(4))) // 2
        adb("input", "tap", str(x), str(y))
        time.sleep(0.3)
        # Type email - @ needs KEYCODE_AT
        adb("input", "text", "alice.hivmeet")
        adb("input", "keyevent", "KEYCODE_AT")
        adb("input", "text", "test.local")
        time.sleep(0.3)
        print(f"  Email typed at ({x},{y})")

# Step 5: Fill password field using file-based approach
print("Step 5: Filling password from file...")
if len(edittexts) >= 2:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', edittexts[1])
    if m:
        x = (int(m.group(1)) + int(m.group(3))) // 2
        y = (int(m.group(2)) + int(m.group(4))) // 2
        adb("input", "tap", str(x), str(y))
        time.sleep(0.3)
        # Use $(cat file) to pass the password with special chars to input text
        adb_shell(f"input text \"$(cat /sdcard/_pwd.txt)\"")
        time.sleep(0.3)
        print(f"  Password typed at ({x},{y})")

# Step 6: Fill confirm password
print("Step 6: Filling confirm password...")
if len(edittexts) >= 3:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', edittexts[2])
    if m:
        x = (int(m.group(1)) + int(m.group(3))) // 2
        y = (int(m.group(2)) + int(m.group(4))) // 2
        adb("input", "tap", str(x), str(y))
        time.sleep(0.3)
        adb_shell(f"input text \"$(cat /sdcard/_pwd.txt)\"")
        time.sleep(0.3)
        print(f"  Confirm typed at ({x},{y})")

# Step 7: Fill display name
print("Step 7: Filling display name...")
if len(edittexts) >= 4:
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', edittexts[3])
    if m:
        x = (int(m.group(1)) + int(m.group(3))) // 2
        y = (int(m.group(2)) + int(m.group(4))) // 2
        adb("input", "tap", str(x), str(y))
        time.sleep(0.3)
        adb("input", "text", "Alice")
        time.sleep(0.3)
        print(f"  Name typed at ({x},{y})")

# Step 8: Verify the form
print("\nStep 8: Verifying form...")
texts, descs = get_texts()
print(f"  Texts: {texts[:5]}")
print(f"  Descs: {descs[:15]}")

# Check for error messages
errors = [d for d in descs if "erreur" in d.lower() or "invalid" in d.lower() or "correspondent" in d.lower()]
if errors:
    print(f"  ERRORS FOUND: {errors}")
else:
    print("  No errors found!")

# Cleanup
adb("shell", "rm", "/sdcard/_pwd.txt")
print("\nDone!")