# Complete Watch-to-Phone Live Data Flow ✅

## 🎯 Your Setup: Watch → Phone UI (main.dart)

You want **live heart rate data** from your Galaxy Watch to appear in the **phone's Flutter UI** (main.dart → PhoneHomePage).

## 📊 Complete Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    GALAXY WATCH (Wear OS)                   │
├─────────────────────────────────────────────────────────────┤
│  1. Samsung Health SDK collects HR data (80-82 bpm)        │
│  2. HealthTrackingManager processes data                    │
│  3. Sends to Flutter via EventChannel                       │
│  4. WatchToPhoneSyncManager sends to phone                  │
│     └─> MessageClient.sendMessage("/heart_rate", json)     │
└─────────────────────────────────────────────────────────────┘
                            ║
                  Wearable Data Layer API
                  (Bluetooth/WiFi Network)
                            ║
┌─────────────────────────────────────────────────────────────┐
│                    ANDROID PHONE                            │
├─────────────────────────────────────────────────────────────┤
│  1. PhoneDataListenerService.onMessageReceived()           │
│     └─> Receives message on "/heart_rate" path             │
│  2. Decodes JSON data                                       │
│  3. Sends to Flutter via EventChannel.EventSink            │
│     └─> eventSink.success(jsonData)                        │
│  4. PhoneDataListener (Dart) receives data                 │
│  5. Converts JSON to HeartRateData model                   │
│  6. Emits to heartRateStream                               │
│  7. PhoneHomePage listens to stream                        │
│  8. Updates UI with live heart rate                        │
└─────────────────────────────────────────────────────────────┘
```

## ✅ What's Already Working

Based on your logs:

### Watch Side (100% Working):
```
✅ Heart rate collection: 80-82 bpm
✅ Data processing: Valid HR data stored
✅ Phone discovery: Found "Marcus" (2494c51c)
✅ Message sending: Messages 17808-17811 sent successfully
✅ Auto-sync: Working perfectly
```

### Phone Side (Needs Verification):
```
❓ PhoneDataListenerService receiving messages
❓ EventChannel sending to Flutter
❓ PhoneDataListener processing data
❓ PhoneHomePage displaying data
```

## 🔧 Complete Setup Checklist

### 1. ✅ Watch App (Already Working)
- [x] HealthTrackingManager collecting data
- [x] WatchToPhoneSyncManager sending messages
- [x] Finding phone node "Marcus"
- [x] Sending to `/heart_rate` path

### 2. ⚠️ Phone App (Needs Verification)

#### A. Capability Declaration
**File:** `android/app/src/main/res/values/wear.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string-array name="android_wear_capabilities">
        <item>flowfit_phone_app</item>
    </string-array>
</resources>
```

**Status:** ✅ Created

#### B. Service Registration
**File:** `android/app/src/main/AndroidManifest.xml`

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

**Status:** ✅ Already in manifest

#### C. EventChannel Setup
**File:** `android/app/src/main/kotlin/com/example/flowfit/MainActivity.kt`

```kotlin
// Phone data listener event channel (phone side - receives from watch)
EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.phone/heartrate")
    .setStreamHandler(
        object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                PhoneDataListenerService.eventSink = events
                Log.i(TAG, "Phone data listener event sink registered")
            }
            
            override fun onCancel(arguments: Any?) {
                PhoneDataListenerService.eventSink = null
                Log.i(TAG, "Phone data listener event sink cancelled")
            }
        }
    )
```

**Status:** ✅ Already configured

#### D. Flutter UI
**File:** `lib/main.dart` → `lib/screens/phone_home.dart`

```dart
// PhoneHomePage listens to heart rate stream
_heartRateSubscription = _dataListener.heartRateStream.listen(
  (heartRateData) {
    setState(() {
      _latestHeartRate = heartRateData;
      _heartRateHistory.insert(0, heartRateData);
      _isConnected = true;
      _statusMessage = 'Received from watch';
    });
  },
);
```

**Status:** ✅ Already implemented

## 🧪 Testing Steps

### Step 1: Install Phone App

```bash
# Build APK
flutter clean
flutter build apk

# Find your phone device ID
adb devices

# Install on phone (NOT watch!)
adb -s [PHONE_DEVICE_ID] install build/app/outputs/flutter-apk/app-debug.apk
```

### Step 2: Launch Phone App

```bash
# Launch the app
adb -s [PHONE_DEVICE_ID] shell am start -n com.example.flowfit/.MainActivity

# Or just tap the FlowFit icon on your phone
```

### Step 3: Monitor Phone Logs

```bash
# In one terminal, watch phone logs
adb -s [PHONE_DEVICE_ID] logcat -c  # Clear logs first
adb -s [PHONE_DEVICE_ID] logcat | grep -E "PhoneDataListener|MainActivity|EventChannel"
```

**Expected logs:**
```
I/MainActivity: Phone data listener event sink registered
I/PhoneDataListener: Message received from watch
I/PhoneDataListener: Path: /heart_rate
I/PhoneDataListener: Heart rate data received: {"bpm":82,...}
```

### Step 4: Start Heart Rate on Watch

On your Galaxy Watch:
1. Open FlowFit app
2. Start heart rate tracking
3. Watch should show: "Auto-sync to phone successful"

### Step 5: Verify Phone UI

On your phone, you should see:
- ✅ Watch icon turns GREEN (connected)
- ✅ Current heart rate displays (e.g., "82 BPM")
- ✅ Heart rate zone shows (e.g., "Light")
- ✅ Recent readings list updates
- ✅ Status shows "Received from watch"

## 🐛 Troubleshooting

### Issue 1: Phone Not Receiving Data

**Symptoms:**
- Watch logs show "Message sent successfully"
- Phone logs show nothing

**Solution:**
```bash
# Check if service is registered
adb -s [PHONE_DEVICE_ID] shell dumpsys package com.example.flowfit | grep PhoneDataListenerService

