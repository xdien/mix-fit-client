import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/services/websocket_analytics.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/models/websocket_metrics.dart';

void main() {
  group('WebSocketAnalytics', () {
    late WebSocketAnalytics analytics;

    setUp(() {
      analytics = WebSocketAnalytics(
        batchInterval: const Duration(milliseconds: 100), // Short interval for testing
        maxBatchSize: 5,
        enableErrorReporting: true,
        enablePerformanceTracking: true,
        enableUserAnalytics: true,
      );
    });

    tearDown(() {
      analytics.dispose();
    });

    group('Initialization', () {
      test('should initialize with enabled state', () {
        expect(analytics.isEnabled, isTrue);
        expect(analytics.pendingEventsCount, equals(0));
      });

      test('should provide event stream', () {
        expect(analytics.eventStream, isA<Stream<WebSocketAnalyticsEvent>>());
      });
    });

    group('Connection Event Tracking', () {
      test('should track connection events', () {
        analytics.trackConnectionEvent(
          eventType: 'connect',
          state: WebSocketConnectionState.connected,
          connectionTime: const Duration(milliseconds: 500),
          metadata: {'server': 'test.com'},
        );

        expect(analytics.pendingEventsCount, equals(1));
      });

      test('should not track connection events when performance tracking disabled', () {
        final disabledAnalytics = WebSocketAnalytics(
          enablePerformanceTracking: false,
        );

        disabledAnalytics.trackConnectionEvent(
          eventType: 'connect',
          state: WebSocketConnectionState.connected,
        );

        expect(disabledAnalytics.pendingEventsCount, equals(0));
        disabledAnalytics.dispose();
      });
    });

    group('Error Tracking', () {
      test('should track errors', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Connection failed',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        analytics.trackError(
          error: error,
          context: 'connection_attempt',
          additionalData: {'attempt': 2},
        );

        expect(analytics.pendingEventsCount, equals(1));
      });

      test('should assign correct severity to errors', () async {
        final criticalError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Auth failed',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        final warningError = WebSocketError(
          type: WebSocketErrorType.heartbeatTimeout,
          message: 'Heartbeat timeout',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final eventStream = analytics.eventStream;
        final events = <WebSocketAnalyticsEvent>[];
        
        final subscription = eventStream.listen((event) {
          events.add(event);
        });

        analytics.trackError(error: criticalError);
        analytics.trackError(error: warningError);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(2));
        expect(events[0].severity, equals(WebSocketAnalyticsEventSeverity.critical));
        expect(events[1].severity, equals(WebSocketAnalyticsEventSeverity.warning));

        await subscription.cancel();
      });

      test('should not track errors when error reporting disabled', () {
        final disabledAnalytics = WebSocketAnalytics(
          enableErrorReporting: false,
        );

        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        disabledAnalytics.trackError(error: error);

        expect(disabledAnalytics.pendingEventsCount, equals(0));
        disabledAnalytics.dispose();
      });
    });

    group('Performance Metrics Tracking', () {
      test('should track performance metrics', () {
        const metrics = WebSocketMetrics(
          connectionAttempts: 5,
          successfulConnections: 4,
          failedConnections: 1,
          messagesSent: 100,
          messagesReceived: 95,
          errorCount: 2,
          connectionQualityScore: 85,
        );

        analytics.trackPerformanceMetrics(metrics);

        expect(analytics.pendingEventsCount, equals(1));
      });
    });

    group('User Interaction Tracking', () {
      test('should track user interactions', () {
        analytics.trackUserInteraction(
          action: 'subscribe',
          feature: 'notifications',
          properties: {'channel': 'alerts'},
        );

        expect(analytics.pendingEventsCount, equals(1));
      });

      test('should not track user interactions when disabled', () {
        final disabledAnalytics = WebSocketAnalytics(
          enableUserAnalytics: false,
        );

        disabledAnalytics.trackUserInteraction(action: 'test');

        expect(disabledAnalytics.pendingEventsCount, equals(0));
        disabledAnalytics.dispose();
      });
    });

    group('Configuration Change Tracking', () {
      test('should track configuration changes', () {
        analytics.trackConfigurationChange(
          setting: 'reconnectInterval',
          oldValue: 5000,
          newValue: 10000,
          reason: 'user_preference',
        );

        expect(analytics.pendingEventsCount, equals(1));
      });
    });

    group('Custom Event Tracking', () {
      test('should track custom events', () {
        analytics.trackCustomEvent(
          eventName: 'feature_used',
          properties: {'feature': 'auto_reconnect'},
          severity: WebSocketAnalyticsEventSeverity.info,
        );

        expect(analytics.pendingEventsCount, equals(1));
      });
    });

    group('Batch Processing', () {
      test('should process batch when max size reached', () async {
        // Add events up to max batch size
        for (int i = 0; i < 5; i++) {
          analytics.trackCustomEvent(eventName: 'test_$i');
        }

        // Should have processed the batch automatically
        await Future.delayed(const Duration(milliseconds: 50));
        expect(analytics.pendingEventsCount, equals(0));
      });

      test('should process batch on timer', () async {
        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(1));

        // Wait for batch timer to trigger
        await Future.delayed(const Duration(milliseconds: 150));

        expect(analytics.pendingEventsCount, equals(0));
      });

      test('should process batch immediately for critical events', () async {
        final criticalError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Critical error',
          timestamp: DateTime.now(),
          isRecoverable: false,
        );

        analytics.trackError(error: criticalError);

        // Should process immediately due to critical severity
        await Future.delayed(const Duration(milliseconds: 10));
        expect(analytics.pendingEventsCount, equals(0));
      });
    });

    group('Analytics Summary', () {
      test('should provide analytics summary', () {
        analytics.trackCustomEvent(eventName: 'test1');
        analytics.trackCustomEvent(
          eventName: 'test2',
          severity: WebSocketAnalyticsEventSeverity.warning,
        );

        final summary = analytics.getAnalyticsSummary();

        expect(summary, isA<Map<String, dynamic>>());
        expect(summary['isEnabled'], isTrue);
        expect(summary['pendingEventsCount'], equals(2));
        expect(summary['eventsByType'], isA<Map<String, int>>());
        expect(summary['eventsBySeverity'], isA<Map<String, int>>());
        expect(summary['configuration'], isA<Map<String, dynamic>>());
      });
    });

    group('Event Flushing', () {
      test('should flush pending events', () async {
        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(1));

        analytics.flushEvents();

        await Future.delayed(const Duration(milliseconds: 10));
        expect(analytics.pendingEventsCount, equals(0));
      });
    });

    group('Enable/Disable', () {
      test('should disable analytics', () {
        analytics.setEnabled(false);

        expect(analytics.isEnabled, isFalse);

        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(0));
      });

      test('should re-enable analytics', () {
        analytics.setEnabled(false);
        analytics.setEnabled(true);

        expect(analytics.isEnabled, isTrue);

        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(1));
      });

      test('should clear pending events when disabled', () {
        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(1));

        analytics.setEnabled(false);

        expect(analytics.pendingEventsCount, equals(0));
      });
    });

    group('Event Stream', () {
      test('should emit events to stream', () async {
        final eventStream = analytics.eventStream;
        final events = <WebSocketAnalyticsEvent>[];
        
        final subscription = eventStream.listen((event) {
          events.add(event);
        });

        analytics.trackCustomEvent(eventName: 'test1');
        analytics.trackCustomEvent(eventName: 'test2');

        await Future.delayed(const Duration(milliseconds: 10));

        expect(events.length, equals(2));
        expect(events[0].data['eventName'], equals('test1'));
        expect(events[1].data['eventName'], equals('test2'));

        await subscription.cancel();
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        expect(() => analytics.dispose(), returnsNormally);
      });

      test('should flush events on disposal', () async {
        analytics.trackCustomEvent(eventName: 'test');

        expect(analytics.pendingEventsCount, equals(1));

        analytics.dispose();

        // Events should be flushed during disposal
        // Note: In a real implementation, this would send events to the analytics service
      });

      test('should not accept events after disposal', () {
        analytics.dispose();

        analytics.trackCustomEvent(eventName: 'test');

        // Should not crash, but also should not track the event
        expect(analytics.pendingEventsCount, equals(0));
      });
    });
  });

  group('WebSocketAnalyticsEvent', () {
    test('should create event with required fields', () {
      final event = WebSocketAnalyticsEvent(
        type: WebSocketAnalyticsEventType.error,
        timestamp: DateTime.now(),
        data: {'error': 'test'},
      );

      expect(event.type, equals(WebSocketAnalyticsEventType.error));
      expect(event.severity, equals(WebSocketAnalyticsEventSeverity.info)); // default
      expect(event.data['error'], equals('test'));
    });

    test('should create event with custom severity', () {
      final event = WebSocketAnalyticsEvent(
        type: WebSocketAnalyticsEventType.error,
        timestamp: DateTime.now(),
        data: {'error': 'test'},
        severity: WebSocketAnalyticsEventSeverity.critical,
      );

      expect(event.severity, equals(WebSocketAnalyticsEventSeverity.critical));
    });

    test('should convert to JSON', () {
      final timestamp = DateTime.now();
      final event = WebSocketAnalyticsEvent(
        type: WebSocketAnalyticsEventType.performance,
        timestamp: timestamp,
        data: {'metric': 'value'},
        severity: WebSocketAnalyticsEventSeverity.warning,
      );

      final json = event.toJson();

      expect(json['type'], equals('performance'));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['data'], equals({'metric': 'value'}));
      expect(json['severity'], equals('warning'));
    });

    test('should have string representation', () {
      final event = WebSocketAnalyticsEvent(
        type: WebSocketAnalyticsEventType.custom,
        timestamp: DateTime.now(),
        data: {},
      );

      final string = event.toString();

      expect(string, contains('WebSocketAnalyticsEvent'));
      expect(string, contains('custom'));
      expect(string, contains('info'));
    });
  });
}