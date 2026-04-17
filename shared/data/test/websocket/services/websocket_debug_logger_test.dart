import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/services/websocket_debug_logger.dart';
import 'package:data/websocket/models/websocket_debug_event.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';

void main() {
  group('WebSocketDebugLogger', () {
    late WebSocketDebugLogger debugLogger;
    late WebSocketDebugConfig config;

    setUp(() {
      config = const WebSocketDebugConfig(
        enableLogging: true,
        enableEventTracking: true,
        enablePerformanceMonitoring: true,
        enableErrorAnalytics: true,
        maxEventsInMemory: 100,
        logLevel: WebSocketDebugLogLevel.debug,
        enableConsoleOutput: false, // Disable console output for tests
      );
      debugLogger = WebSocketDebugLogger(config);
    });

    tearDown(() {
      debugLogger.dispose();
    });

    group('Initialization', () {
      test('should initialize with debug session', () {
        expect(debugLogger.currentSession, isNotNull);
        expect(debugLogger.currentSession!.sessionId, isNotEmpty);
        expect(debugLogger.events, isEmpty);
      });

      test('should provide event stream', () {
        expect(debugLogger.eventStream, isA<Stream<WebSocketDebugEvent>>());
      });
    });

    group('Connection Logging', () {
      test('should log connection attempt', () {
        const url = 'ws://test.com';
        final metadata = {'timeout': 5000};

        debugLogger.logConnectionAttempt(url, metadata: metadata);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.connectionAttempt));
        expect(event.message, contains(url));
        expect(event.data!['url'], equals(url));
        expect(event.data!['timeout'], equals(5000));
      });

      test('should log connection success', () {
        const url = 'ws://test.com';
        const connectionTime = Duration(milliseconds: 500);

        debugLogger.logConnectionSuccess(url, connectionTime: connectionTime);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.connectionSuccess));
        expect(event.message, contains(url));
        expect(event.data!['connectionTimeMs'], equals(500));
        expect(event.duration, equals(connectionTime));
      });

      test('should log connection failure', () {
        const url = 'ws://test.com';
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Connection failed',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        debugLogger.logConnectionFailure(url, error, attemptNumber: 2);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.connectionFailure));
        expect(event.message, contains(url));
        expect(event.data!['errorType'], equals('networkError'));
        expect(event.attemptNumber, equals(2));
        expect(event.error, equals(error));
      });

      test('should log disconnection', () {
        const reason = 'Server shutdown';

        debugLogger.logDisconnection(reason, wasExpected: true);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.disconnection));
        expect(event.message, contains(reason));
        expect(event.data!['wasExpected'], isTrue);
      });
    });

    group('Message Logging', () {
      test('should log message sent', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        const messageId = 'msg_123';

        debugLogger.logMessageSent(channel, message, messageId: messageId);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.messageSent));
        expect(event.channel, equals(channel));
        expect(event.data!['messageId'], equals(messageId));
        expect(event.data!['messageSize'], greaterThan(0));
      });

      test('should log message received', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        const processingTime = Duration(milliseconds: 25);

        debugLogger.logMessageReceived(channel, message, processingTime: processingTime);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.messageReceived));
        expect(event.channel, equals(channel));
        expect(event.data!['processingTimeMs'], equals(25));
        expect(event.duration, equals(processingTime));
      });

      test('should include message content in verbose mode', () {
        final verboseConfig = config.copyWith(logLevel: WebSocketDebugLogLevel.verbose);
        debugLogger.dispose();
        debugLogger = WebSocketDebugLogger(verboseConfig);

        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        debugLogger.logMessageSent(channel, message);

        final event = debugLogger.events.first;
        expect(event.data!['message'], equals(message));
      });

      test('should not include message content in non-verbose mode', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        debugLogger.logMessageSent(channel, message);

        final event = debugLogger.events.first;
        expect(event.data!.containsKey('message'), isFalse);
      });
    });

    group('Subscription Logging', () {
      test('should log subscription', () {
        const channel = 'test_channel';

        debugLogger.logSubscription(channel);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.subscriptionAdded));
        expect(event.channel, equals(channel));
        expect(event.data!['isResubscription'], isFalse);
      });

      test('should log resubscription', () {
        const channel = 'test_channel';

        debugLogger.logSubscription(channel, isResubscription: true);

        final event = debugLogger.events.first;
        expect(event.data!['isResubscription'], isTrue);
        expect(event.message, contains('Resubscribed'));
      });

      test('should log unsubscription', () {
        const channel = 'test_channel';

        debugLogger.logUnsubscription(channel);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.subscriptionRemoved));
        expect(event.channel, equals(channel));
      });
    });

    group('State Change Logging', () {
      test('should log state changes', () {
        const oldState = WebSocketConnectionState.connecting;
        const newState = WebSocketConnectionState.connected;

        debugLogger.logStateChange(oldState, newState);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.stateChange));
        expect(event.connectionState, equals(newState));
        expect(event.data!['oldState'], equals('connecting'));
        expect(event.data!['newState'], equals('connected'));
      });
    });

    group('Error Logging', () {
      test('should log errors', () {
        final error = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Invalid token',
          timestamp: DateTime.now(),
          isRecoverable: true,
          attemptNumber: 1,
        );
        const context = 'token_validation';

        debugLogger.logError(error, context: context);

        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.error));
        expect(event.error, equals(error));
        expect(event.data!['context'], equals(context));
        expect(event.data!['errorType'], equals('authenticationFailed'));
        expect(event.data!['isRecoverable'], isTrue);
      });
    });

    group('Authentication Logging', () {
      test('should log successful authentication', () {
        const event = 'token_validation';

        debugLogger.logAuthentication(event, success: true);

        final logEvent = debugLogger.events.first;
        expect(logEvent.type, equals(WebSocketDebugEventType.authentication));
        expect(logEvent.data!['success'], isTrue);
        expect(logEvent.message, contains('successful'));
      });

      test('should log failed authentication', () {
        const event = 'token_validation';
        const error = 'Invalid token format';

        debugLogger.logAuthentication(event, success: false, error: error);

        final logEvent = debugLogger.events.first;
        expect(logEvent.type, equals(WebSocketDebugEventType.authentication));
        expect(logEvent.data!['success'], isFalse);
        expect(logEvent.data!['error'], equals(error));
        expect(logEvent.message, contains('failed'));
      });
    });

    group('Event Filtering', () {
      test('should filter events by type', () {
        debugLogger.logConnectionAttempt('ws://test.com');
        debugLogger.logConnectionSuccess('ws://test.com');
        debugLogger.logSubscription('test_channel');

        final connectionEvents = debugLogger.getEventsByType(WebSocketDebugEventType.connectionAttempt);
        expect(connectionEvents.length, equals(1));
        expect(connectionEvents.first.type, equals(WebSocketDebugEventType.connectionAttempt));
      });

      test('should filter events by time range', () async {
        final start = DateTime.now();
        
        debugLogger.logConnectionAttempt('ws://test.com');
        
        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 10));
        
        final end = DateTime.now();
        debugLogger.logConnectionSuccess('ws://test.com');
        
        final eventsInRange = debugLogger.getEventsInTimeRange(start, end);
        expect(eventsInRange.length, equals(1));
      });

      test('should get error events only', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        debugLogger.logConnectionAttempt('ws://test.com');
        debugLogger.logError(error);
        debugLogger.logSubscription('test_channel');

        final errorEvents = debugLogger.getErrorEvents();
        expect(errorEvents.length, equals(1));
        expect(errorEvents.first.error, equals(error));
      });
    });

    group('Event Limits', () {
      test('should respect max events in memory limit', () {
        final smallConfig = config.copyWith(maxEventsInMemory: 5);
        debugLogger.dispose();
        debugLogger = WebSocketDebugLogger(smallConfig);

        // Add more events than the limit
        for (int i = 0; i < 10; i++) {
          debugLogger.logConnectionAttempt('ws://test$i.com');
        }

        expect(debugLogger.events.length, equals(5));
        // Should keep the most recent events
        expect(debugLogger.events.last.data!['url'], equals('ws://test9.com'));
      });
    });

    group('Session Management', () {
      test('should end session', () {
        expect(debugLogger.currentSession!.endTime, isNull);

        debugLogger.endSession();

        expect(debugLogger.currentSession!.endTime, isNotNull);
      });

      test('should export session data', () {
        debugLogger.logConnectionAttempt('ws://test.com');
        
        final exportData = debugLogger.exportSession();

        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData['session'], isNotNull);
        expect(exportData['events'], isA<List>());
        expect(exportData['exportedAt'], isA<String>());
      });
    });

    group('Event Clearing', () {
      test('should clear all events', () {
        debugLogger.logConnectionAttempt('ws://test.com');
        debugLogger.logSubscription('test_channel');

        expect(debugLogger.events.length, equals(2));

        debugLogger.clearEvents();

        expect(debugLogger.events.length, equals(0));
      });
    });

    group('Configuration Updates', () {
      test('should update configuration', () {
        final newConfig = config.copyWith(
          logLevel: WebSocketDebugLogLevel.error,
          maxEventsInMemory: 200,
        );

        debugLogger.updateConfig(newConfig);

        // Should log the configuration change
        expect(debugLogger.events.length, equals(1));
        final event = debugLogger.events.first;
        expect(event.type, equals(WebSocketDebugEventType.configurationChange));
        expect(event.data!['setting'], equals('debugConfig'));
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        expect(() => debugLogger.dispose(), returnsNormally);
      });

      test('should end session on disposal', () {
        expect(debugLogger.currentSession!.endTime, isNull);

        debugLogger.dispose();

        expect(debugLogger.currentSession!.endTime, isNotNull);
      });
    });
  });
}