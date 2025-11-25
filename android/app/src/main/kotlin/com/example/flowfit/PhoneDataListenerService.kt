package com.example.flowfit

import android.content.Intent
import android.util.Log
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel

/**
 * Service to receive heart rate data from Galaxy Watch
 * Listens for messages sent via Wearable Data Layer API
 */
class PhoneDataListenerService : WearableListenerService() {
    companion object {
        private const val TAG = "PhoneDataListener"
        private const val MESSAGE_PATH = "/heart_rate"
        private const val BATCH_PATH = "/heart_rate_batch"
        
        // Static event sink for sending data to Flutter
        var eventSink: EventChannel.EventSink? = null
    }

    override fun onMessageReceived(messageEvent: MessageEvent) {
        super.onMessageReceived(messageEvent)
        
        Log.i(TAG, "Message received from watch")
        Log.i(TAG, "Path: ${messageEvent.path}")
        
        when (messageEvent.path) {
            MESSAGE_PATH -> {
                handleHeartRateData(messageEvent)
            }
            BATCH_PATH -> {
                handleBatchData(messageEvent)
            }
            else -> {
                Log.w(TAG, "Unknown message path: ${messageEvent.path}")
            }
        }
    }

    private fun handleHeartRateData(messageEvent: MessageEvent) {
        try {
            val jsonData = String(messageEvent.data, Charsets.UTF_8)
            Log.i(TAG, "Heart rate data received: $jsonData")
            
            // Send to Flutter via event channel
            eventSink?.success(jsonData)
            
            // Optionally launch the app if not running
            if (eventSink == null) {
                launchMainActivity(jsonData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling heart rate data", e)
            eventSink?.error("PARSE_ERROR", "Failed to parse heart rate data", e.message)
        }
    }

    private fun handleBatchData(messageEvent: MessageEvent) {
        try {
            val jsonData = String(messageEvent.data, Charsets.UTF_8)
            Log.i(TAG, "Batch data received: $jsonData")
            
            // Send to Flutter via event channel
            eventSink?.success(jsonData)
            
            // Optionally launch the app if not running
            if (eventSink == null) {
                launchMainActivity(jsonData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error handling batch data", e)
            eventSink?.error("PARSE_ERROR", "Failed to parse batch data", e.message)
        }
    }

    private fun launchMainActivity(data: String) {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("heart_rate_data", data)
            }
            startActivity(intent)
            Log.i(TAG, "Launched MainActivity with data")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch MainActivity", e)
        }
    }
}