# Check if app is running
adb -s [PHONE_DEVICE_ID] shell ps | grep flowfit

# Check Bluetooth
adb -s [PHONE_DEVICE_ID] shell settings get global bluetooth_on
# Should return: 1
```

### Issue 2: EventChannel Not Registered

**Symptoms:**
- Phone logs show "Message received from watch"
- But no data in Flutter UI

**Solution:**
```bash
# Check MainActivity logs
adb -s [PHONE_DEVICE_ID] logcat | grep "event sink"

# Should see:
# I/MainActivity: Phone data listener event sink registered
```

If you DON'T see this, the Flutter app hasn't registered the EventChannel yet. Make sure the phone app is in the foreground.

### Issue 3: JSON Parsing Error

**Symptoms:**
- Phone receives data
- Flutter logs show parsing error

**Solution:**
Check the JSON format matches:
```json
{
  "bpm": 82,
  "timestamp": 1764050589641,
  "status": "active",
  "ibiValues": []
}
```

### Issue 4: Phone App Closes

**Symptoms:**
- Phone app launches then closes immediately

**Solution:**
```bash
# Check for crashes
adb -s [PHONE_DEVICE_ID] logcat | grep -E "FATAL|AndroidRuntime|CRASH"
```

## 📱 Complete Test Script

Save this as `test_watch_to_phone.sh`:

```bash
#!/bin/bash

echo "🔍 Testing Watch-to-Phone Data Flow"
echo "===================================="
echo ""

# Get device IDs
WATCH_DEVICE=$(adb devices | grep "RFAX21TD0NA" | awk '{print $1}')
PHONE_DEVICE=$(adb devices | grep -v "List" | grep -v "RFAX21TD0NA" | awk '{print $1}' | head -1)

echo "📱 Watch: $WATCH_DEVICE"
echo "📱 Phone: $PHONE_DEVICE"
echo ""

# Clear logs
echo "🧹 Clearing logs..."
adb -s $PHONE_DEVICE logcat -c
adb -s $WATCH_DEVICE logcat -c

# Launch phone app
echo "🚀 Launching phone app..."
adb -s $PHONE_DEVICE shell am start -n com.example.flowfit/.MainActivity
sleep 3

# Monitor both devices
echo "👀 Monitoring data flow..."
echo "   (Press Ctrl+C to stop)"
echo ""

# Watch logs in parallel
(adb -s $WATCH_DEVICE logcat | grep --line-buffered "WatchToPhoneSync" | sed 's/^/[WATCH] /') &
(adb -s $PHONE_DEVICE logcat | grep --line-buffered -E "PhoneDataListener|MainActivity.*event" | sed 's/^/[PHONE] /') &

wait
```

## 🎯 Expected Complete Flow

### Timeline:

```
T+0s:  Phone app launches
       └─> MainActivity.onCreate()
       └─> EventChannel registered
       └─> PhoneHomePage.initState()
       └─> PhoneDataListener.startListening()

T+1s:  Watch starts heart rate tracking
       └─> HealthTrackingManager collects data
       └─> HR: 82 bpm

T+2s:  Watch sends data to phone
       └─> WatchToPhoneSyncManager.sendHeartRateToPhone()
       └─> MessageClient.sendMessage("/heart_rate", json)
       └─> Log: "Message sent successfully to Marcus: 17812"

T+3s:  Phone receives data
       └─> PhoneDataListenerService.onMessageReceived()
       └─> Log: "Message received from watch"
       └─> Log: "Heart rate data received: {bpm:82,...}"
       └─> eventSink.success(jsonData)

T+4s:  Flutter processes data
       └─> PhoneDataListener.heartRateStream emits
       └─> HeartRateData(bpm: 82, ...)
       └─> PhoneHomePage._heartRateSubscription receives

T+5s:  UI updates
       └─> setState() called
       └─> _latestHeartRate = 82 bpm
       └─> _isConnected = true
       └─> UI shows: "82 BPM" with green watch icon
```

## ✅ Success Criteria

Your setup is working when you see:

### On Watch:
- [x] Heart rate tracking active
- [x] "Auto-sync to phone successful"
- [x] Logs: "Message sent successfully to Marcus"

### On Phone:
- [ ] Logs: "Message received from watch"
- [ ] Logs: "Heart rate data received"
- [ ] UI: Green watch icon
- [ ] UI: Current heart rate displayed
- [ ] UI: Recent readings list updates
- [ ] UI: Status shows "Received from watch"

## 🚀 Quick Start Commands

```bash
# 1. Build and install on phone
flutter build apk
adb -s [PHONE_DEVICE_ID] install build/app/outputs/flutter-apk/app-debug.apk

# 2. Launch phone app
adb -s [PHONE_DEVICE_ID] shell am start -n com.example.flowfit/.MainActivity

# 3. Monitor phone logs
adb -s [PHONE_DEVICE_ID] logcat | grep -E "PhoneDataListener|event sink"

# 4. Start heart rate on watch
# (Use watch UI to start tracking)

# 5. Watch for success
# Phone logs should show: "Message received from watch"
# Phone UI should show: Heart rate updating
```

---

**Generated:** November 25, 2025  
**Status:** Watch ✅ | Phone ⚠️ (needs testing)  
**Next:** Install on phone and verify data reception
