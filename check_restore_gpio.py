import os
import time
from gpiozero import Button

# GPIO 21 — physical restore button (wired to GND)
button = Button(21, pull_up=True)

BOOT_FIRMWARE="/boot/firmware"
BOOT_OTHER="/boot/b"

def switch_boot_partition():
    """Toggle boot_partition in autoboot.txt between 1 and 2."""
    autoboot = f"{BOOT_FIRMWARE}/autoboot.txt"
    if os.path.exists(autoboot):
        with open(autoboot, 'r') as f:
            content = f.read()
        current = '1' if 'boot_partition=1' in content else '2'
        new = '2' if current == '1' else '1'
        content = content.replace(f'boot_partition={current}', f'boot_partition={new}')
        with open(autoboot, 'w') as f:
            f.write(content)
        print(f"Switched boot partition from {current} to {new}")
        return True
    return False

if button.is_pressed:
    print("[PiOpsOS] Restore button is pressed")
    # Wait for button release to avoid multiple triggers
    button.wait_for_release()
    time.sleep(0.5)
    # Trigger factory reset: wipe overlay + switch to boot A
    os.system(f"{BOOT_FIRMWARE}/boot_to_root")
else:
    print("Restore button is not pressed")
