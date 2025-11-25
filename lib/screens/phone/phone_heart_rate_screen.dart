import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/tracked_data.dart';

/// Screen for displaying heart rate data received from Galaxy Watch
/// Shows real-time BPM, IBI values, and connection status
class PhoneHeartRateScreen extends StatefulWidget {
  const PhoneHeartRateScreen({super.key});

  @override
  State<PhoneHeartRateScreen> createState() => _PhoneHeartRateScreenState();
}

class _PhoneHeartRateScreenState extends State<PhoneHeartRateScreen> {
  static const EventChannel _eventChannel =
      EventChannel('com.flowfit.phone/heartrate');

  final List<TrackedData> _receivedData = [];
  StreamSubscription? _subscription;
  bool _isConnected = false;
  DateTime? _lastDataTime;

  @override
  void initState() {
    super.initState();
    _listenToWatchData();
  }

  void _listenToWatchData() {
    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) {
        try {
          final jsonString = data as String;
          final jsonData = jsonDecode(jsonString);

          setState(() {
            _isConnected = true;
            _lastDataTime = DateTime.now();

            if (jsonData is List) {
              // Batch data
              final batch = jsonData
                  .map((item) => TrackedData.fromJson(item as Map<String, dynamic>))
                  .toList();
              _receivedData.addAll(batch);
              
              // Keep only last 100 readings
              if (_receivedData.length > 100) {
                _receivedData.removeRange(0, _receivedData.length - 100);
              }
            } else {
              // Single data point
              final trackedData = TrackedData.fromJson(jsonData as Map<String, dynamic>);
              _receivedData.add(trackedData);
              
              // Keep only last 100 readings
              if (_receivedData.length > 100) {
                _receivedData.removeAt(0);
              }
            }
          });
        } catch (e) {
          debugPrint('Error parsing watch data: $e');
        }
      },
      onError: (error) {
        debugPrint('Error receiving watch data: $error');
        setState(() {
          _isConnected = false;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Heart Rate Data'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.watch : Icons.watch_off,
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _receivedData.isEmpty
          ? _buildEmptyState()
          : _buildDataList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.watch,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No data received yet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start heart rate tracking on your watch',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList() {
    // Show most recent data first
    final reversedData = _receivedData.reversed.toList();
    final latestData = reversedData.first;

    return Column(
      children: [
        // Large BPM display at top
        _buildLatestBpmCard(latestData),
        
        // Data freshness indicator
        if (_lastDataTime != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Last updated: ${_formatTimestamp(_lastDataTime!)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        
        const Divider(),
        
        // List of all readings
        Expanded(
          child: ListView.builder(
            itemCount: reversedData.length,
            itemBuilder: (context, index) {
              final data = reversedData[index];
              return _buildDataTile(data, index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLatestBpmCard(TrackedData data) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Current Heart Rate',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${data.hr}',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            if (data.ibi.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'IBI: ${data.ibi.take(5).join(", ")}${data.ibi.length > 5 ? "..." : ""} ms',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTile(TrackedData data, bool isLatest) {
    return ListTile(
      leading: Icon(
        Icons.favorite,
        color: isLatest ? Colors.red : Colors.grey,
      ),
      title: Text(
        'HR: ${data.hr} bpm',
        style: TextStyle(
          fontWeight: isLatest ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: data.ibi.isNotEmpty
          ? Text('IBI: ${data.ibi.take(4).join(", ")}${data.ibi.length > 4 ? "..." : ""} ms')
          : const Text('No IBI data'),
      trailing: isLatest
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Latest',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
