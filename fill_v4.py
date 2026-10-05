"""Fill HIVMeet registration form using TAB navigation between Flutter fields."""
import subprocess
import time
import re

DEVICE = "emulator-5554"

def adb(*args):
    return subprocess.run(["adb", "-s", DEVICE] + list(args), capture_output=True, text=True, timeout=30)

def shell(cmd):
    return subprocess.run(["adb", "-s", DEVICE, "shell", cmd], capture_output=True, text=True, timeout=30)

def dump():
    adb("shell", "uiautomator", "dump", "/sdcard/ui.xml")
    return adb("shell", "cat", "/sdcard/ui.xml").stdout

def descs():
    return re.findall(r'content-desc="([^"]{3,})"', dump())

def texts():
    return re.findall(r'text="([^"]{2,})"', dump())

# 1. Force stop and relaunch for clean state
print("[1] Force stop + relaunch...")
adb("shell", "am", "force-stop", "com.hivmeet.hivmeet")
time.sleep(2)
adb("shell", "am", "start", "-n", "com.hivmeet.hivmeet/.MainActivity")
time.sleep(12)

# 2. Wait for login page, click S'inscrire
d = descs()
print(f"[2] Screen: {d[:4]}")
if any("Bon retour" in x for x in d):
    print("    Login page -> click S'inscrire")
    adb("shell", "input", "tap", "765", "1977")
    time.sleep(3)
else:
    # Maybe ANR dialog
    t = texts()
    if any("responding" in x for x in t):
        print("    ANR -> click Wait")
        adb("shell", "input", "tap", "540", "1258")
        time.sleep(10)
        d = descs()
        if any("Bon retour" in x for x in d):
            adb("shell", "input", "tap", "765", "1977")
            time.sleep(3)

# 3. Verify on register page
d = descs()
print(f"[3] Screen: {d[:4]}")
if not any("compte" in x for x in d):
    print("    ERROR: Not on register page!")
    exit(1)

# 4. Find EditText positions from XML
xml = dump()
# Parse EditText bounds - they appear as: class="android.widget.EditText" ... bounds="[x1,y1][x2,y2]"
nodes = re.findall(r'class="android\.widget\.EditText"[^>]*?bounds="(\[\d+,\d+\]\[\d+,\d+\])"', xml)
print(f"[4] EditTexts: {nodes}")
if not nodes:
    # Try alternate regex - sometimes password attr is between class and bounds
    nodes = re.findall(r'EditText[^>]*?bounds="(\[\d+,\d+\]\[\d+,\d+\])"', xml)
    print(f"    Alt EditTexts: {nodes}")

def center(b):
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', b)
    return (int(m.group(1))+int(m.group(3)))//2, (int(m.group(2))+int(m.group(4)))//2

# 5. Tap first field (email), type email
if nodes:
    x, y = center(nodes[0])
    print(f"[5] Tap email field at ({x},{y})")
    adb("shell", "input", "tap", str(x), str(y))
    time.sleep(0.5)
    # Type email
    adb("shell", "input", "text", "alice.hivmeet")
    adb("shell", "input", "keyevent", "KEYCODE_AT")
    adb("shell", "input", "text", "test.local")
    time.sleep(0.3)
    
    # Verify email
    t = texts()
    print(f"    Email field text: {t[:2]}")

# 6. TAB to password field, type password
print("[6] TAB -> password")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
# Type password: Alice2026 followed by & (using shell single-quotes)
adb("shell", "input", "text", "Alice2026")
# For & char: use adb shell with single-quoted argument
shell("input text 'Alice2026&'")
time.sleep(0.3)

# Wait - that would type Alice2026 twice! Let me fix.
# Actually we already typed Alice2026 above. We need just the & character.
# Let me redo: clear and type the full password with single quotes

# Clear the field (we typed Alice2026 already, need to add just &)
# Actually the shell("input text 'Alice2026&'") will append "Alice2026&" to what's there
# We need to clear first. Let me use backspace to delete what we typed, then type the full password.

# Hmm, this is getting complicated. Let me take a simpler approach:
# Just use the shell command with single quotes for the entire password in one shot.

print("    [FIX] Clearing and retyping password...")
# Move to end, delete 9 chars (Alice2026 = 9 chars)
for _ in range(9):
    adb("shell", "input", "keyevent", "KEYCODE_DEL")
time.sleep(0.1)
# Now type the full password with & using shell single-quotes
shell("input text 'Alice2026&'")
time.sleep(0.3)

# 7. TAB to confirm password, type same password
print("[7] TAB -> confirm password")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
shell("input text 'Alice2026&'")
time.sleep(0.3)

# 8. TAB to display name, type Alice
print("[8] TAB -> display name")
adb("shell", "input", "keyevent", "KEYCODE_TAB")
time.sleep(0.5)
adb("shell", "input", "text", "Alice")
time.sleep(0.3)

# 9. Verify
print("\n[9] Verification:")
t = texts()
d = descs()
print(f"    Texts: {t[:5]}")
print(f"    Descs: {d[:15]}")
errors = [x for x in d if any(k in x.lower() for k in ["erreur","invalid","correspondent","requi"])]
if errors:
    print(f"    ERRORS: {errors}")
else:
    print("    No errors!")
print("\nDone!")