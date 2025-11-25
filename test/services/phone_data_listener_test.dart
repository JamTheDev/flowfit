import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/models/sensor_error.dart';
import 'package:flowfit/models/sensor_error_code.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneDataListener', () {
    late PhoneDataListener service;
    const methodChannel = MethodChannel('com.flowfit.phone/data');
    const eventChannel = EventChannel('com.flowfit.phone/heartrate');

    setUp(() {
      service = PhoneDataListener();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
      service.dispose();
    });

    group('heartRateStream', () {
      test('emits HeartRateData when valid data is received from watch', () async {
        final testData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [850, 845, 855],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(testData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        final heartRateData = await stream.first;

        expect(heartRateData.bpm, 72);
        expect(heartRateData.status.name, 'active');
        expect(heartRateData.ibiValues.length, 3);
      });

      test('emits multiple HeartRateData events from watch', () async {
        final testData1 = {
          'bpm': 70,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };
        final testData2 = {
          'bpm': 75,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(testData1);
              events.success(testData2);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        final heartRateList = await stream.take(2).toList();

        expect(heartRateList.length, 2);
        expect(heartRateList[0].bpm, 70);
        expect(heartRateList[1].bpm, 75);
      });

      test('throws SensorError when null event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(null);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Received null data from watch',
          )),
        );
      });

      test('throws SensorError when non-Map event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success('invalid string data');
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Invalid data format from watch',
          )),
        );
      });

      test('throws SensorError when required field "timestamp" is missing', () async {
        final invalidData = {
          'bpm': 72,
          'status': 'active',
          // Missing 'timestamp'
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Malformed JSON from watch',
          )),
        );
      });

      test('throws SensorError when required field "status" is missing', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          // Missing 'status'
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Malformed JSON from watch',
          )),
        );
      });

      test('throws SensorError when timestamp has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': 'not an integer',
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Invalid timestamp field type',
          )),
        );
      });

      test('throws SensorError when status has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 123, // Should be string
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Invalid status field type',
          )),
        );
      });

      test('throws SensorError when bpm has invalid type', () async {
        final invalidData = {
          'bpm': 'seventy-two', // Should be int or null
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Invalid bpm field type',
          )),
        );
      });

      test('throws SensorError when ibiValues has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': 'not a list',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>().having(
            (e) => e.message,
            'message',
            'Invalid ibiValues field type',
          )),
        );
      });

      test('accepts null bpm value', () async {
        final testData = {
          'bpm': null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(testData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        final heartRateData = await stream.first;

        expect(heartRateData.bpm, isNull);
        expect(heartRateData.status.name, 'active');
      });

      test('handles error in JSON parsing', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': 'invalid',
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(invalidData);
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        
        expect(
          () => stream.first,
          throwsA(isA<SensorError>()),
        );
      });

      test('handles stream cancellation', () async {
        var cancelCalled = false;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              return null;
            },
            onCancel: (arguments) {
              cancelCalled = true;
              return null;
            },
          ),
        );

        final stream = service.heartRateStream;
        final subscription = stream.listen((_) {});
        await subscription.cancel();

        expect(cancelCalled, true);
      });
    });

    group('startListening', () {
      test('returns true when listening starts successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'startListening') {
            return true;
          }
          return null;
        });

        final result = await service.startListening();
        expect(result, true);
      });

      test('returns false when listening fails to start', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'startListening') {
            return false;
          }
          return null;
        });

        final result = await service.startListening();
        expect(result, false);
      });

      test('returns false on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'startListening') {
            throw PlatformException(
              code: 'ERROR',
              message: 'Failed to start',
            );
          }
          return null;
        });

        final result = await service.startListening();
        expect(result, false);
      });
    });

    group('stopListening', () {
      test('completes successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'stopListening') {
            return null;
          }
          return null;
        });

        await expectLater(service.stopListening(), completes);
      });

      test('handles PlatformException gracefully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'stopListening') {
            throw PlatformException(
              code: 'ERROR',
              message: 'Failed to stop',
            );
          }
          return null;
        });

        // Should not throw, just log the error
        await expectLater(service.stopListening(), completes);
      });
    });

    group('isWatchConnected', () {
      test('returns true when watch is connected', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'isWatchConnected') {
            return true;
          }
          return null;
        });

        final result = await service.isWatchConnected();
        expect(result, true);
      });

      test('returns false when watch is not connected', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'isWatchConnected') {
            return false;
          }
          return null;
        });

        final result = await service.isWatchConnected();
        expect(result, false);
      });

      test('returns false on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'isWatchConnected') {
            throw PlatformException(
              code: 'ERROR',
              message: 'Failed to check',
            );
          }
          return null;
        });

        final result = await service.isWatchConnected();
        expect(result, false);
      });
    });

    group('dispose', () {
      test('disposes resources without error', () {
        final testService = PhoneDataListener();
        expect(() => testService.dispose(), returnsNormally);
      });
    });
  });
}
