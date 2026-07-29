# Samsung Knox Guard (KG) Bypass Guide
# Samsung Knox Guard (KG) बाइपास गाइड

## Device Tested / डिवाइस टेस्टेड
- **Model:** Samsung SM-A042F (Galaxy A04e)
- **Android:** 14 (BIT-G firmware: A042FXXSGEZF1)
- **Chipset:** MediaTek MT6765
- **KG Type:** Device Owner enforced via `com.sds.emm.cloud.knox.samsung` (EMM agent) + `com.sec.enterprise.knox.cloudmdm.smdms` (MDM)

---

## Method 1: ADB + AppOps (No Root, No PC Driver Required)
### विधि 1: ADB + AppOps (बिना रूट के)

### Requirements / आवश्यकताएँ
- Windows PC with ADB installed (या कोई भी OS जहाँ ADB चल सके)
- USB cable
- Samsung phone with KG lock

### Automated Batch Script (Windows) / ऑटोमेटेड बैच स्क्रिप्ट
Download **`KG_Bypass.bat`** from this repo and run it as Administrator. It automates all steps:
1. Detects connected device
2. Lists Knox/EMM packages
3. Sets `device_provisioned=0` and reboots
4. Applies AppOps restrictions to block KG
5. Restores settings and reboots

```
KG_Bypass.bat
```

> Double-click and follow the prompts — no manual ADB commands needed.

### Manual Steps / मैन्युअल चरण

#### Step 1: Set device_provisioned to 0
```
adb shell settings put global device_provisioned 0
adb shell settings put secure user_setup_complete 0
```

#### Step 2: Reboot phone
```
adb shell reboot
```

> After reboot, KG will be gone. You'll see the home screen / setup screen.
> रिबूट के बाद KG हट जाएगा और होम स्क्रीन दिखेगी।

#### Step 3: Immediately block EMM apps via AppOps
```
adb shell appops set com.sds.emm.cloud.knox.samsung RUN_ANY_IN_BACKGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung RUN_IN_BACKGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung START_FOREGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung WAKE_LOCK deny

adb shell appops set com.sec.enterprise.knox.cloudmdm.smdms RUN_ANY_IN_BACKGROUND deny
adb shell appops set com.sec.enterprise.knox.cloudmdm.smdms RUN_IN_BACKGROUND deny
adb shell appops set com.sec.enterprise.knox.cloudmdm.smdms START_FOREGROUND deny
adb shell appops set com.sec.enterprise.knox.cloudmdm.smdms WAKE_LOCK deny
```

#### Step 4: Restore settings (optional)
```
adb shell settings put global device_provisioned 1
adb shell settings put secure user_setup_complete 1
```

#### Step 5: Reboot to verify
```
adb shell reboot
```

> After reboot, KG should stay gone. The appops restrictions persist across reboots.
> रिबूट के बाद भी KG वापस नहीं आना चाहिए।

---

## How It Works / यह कैसे काम करता है

1. Setting `device_provisioned=0` tricks the system into thinking the device setup is incomplete, which breaks the KG enforcement loop temporarily.
2. With KG inactive, AppOps restrictions are applied to the EMM packages to deny them WAKE_LOCK, RUN_IN_BACKGROUND, and START_FOREGROUND privileges.
3. These restrictions prevent the Knox apps from launching their lock screen activity, even after reboot.

**These AppOps restrictions persist across reboots on Android 14.**

---

## Troubleshooting / समस्या समाधान

### KG returns after reboot
Re-run `KG_Bypass.bat` (it will repeat the full process).  
Or manually run the AppOps commands again while KG is active:
```
adb shell settings put global device_provisioned 0
<wait for reboot, KG should clear>
adb shell appops set com.sds.emm.cloud.knox.samsung RUN_ANY_IN_BACKGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung RUN_IN_BACKGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung START_FOREGROUND deny
adb shell appops set com.sds.emm.cloud.knox.samsung WAKE_LOCK deny
```

### EMM app package names are different
Find the correct package names:
```
adb shell pm list packages | findstr knox
adb shell pm list packages | findstr mdm
adb shell pm list packages | findstr emm
```

### "Cannot disable a protected package" error
This is expected. You don't need to disable the package — the AppOps restrictions are enough to block KG.

---

## Method 2: Odin Flash + ADB (Alternative)

If Method 1 doesn't work, try this alternative:

1. Flash stock firmware via Odin (use CSC, not HOME_CSC)
2. Before touching anything on the phone, connect ADB and immediately run the AppOps block commands from Step 3 above
3. Then set `device_provisioned=1` and `user_setup_complete=1`
4. Reboot

> The key is to block the EMM apps **before** they complete their first-run enrollment.

---

## Limitations / सीमाएँ

- Device admin apps remain installed and active — they just can't show the KG lock screen.
- Admin policies (like lock task mode) may still be enforced.
- If the EMM app receives an update, AppOps may reset — repeat the process.
- This does NOT:
  - Unlock the bootloader
  - Remove the device owner
  - Allow OEM Unlock toggle access
- For a permanent fix, a Knox OFF firmware (from CK Mobile Care or GiveMeROM) or an EMM tool (EFT Pro, UnlockTool) is needed.

---

## Prevention / सावधानियाँ

- DO NOT factory reset from recovery — this will clear AppOps and re-trigger KG.
- DO NOT open any Knox-related apps.
- DO NOT connect to a corporate Wi-Fi/network that might trigger re-enrollment.

---

## Credits

Discovered and documented during real-time debugging on SM-A042F (Android 14, BIT-G firmware).

Tool used: ADB (Android Debug Bridge)
