import 'dart:async';
import 'package:flutter/services.dart';
import '../models/heart_rate_data.dart';
import '../models/sensor_error.dart';
import '../models/sensor_error_code.dart';
import 'package:logger/logger.dart';

/// Service for receiving heart rate data from Galaxy Watch
/// Uses Wearable Data Layer API to listen for messages from watch
/// 
/// This service listens to the EventChannel "com.flowfit.phone/heartrate"
/// which receives data from PhoneDataListenerService on the native Android side.
/// The data is transmitted from the watch via Wearable Data Layer API.
class PhoneDataListener {
  static const MethodChannel _methodChannel =
      MethodChannel('com.flowfit.phone/data');
  static const EventChannel _heartRateEventChannel =
      EventChannel('com.flowfit.phone/heartrate');

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  Stream<HeartRateData>? _heartRateStream;
  StreamController<HeartRateData>? _heartRateController;

  /// Get stream of heart rate data from watch
  /// 
  /// This stream receives heart rate data sent from the Galaxy Watch
  /// via the Wearable Data Layer API. The data is decoded from JSON
  /// and validated before being emitted.
  /// 
  /// Requirements: 8.2, 9.4
  Stream<HeartRateData> get heartRateStream {
    _heartRateStream ??= _heartRateEventChannel
        .receiveBroadcastStream()
        .map((dynamic event) {
      try {
        // Validate that event is a Map
        if (event == null) {
          _logger.e('Received null event from heart rate stream');
          throw SensorError(
            code: SensorErrorCode.unknown,
            message: 'Received null data from watch',
            details: 'Event channel emitted null value',
          );
        }

        if (event is! Map) {
          _logger.e('Received non-Map event: ${event.runtimeType}');
          throw SensorError(
            code: SensorErrorCode.unknown,
            message: 'Invalid data format from watch',
            details: 'Expected Map but got ${event.runtimeType}',
          );
        }

        // Convert to Map<String, dynamic>
        final jsonMap = Map<String, dynamic>.from(event);
        
        // Validate required fields (Requirements 9.4)
        _validateRequiredFields(jsonMap);
        
        // Parse heart rate data
        final heartRateData = HeartRateData.fromJson(jsonMap);
        
        _logger.d(
          'Received heart rate from watch: ${heartRateData.bpm} bpm, '
          'status: ${heartRateData.status.name}, '
          'ibiCount: ${heartRateData.ibiValues.length}'
        );
        
        return heartRateData;
      } on SensorError catch (e) {
        // Re-throw SensorError as-is
        throw e;
      } catch (e, stackTrace) {
        _logger.e('Failed to parse heart rate data from watch', 
          error: e, stackTrace: stackTrace);
        throw SensorError(
          code: SensorErrorCode.unknown,
          message: 'Failed to decode heart rate data from watch',
          details: 'JSON parsing error: ${e.toString()}',
        );
      }
    }).handleError((error, stackTrace) {
      _logger.e('Error in heart rate stream from watch', 
        error: error, stackTrace: stackTrace);
      
      // Convert platform exceptions to SensorError
      if (error is PlatformException) {
        throw SensorError(
          code: SensorErrorCode.unknown,
          message: 'Platform error in heart rate stream',
          details: '${error.code}: ${error.message}',
        );
      }
      
      // Re-throw if already a SensorError
      if (error is SensorError) {
        throw error;
      }
      
      // Wrap other errors
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Unexpected error in heart rate stream',
        details: error.toString(),
      );
    });

    return _heartRateStream!;
  }

  /// Validate that all required fields are present in the JSON data
  /// 
  /// According to Requirements 9.4, the JSON must contain:
  /// - bpm (can be null)
  /// - ibiValues (array)
  /// - timestamp (integer)
  /// - status (string)
  void _validateRequiredFields(Map<String, dynamic> json) {
    final requiredFields = ['timestamp', 'status'];
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (!json.containsKey(field)) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      final message = 'Missing required fields: ${missingFields.join(", ")}';
      _logger.e('JSON validation failed: $message');
      _logger.d('Received JSON: $json');
      
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Malformed JSON from watch',
        details: message,
      );
    }

    // Validate field types
    if (json['timestamp'] is! int) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid timestamp field type',
        details: 'Expected int but got ${json['timestamp'].runtimeType}',
      );
    }

    if (json['status'] is! String) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid status field type',
        details: 'Expected String but got ${json['status'].runtimeType}',
      );
    }

    // Validate optional fields if present
    if (json.containsKey('bpm') && json['bpm'] != null && json['bpm'] is! int) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid bpm field type',
        details: 'Expected int or null but got ${json['bpm'].runtimeType}',
      );
    }

    if (json.containsKey('ibiValues') && json['ibiValues'] != null && json['ibiValues'] is! List) {
      throw SensorError(
        code: SensorErrorCode.unknown,
        message: 'Invalid ibiValues field type',
        details: 'Expected List but got ${json['ibiValues'].runtimeType}',
      );
    }
  }

  /// Start listening for data from watch
  Future<bool> startListening() async {
    try {
      _logger.i('Starting to listen for watch data');
      final result = await _methodChannel.invokeMethod<bool>('startListening');
      _logger.i('Listening started: ${result ?? false}');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('Failed to start listening', error: e);
      return false;
    }
  }

  /// Stop listening for data from watch
  Future<void> stopListening() async {
    try {
      _logger.i('Stopping listening for watch data');
      await _methodChannel.invokeMethod<void>('stopListening');
    } on PlatformException catch (e) {
      _logger.e('Failed to stop listening', error: e);
    }
  }

  /// Check if watch is connected
  Future<bool> isWatchConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isWatchConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      _logger.e('Failed to check watch connection', error: e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _heartRateController?.close();
    _heartRateController = null;
    _heartRateStream = null;
  }
}
