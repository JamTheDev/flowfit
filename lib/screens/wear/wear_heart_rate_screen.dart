import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';
import 'dart:async';
import '../../services/watch_bridge.dart';
import '../../services/watch_to_phone_sync.dart';
import '../../models/heart_rate_data.dart';
import '../../models/sensor_status.dart';

/// Modern Wear OS heart rate monitoring screen
/// Features:
/// - Large BPM display
/// - Real-time monitoring with Samsung Health SDK
/// - One-tap send to phone button
/// - Ambient mode support
/// - Material Design 3 for Wear OS
class WearHeartRateScreen extends StatefulWidget {
  final WearShape shape;
  final WearMode mode;

  const WearHeartRateScreen({
    super.key,
    required this.shape,
    required this.mode,
  });

  @override
  State<WearHeartRateScreen> createState() => _WearHeartRateScreenState();
}

class _WearHeartRateScreenState extends State<WearHeartRateScreen>
    with SingleTickerProviderStateMixin {
  final WatchBridgeService _watchBridge = WatchBridgeService();
  final WatchToPhoneSync _phoneSync = WatchToPhoneSync();
  
  HeartRateData? _currentHeartRate;
  bool _isMonitoring = false;
  bool _isConnected = false;
  bool _isSending = false;
  bool _isPhoneConnected = false;
  String _statusMessage = 'Ready';
  
  StreamSubscription? _heartRateSubscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnection();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _checkConnection() async {
    if (!mounted) return;
    
    setState(() {
      _statusMessage = 'Checking permissions...';
    });

    try {
      // CRITICAL: Check permissions first
      final permissionStatus = await _watchBridge.checkPermission();
      
      if (permissionStatus != 'granted') {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Requesting permission...';
        });
        
        // Request permission
        final granted = await _watchBridge.requestPermission();
        
        if (!granted) {
          if (!mounted) return;
          setState(() {
            _isConnected = false;
            _statusMessage = 'Permission denied';
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _statusMessage = 'Connecting...';
      });

      // Connect to Samsung Health SDK
      final connected = await _watchBridge.connectToWatch();
      
      if (!connected) {
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _statusMessage = 'SDK unavailable';
        });
        return;
      }

      // Check phone connection
      final phoneConnected = await _phoneSync.checkPhoneConnection();
      
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _isPhoneConnected = phoneConnected;
        _statusMessage = 'Ready';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _statusMessage = 'Error';
      });
      debugPrint('Connection error: $e');
    }
  }

  Future<void> _toggleMonitoring() async {
    if (_isMonitoring) {
      await _stopMonitoring();
    } else {
      await _startMonitoring();
    }
  }

  Future<void> _startMonitoring() async {
    if (!_isConnected) {
      setState(() {
        _statusMessage = 'Connecting...';
      });
      await _checkConnection();
      if (!_isConnected) {
        setState(() {
          _statusMessage = 'Connection failed';
        });
        return;
      }
    }

    try {
      setState(() {
        _statusMessage = 'Starting...';
      });

      final started = await _watchBridge.startHeartRateTracking();
      
      if (!started) {
        setState(() {
          _statusMessage = 'Start failed';
        });
        return;
      }

      setState(() {
        _isMonitoring = true;
        _statusMessage = 'Monitoring';
      });

      _heartRateSubscription = _watchBridge.heartRateStream.listen(
        (heartRateData) {
          if (mounted) {
            setState(() {
              _currentHeartRate = heartRateData;
              _statusMessage = 'Active';
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isMonitoring = false;
              _statusMessage = 'Error';
            });
          }
          debugPrint('Heart rate error: $error');
        },
      );
    } catch (e) {
      setState(() {
        _isMonitoring = false;
        _statusMessage = 'Failed';
      });
      debugPrint('Start monitoring error: $e');
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _watchBridge.stopHeartRateTracking();
      await _heartRateSubscription?.cancel();
      
      setState(() {
        _isMonitoring = false;
        _statusMessage = 'Stopped';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping';
      });
    }
  }

  Future<void> _sendToPhone() async {
    if (_currentHeartRate == null) return;

    setState(() {
      _isSending = true;
      _statusMessage = 'Sending...';
    });

    try {
      final success = await _phoneSync.sendHeartRateToPhone(_currentHeartRate!);

      if (mounted) {
        setState(() {
          _isSending = false;
          _statusMessage = success ? 'Sent!' : 'Failed';
        });

        // Reset status
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _statusMessage = _isMonitoring ? 'Active' : 'Ready';
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _statusMessage = 'Error';
        });
      }
      debugPrint('Send error: $e');
    }
  }

  @override
  void dispose() {
    _heartRateSubscription?.cancel();
    _pulseController.dispose();
    _watchBridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAmbient = widget.mode == WearMode.ambient;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: isAmbient ? _buildAmbientMode() : _buildActiveMode(),
        ),
      ),
    );
  }

  Widget _buildActiveMode() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            _buildBpmDisplay(),
            const SizedBox(height: 16),
            _buildStartButton(),
            if (_currentHeartRate != null) ...[
              const SizedBox(height: 8),
              _buildSendButton(),
            ],
            const SizedBox(height: 12),
            _buildStatusIndicator(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBpmDisplay() {
    final bpm = _currentHeartRate?.bpm;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isMonitoring ? _pulseAnimation.value : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: _isMonitoring ? Colors.red : Colors.grey.shade700,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                bpm != null ? '$bpm' : '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'BPM',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: 100,
      height: 40,
      child: ElevatedButton.icon(
        onPressed: _toggleMonitoring,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isMonitoring ? Colors.red : Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: Icon(
          _isMonitoring ? Icons.pause : Icons.play_arrow,
          size: 18,
        ),
        label: Text(
          _isMonitoring ? 'Stop' : 'Start',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: 100,
      height: 36,
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _sendToPhone,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        icon: _isSending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.phone_android, size: 16),
        label: Text(
          _isSending ? 'Sending' : 'Send',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor = Colors.grey;
    if (_isConnected && _isMonitoring) {
      statusColor = Colors.green;
    } else if (_isConnected) {
      statusColor = Colors.blue;
    } else {
      statusColor = Colors.orange;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 10,
            color: statusColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAmbientMode() {
    final bpm = _currentHeartRate?.bpm;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.favorite,
          color: Colors.white24,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          bpm != null ? '$bpm' : '--',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white24,
          ),
        ),
        const Text(
          'BPM',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white10,
          ),
        ),
      ],
    );
  }
}
