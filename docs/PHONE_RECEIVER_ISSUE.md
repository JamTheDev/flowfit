# Phone Not Receiving Data - Issue Found! 🔍

## 🎉 Good News: Watch is Working Perfectly!

Your logs show:
```
I/WatchToPhoneSync: √ Message sent successfully to Marcus: 17808
I/WatchToPhoneSync: √ Message sent successfully to Marcus: 17809
I/WatchToPhoneSync: √ Message sent successfully to Marcus: 17810
I/flutter: 💡 Auto-sync to phone successful
```

**The watch is sending data successfully!** ✅

## ❌ The Problem: Phone Not Receiving

The issue is that **you're running the WATCH app on both devices**. The phone needs to:
1. Have the FlowFit app installed
2. Have the `PhoneDataListenerService` running
3. Be listening for messages on the `/heart_rate` path

## 🔍 Diagnosis Steps

### Step 1: Check if Phone App is Running

On your phone (Marcus), run:
```bash
# Get phone device ID
adb devices

# Check if FlowFit is installed on phone
adb -s [PHONE_DEVICE_ID] shell pm list packages | grep flowfit

# Check if service is registered
adb -s [PHONE_DEVICE_ID] shell dumpsys package com.example.flowfit | grep PhoneDataListenerService
```

### Step 2: Check Phone Logs

```bash
# Watch phone logs for incoming messages
adb -s [PHONE_DEVICE_ID] logcat | grep -E "PhoneDataListener|WearableListenerService|MESSAGE_RECEIVED"
```

**Expected logs if working:**
```
I/PhoneDataListener: Message received from watch
I/PhoneDataListener: Path: /heart_rate
I/PhoneDataListener: Heart rate data received: {"bpm":80,...}
```

**If you see NOTHING**, the service isn't receiving messages.

## 🔧 The Fix: Ensure Phone App is Properly Configured

### Issue 1: Phone App Not Installed

**Solution:** Install the app on your phone:
```bash
# Build and install on phone
flutter build apk
adb -s [PHONE_DEVICE_ID] install build/app/outputs/flutter-apk/app-debug.apk
```

### Issue 2: Service Not Registered on Phone

Check your `AndroidManifest.xml`:

```xml
<!-- This service MUST be in the phone app's manifest -->
<service
    android:name=".PhoneDataListenerService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data
            android:host="*"
            android:pathPrefix="/heart_rate"
            android:scheme="wear" />
    </intent-filter>
</service>
```

**CRITICAL:** The `pathPrefix` must match what the watch is sending!

### Issue 3: Capability Declaration Missing

The phone needs to declare the capability so the watch can find it.

**Create:** `android/app/src/main/res/values/wear.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="android_wear_capabilities">
        <item>flowfit_phone_app</item>
    </string-array>
</resources>
```

This tells the watch "I'm a phone that can receive FlowFit data!"

## 📱 Phone vs Watch App Configuration

### Current Setup (PROBLEM):
```
Watch App:
  - Has PhoneDataListenerService ✅
  - Sends messages ✅
  - Declares capability ❌ (should be on phone!)

Phone App:
  - Same APK as watch ❌
  - Service registered but not running ❌
  - No capability declaration ❌
```

### Correct Setup (SOLUTION):
```
Watch App:
  - Sends messages ✅
  - Has HealthTrackingManager ✅
  - Has WatchToPhoneSyncManager ✅

Phone App:
  - Has PhoneDataListenerService ✅
  - Service running in background ✅
  - Declares "flowfit_phone_app" capability ✅
  - Receives messages ✅
```

## 🎯 Quick Fix Steps

### 1. Create Capability Declaration

Create `android/app/src/main/res/values/wear.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="android_wear_capabilities">
        <item>flowfit_phone_app</item>
    </string-array>
</resources>
```

### 2. Verify AndroidManifest.xml

Ensure this is in your manifest:

```xml
<service
    android:name=".PhoneDataListenerService"
    android:enabled="true"
    android:exported="true">
    <intent-filter>
        <action android:name="com.google.android.gms.wearable.MESSAGE_RECEIVED" />
        <data
            android:host="*"
            android:pathPrefix="/heart_rate"
            android:scheme="wear" />
    </intent-filter>
</service>
```

### 3. Rebuild and Install on Phone

```bash
# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk

# Install on PHONE (not watch!)
adb -s [PHONE_DEVICE_ID] install build/app/outputs/flutter-apk/app-debug.apk
```

### 4. Launch Phone App

```bash
# Launch the app on phone
adb -s [PHONE_DEVICE_ID] shell am start -n com.example.flowfit/.MainActivity
```

### 5. Watch Phone Logs

```bash
# In one terminal, watch phone logs
adb -s [PHONE_DEVICE_ID] logcat | grep -E "PhoneDataListener|MESSAGE_RECEIVED"

# In another terminal, watch watch logs
adb -s [WATCH_DEVICE_ID] logcat | grep WatchToPhoneSync
```

### 6. Send Test Data from Watch

On the watch, trigger a heart rate reading. You should see:

**Watch logs:**
```
I/WatchToPhoneSync: √ Message sent successfully to Marcus: 17812
```

**Phone logs:**
```
I/PhoneDataListener: Message received from watch
I/PhoneDataListener: Path: /heart_rate
I/PhoneDataListener: Heart rate data received: {"bpm":82,...}
```

## 🐛 Debugging: Why Phone Closes

You mentioned "the phone closes after" - this suggests:

### Possible Cause 1: App Crashes on Phone

Check phone crash logs:
```bash
adb -s [PHONE_DEVICE_ID] logcat | grep -E "FATAL|AndroidRuntime"
```

### Possible Cause 2: Service Not Starting

The `PhoneDataListenerService` might not be starting. Check:
```bash
adb -s [PHONE_DEVICE_ID] shell dumpsys activity services | grep PhoneDataListener
```

### Possible Cause 3: Permission Issues on Phone

The phone might need Bluetooth permissions:
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

## 📋 Complete Phone Setup Checklist

- [ ] `wear.xml` created with capability declaration
- [ ] `PhoneDataListenerService` in AndroidManifest.xml
- [ ] Service has correct intent-filter with `/heart_rate` path
- [ ] App installed on phone
- [ ] App launched on phone at least once
- [ ] Bluetooth enabled on both devices
- [ ] Devices paired
- [ ] Phone logs show service is running

## 🎯 Expected Flow After Fix

```
Watch:
  1. Collects HR data (82 bpm)
  2. Finds phone node "Marcus"
  3. Sends message to /heart_rate
  4. Logs: "Message sent successfully"

Phone:
  1. PhoneDataListenerService receives message
  2. Logs: "Message received from watch"
  3. Logs: "Heart rate data received: {bpm:82}"
  4. Sends to Flutter via EventChannel
  5. Flutter UI updates with data
```

## 🚀 Next Steps

1. **Create `wear.xml`** with capability declaration
2. **Rebuild and install on phone**
3. **Launch phone app**
4. **Watch logs on both devices**
5. **Send test data from watch**
6. **Verify phone receives data**

---

**Generated:** November 25, 2025  
**Status:** Watch working ✅, Phone setup needed ⚠️  
**Next:** Create wear.xml and test phone reception
