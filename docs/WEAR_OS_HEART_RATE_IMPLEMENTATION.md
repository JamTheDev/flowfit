# Wear OS Heart Rate Monitor - Implementation Plan

## 🎯 Overview
This plan updates your FlowFit Wear OS app to have a streamlined heart rate monitoring interface with direct phone sync capability, following Wear OS best practices.

## ✅ Phase 1: UI Components (COMPLETED)

### Files Created:

#### 1. `lib/screens/wear/wear_heart_rate_screen.dart` ✅
Modern Wear OS heart rate screen with:
- ✅ Large BPM display (48sp)
- ✅ Real-time monitoring with Samsung Health SDK
- ✅ One-tap "Send to Phone" button
- ✅ Ambient mode support
- ✅ Pulse animation during monitoring
- ✅ Material Design 3 styling
- ✅ Connection status indicator
- ✅ IBI value display

**Features:**
- Start/Stop monitoring button
- Real-time heart rate updates
- Animated heart icon (pulses with heartbeat)
- Send to phone functionality (placeholder)
- Ambient mode (low-power display)
- Status messages

#### 2. `lib/screens/wear/wear_dashboard.dart` ✅
Updated dashboard with:
- ✅ Navigation to heart rate screen
- ✅ "Measure" button on heart rate page
- ✅ Existing rotary input support
- ✅ Page-based navigation

## 🚀 How to Test

### Run on Watch
```bash
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart
```

### Navigation Flow
1. App opens to dashboard
2. Swipe or rotate to heart rate page
3. Tap "Measure" button
4. Opens full heart rate monitoring screen
5. Tap "Start" to begin monitoring
6. See real-time BPM updates
7. Tap "Send" to send data to phone (placeholder)
8. Tap "Stop" to end monitoring

## 📱 UI Specifications

### Color Scheme
- **Primary**: Deep Blue (#1976D2) - Samsung Health style
- **Accent**: Bright Red (#F44336) - for heart rate
- **Background**: True Black (#000000) - AMOLED optimization
- **Text**: White (#FFFFFF) - high contrast
- **Send Button**: Bright Blue (#00B5FF)

### Typography
- **BPM Display**: 48sp (extra large)
- **Labels**: 16sp (medium)
- **Status**: 12sp (small)
- **Font**: Roboto (system default)

### Button Sizes
- **Start/Stop**: 120x48dp
- **Send to Phone**: 140x48dp
- **Corner radius**: 24dp
- **Elevation**: 4dp

## 🔄 Data Flow

```
[Samsung Health SDK]
        ↓
[WatchBridgeService]
        ↓
[HeartRateData Model]
        ↓
[Wear UI Display] → [Send Button Pressed]
        ↓
[WatchToPhoneSync Service] (TODO)
        ↓
[Wearable Data Layer API]
        ↓
[Phone App Receiver]
        ↓
[Supabase Sync]
```

## 📋 Implementation Status

### ✅ Completed (Phase 1)
- [x] Create `wear_heart_rate_screen.dart` with large BPM display
- [x] Add "Send to Phone" button with Material Design 3 styling
- [x] Implement WatchShape adaptive layouts
- [x] Create ambient mode display
- [x] Add connection status indicator
- [x] Add pulse animation
- [x] Integrate with WatchBridgeService
- [x] Add navigation from dashboard

### 🔄 In Progress (Phase 2)
- [ ] Verify WatchBridgeService heart rate streaming works on device
- [ ] Add haptic feedback on button press
- [ ] Test on physical Galaxy Watch

### ⏳ TODO (Phase 3)
- [ ] Create `WatchToPhoneSync` service using MessageClient
- [ ] Implement data serialization (JSON format)
- [ ] Add retry logic for failed transfers
- [ ] Create connection status checker

### ⏳ TODO (Phase 4)
- [ ] Update `DataListenerService` in Android/Kotlin (phone side)
- [ ] Parse incoming heart rate messages
- [ ] Display notification on phone when data received
- [ ] Save to local database + Supabase

### ⏳ TODO (Phase 5)
- [ ] Add loading states and animations
- [ ] Implement battery optimization
- [ ] Add settings screen
- [ ] Test end-to-end on physical devices
- [ ] Add haptic feedback

## 🎯 Example Usage Flow

1. **User opens FlowFit on watch**
   - Dashboard shows with heart icon
   - Swipe/rotate to heart rate page

2. **Taps "Measure" button**
   - Navigates to full HR monitor screen
   - Shows connection status

3. **Taps "Start" button**
   - Automatic permission check
   - Samsung Health SDK starts monitoring
   - Heart icon pulses

4. **BPM updates in real-time**
   - Large number display (e.g., 72 BPM)
   - Small IBI values below
   - Smooth pulse animation

5. **User taps "Send to Phone" button**
   - Button shows loading spinner
   - Data packaged and sent (TODO: implement)
   - Success message "Sent ✓"

6. **Phone receives data** (TODO)
   - Notification appears
   - Data saved to Supabase
   - Watch shows "Synced ✓"

## 📱 Ambient Mode Behavior

### Normal Mode → Ambient Mode
- Screen dims to black
- BPM shows in white24 (very dim)
- Heart icon shows in white24
- No animations
- Sensor polling continues (reduced frequency)

### Ambient Mode → Normal Mode
- Full color returns
- Resume normal polling
- Animations restart
- Full UI visible

## 🔒 Permissions

Already configured in AndroidManifest.xml:
- ✅ `BODY_SENSORS` - Access heart rate sensor
- ✅ `WAKE_LOCK` - Keep device awake
- ✅ `FOREGROUND_SERVICE` - Background tracking
- ✅ `FOREGROUND_SERVICE_HEALTH` - Health services

## 🐛 Known Issues & Solutions

### Issue: Material icons not showing
**Solution:** Icons are from Flutter's built-in set, no additional assets needed

### Issue: Layout overflow on round watches
**Solution:** Using SafeArea and proper padding

### Issue: Connection to Samsung Health fails
**Solution:** 
1. Check permissions granted
2. Verify Samsung Health is installed
3. Check watch model supports SDK (Watch4+)

## 📚 Next Steps

### Immediate (You can test now)
1. Run on watch: `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart`
2. Navigate to heart rate page
3. Tap "Measure"
4. Tap "Start" and test monitoring
5. Check if BPM updates appear

### Short Term (Phase 2-3)
1. Test on physical device
2. Implement WatchToPhoneSync service
3. Add Wearable Data Layer API integration

### Long Term (Phase 4-5)
1. Complete phone-side receiver
2. Add Supabase sync
3. Polish UI and animations
4. Battery optimization

## 🎉 What You Have Now

✅ **Beautiful Wear OS UI** - Modern, Material 3 design
✅ **Real-time monitoring** - Connects to Samsung Health SDK
✅ **Ambient mode** - Battery-efficient display
✅ **Pulse animation** - Visual feedback during monitoring
✅ **Send button** - Ready for phone sync (needs implementation)
✅ **Status indicators** - Connection and monitoring state
✅ **Adaptive layout** - Works on round and square watches

## 🚀 Test Commands

```bash
# Run on watch
flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp -t lib/main_wear.dart

# Watch logs
adb -s adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp logcat | findstr "FlowFit"

# Hot reload (after making changes)
# Press 'r' in terminal
```

---

**Status**: Phase 1 Complete ✅
**Next**: Test on physical watch and implement phone sync
