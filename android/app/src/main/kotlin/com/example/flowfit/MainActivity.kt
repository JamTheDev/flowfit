package com.example.flowfit

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.MotionEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.EventChannel
import com.samsung.wearable_rotary.WearableRotaryPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class MainActivity: FlutterActivity() {
    companion object {
        private const val TAG = "MainActivity"
    }
    
    private val CHANNEL = "com.flowfit.watch/data"
    private val EVENT_CHANNEL = "com.flowfit.watch/heartrate"
    private val PERMISSION_REQUEST_CODE = 1001
    
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var heartRateEventSink: EventChannel.EventSink? = null
    private var healthTrackingManager: HealthTrackingManager? = null
    private var watchToPhoneSyncManager: WatchToPhoneSyncManager? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(Dispatchers.Main)
    
    private var lastHeartRateData: Map<String, Any?>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Make background transparent for round screens (VGV best practice)
        intent.putExtra("background_mode", "transparent")
        super.onCreate(savedInstanceState)
        
        // Initialize health tracking manager
        initializeHealthTracking()
    }
    
    private fun initializeHealthTracking() {
        // CRITICAL: Use applicationContext instead of 'this' (activity context)
        // This ensures the HealthTrackingService survives activity lifecycle changes
        healthTrackingManager = HealthTrackingManager(
            context = applicationContext,  // KEY CHANGE: Use Application context
            onHeartRateData = { data ->
                // Convert to map for Flutter
                val dataMap = mapOf(
                    "bpm" to data.bpm,
                    "ibiValues" to data.ibiValues,
                    "timestamp" to data.timestamp,
                    "status" to data.status
                )
                
                // Store last reading
                lastHeartRateData = dataMap
                
                // Send to Flutter via event channel
                mainHandler.post {
                    heartRateEventSink?.success(dataMap)
                }
            },
            onError = { code, message ->
                Log.e(TAG, "Health tracking error: $code - $message")
                mainHandler.post {
                    heartRateEventSink?.error(code, message, null)
                }
            }
        )
        
        // Initialize watch-to-phone sync manager (also use application context)
        watchToPhoneSyncManager = WatchToPhoneSyncManager(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Samsung Health Sensor method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestPermission(result)
                "checkPermission" -> checkPermission(result)
                "connectWatch" -> connectWatch(result)
                "disconnectWatch" -> disconnectWatch(result)
                "isWatchConnected" -> isWatchConnected(result)
                "startHeartRate" -> startHeartRate(result)
                "stopHeartRate" -> stopHeartRate(result)
                "getCurrentHeartRate" -> getCurrentHeartRate(result)
                else -> result.notImplemented()
            }
        }
        
        // Watch-to-Phone sync method channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.watch/sync").setMethodCallHandler { call, result ->
            when (call.method) {
                "sendHeartRateToPhone" -> sendHeartRateToPhone(call, result)
                "sendBatchToPhone" -> sendBatchToPhone(result)
                "checkPhoneConnection" -> checkPhoneConnection(result)
                "getConnectedNodesCount" -> getConnectedNodesCount(result)
                else -> result.notImplemented()
            }
        }
        
        // Heart rate event channel for streaming data (watch side)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    heartRateEventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    heartRateEventSink = null
                }
            }
        )
        
        // Phone data listener event channel (phone side - receives from watch)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flowfit.phone/heartrate").setStreamHandler(
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
    }

    /**
     * Request body sensor permission from the user
     * Uses health.READ_HEART_RATE for Android 15+ (BAKLAVA), BODY_SENSORS for older versions
     */
    private fun requestPermission(result: MethodChannel.Result) {
        try {
            // Determine which permission to request based on Android version
            val permission = if (android.os.Build.VERSION.SDK_INT >= 35) { // Android 15 (BAKLAVA)
                "android.permission.health.READ_HEART_RATE"
            } else {
                Manifest.permission.BODY_SENSORS
            }
            
            if (ContextCompat.checkSelfPermission(this, permission) 
                == PackageManager.PERMISSION_GRANTED) {
                // Permission already granted
                result.success(true)
            } else {
                // Store the result to respond after permission dialog
                pendingPermissionResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(permission),
                    PERMISSION_REQUEST_CODE
                )
            }
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to request body sensor permission",
                e.message
            )
        }
    }

    /**
     * Check the current body sensor permission status
     * Checks health.READ_HEART_RATE for Android 15+, BODY_SENSORS for older versions
     */
    private fun checkPermission(result: MethodChannel.Result) {
        try {
            // Determine which permission to check based on Android version
            val permission = if (android.os.Build.VERSION.SDK_INT >= 35) { // Android 15 (BAKLAVA)
                "android.permission.health.READ_HEART_RATE"
            } else {
                Manifest.permission.BODY_SENSORS
            }
            
            val status = when (ContextCompat.checkSelfPermission(this, permission)) {
                PackageManager.PERMISSION_GRANTED -> "granted"
                PackageManager.PERMISSION_DENIED -> {
                    // Check if we should show rationale (user denied but can ask again)
                    if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {
                        "denied"
                    } else {
                        // User permanently denied or hasn't been asked yet
                        "denied"
                    }
                }
                else -> "notDetermined"
            }
            result.success(status)
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to check body sensor permission",
                e.message
            )
        }
    }

    /**
     * Handle permission request result
     */
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    /**
     * Connect to Samsung Health services
     */
    private fun connectWatch(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        try {
            // Use callback-based connection to wait for ConnectionListener
            manager.connect { success, error ->
                mainHandler.post {
                    if (success) {
                        result.success(true)
                    } else {
                        result.error(
                            "CONNECTION_FAILED",
                            error ?: "Unknown connection error",
                            null
                        )
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error connecting to watch", e)
            result.error(
                "CONNECTION_FAILED",
                "Failed to connect: ${e.message}",
                null
            )
        }
    }

    /**
     * Disconnect from Samsung Health services
     */
    private fun disconnectWatch(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.disconnect()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error disconnecting from watch", e)
            result.error(
                "DISCONNECT_ERROR",
                "Failed to disconnect: ${e.message}",
                null
            )
        }
    }

    /**
     * Check if currently connected to Samsung Health services
     */
    private fun isWatchConnected(result: MethodChannel.Result) {
        val connected = healthTrackingManager?.isConnected() ?: false
        result.success(connected)
    }

    /**
     * Start heart rate tracking
     */
    private fun startHeartRate(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "INITIALIZATION_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        if (!manager.isConnected()) {
            result.error(
                "NOT_CONNECTED",
                "Not connected to Health Tracking Service",
                null
            )
            return
        }
        
        try {
            val started = manager.startTracking()
            result.success(started)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to start tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Stop heart rate tracking
     */
    private fun stopHeartRate(result: MethodChannel.Result) {
        try {
            healthTrackingManager?.stopTracking()
            result.success(null)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping heart rate tracking", e)
            result.error(
                "TRACKING_ERROR",
                "Failed to stop tracking: ${e.message}",
                null
            )
        }
    }

    /**
     * Get the current/last heart rate reading
     */
    private fun getCurrentHeartRate(result: MethodChannel.Result) {
        result.success(lastHeartRateData)
    }

    // Support for rotary input (rotating bezel on Galaxy Watch)
    override fun onGenericMotionEvent(event: MotionEvent?): Boolean {
        return when {
            WearableRotaryPlugin.onGenericMotionEvent(event) -> true
            else -> super.onGenericMotionEvent(event)
        }
    }
    
    /**
     * Send heart rate data to phone
     */
    private fun sendHeartRateToPhone(call: MethodCall, result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.error(
                "SYNC_ERROR",
                "Sync manager not initialized",
                null
            )
            return
        }

        val jsonData = call.argument<String>("data")
        if (jsonData == null) {
            result.error(
                "INVALID_DATA",
                "No data provided",
                null
            )
            return
        }

        syncManager.sendHeartRateToPhone(jsonData) { success ->
            mainHandler.post {
                result.success(success)
            }
        }
    }

    /**
     * Send batch data to phone
     * Retrieves all collected TrackedData and sends as JSON array
     */
    private fun sendBatchToPhone(result: MethodChannel.Result) {
        val manager = healthTrackingManager
        if (manager == null) {
            result.error(
                "MANAGER_ERROR",
                "Health tracking manager not initialized",
                null
            )
            return
        }
        
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.error(
                "SYNC_ERROR",
                "Sync manager not initialized",
                null
            )
            return
        }

        scope.launch {
            try {
                // Get all valid HR data
                val data = manager.getValidHrData()
                
                if (data.isEmpty()) {
                    Log.w(TAG, "No data to send")
                    mainHandler.post {
                        result.success(false)
                    }
                    return@launch
                }
                
                // Serialize to JSON
                val json = Json.encodeToString(data)
                Log.i(TAG, "Sending batch of ${data.size} measurements to phone")
                
                // Send via sync manager
                syncManager.sendBatchToPhone(json) { success ->
                    mainHandler.post {
                        if (success) {
                            Log.i(TAG, "Batch sent successfully")
                        } else {
                            Log.e(TAG, "Failed to send batch")
                        }
                        result.success(success)
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error sending batch", e)
                mainHandler.post {
                    result.error("BATCH_ERROR", e.message, null)
                }
            }
        }
    }

    /**
     * Check if phone is connected
     */
    private fun checkPhoneConnection(result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.success(false)
            return
        }

        scope.launch {
            try {
                val connected = syncManager.checkPhoneConnection()
                mainHandler.post {
                    result.success(connected)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error checking phone connection", e)
                mainHandler.post {
                    result.success(false)
                }
            }
        }
    }

    /**
     * Get connected nodes count
     */
    private fun getConnectedNodesCount(result: MethodChannel.Result) {
        val syncManager = watchToPhoneSyncManager
        if (syncManager == null) {
            result.success(0)
            return
        }

        scope.launch {
            try {
                val count = syncManager.getConnectedNodesCount()
                mainHandler.post {
                    result.success(count)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting connected nodes count", e)
                mainHandler.post {
                    result.success(0)
                }
            }
        }
    }

    /**
     * Handle onDestroy lifecycle event
     * Complete cleanup of resources
     */
    override fun onDestroy() {
        super.onDestroy()
        // Clean up health tracking
        healthTrackingManager?.disconnect()
        healthTrackingManager = null
        // Clean up sync manager
        watchToPhoneSyncManager = null
        // Clean up event sink
        heartRateEventSink = null
    }
}