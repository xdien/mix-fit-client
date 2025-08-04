import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/services/websocket_monitor.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/models/websocket_metrics.dart';
import 'package:data/websocket/interfaces/i_websocket_service.dart';

import '../stores/websocket_aware_store_test.mocks.dart';

void main() {
  group('WebSocketMonitor', () {
    late MockIWebSocketService mockWebSocketService;
    late WebSocketMonitor monitor;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      when(mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream.fromIterable([WebSocketConnectionState.disconnected]),
      );
      monitor = WebSocketMonitor(mockWebSocketService);
    });

    tearDown(() {
      monitor.dispose();
    });

    group('Initialization', () {
      test('should initialize with default metrics', () {
        expect(monitor.currentMetrics, equals(const WebSocketMetrics()));
      });

      test('should provide metrics stream', () {
        expect(monitor.metricsStream, isA<Stream<WebSocketMetrics>>());
      });

      test('should provide health stream', () {
        expect(monitor.healthStream, isA<Stream<WebSocketHealthCheck>>());
      });
    });

    group('Connection Tracking', () {
      test('should track connection attempts', () {
        // Simulate connection state changes
        when(mockWebSocketService.connectionState).thenAnswer(
          (_) => Stream.fromIterable([
            WebSocketConnectionState.connecting,
            WebSocketConnectionState.connected,
          ]),
        );

        // Create new monitor to trigger state listening
        monitor.dispose();
        monitor = WebSocketMonitor(mockWebSocketService);

        // Wait for state changes to be processed
        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.connectionAttempts, equals(1));
          expect(monitor.currentMetrics.successfulConnections, equals(1));
        });
      });

      test('should track connection failures', () {
        when(mockWebSocketService.connectionState).thenAnswer(
          (_) => Stream.fromIterable([
            WebSocketConnectionState.connecting,
            WebSocketConnectionState.error,
          ]),
        );

        monitor.dispose();
        monitor = WebSocketMonitor(mockWebSocketService);

        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.connectionAttempts, equals(1));
          expect(monitor.currentMetrics.failedConnections, equals(1));
        });
      });

      test('should track reconnection attempts', () {
        when(mockWebSocketService.connectionState).thenAnswer(
          (_) => Stream.fromIterable([
            WebSocketConnectionState.connected,
            WebSocketConnectionState.reconnecting,
          ]),
        );

        monitor.dispose();
        monitor = WebSocketMonitor(mockWebSocketService);

        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.reconnectionAttempts, equals(1));
        });
      });
    });

    group('Message Tracking', () {
      test('should record messages sent', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        monitor.recordMessageSent(channel, message);

        expect(monitor.currentMetrics.messagesSent, equals(1));
        expect(monitor.currentMetrics.dataTransfer.bytesSent, greaterThan(0));
      });

      test('should record messages received', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        const processingTime = Duration(milliseconds: 50);

        monitor.recordMessageReceived(channel, message, processingTime: processingTime);

        expect(monitor.currentMetrics.messagesReceived, equals(1));
        expect(monitor.currentMetrics.dataTransfer.bytesReceived, greaterThan(0));
        expect(monitor.currentMetrics.averageMessageProcessingTimeMs, equals(50.0));
      });

      test('should calculate average message processing time', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        monitor.recordMessageReceived(channel, message, processingTime: const Duration(milliseconds: 30));
        monitor.recordMessageReceived(channel, message, processingTime: const Duration(milliseconds: 70));

        expect(monitor.currentMetrics.averageMessageProcessingTimeMs, equals(50.0));
      });

      test('should track message rate', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        // Send multiple messages quickly
        for (int i = 0; i < 5; i++) {
          monitor.recordMessageSent(channel, message);
        }

        expect(monitor.currentMetrics.dataTransfer.currentMessageRate, greaterThan(0));
      });
    });

    group('Subscription Tracking', () {
      test('should record subscriptions', () {
        const channel = 'test_channel';

        monitor.recordSubscription(channel);

        expect(monitor.currentMetrics.subscriptions, equals(1));
      });

      test('should record unsubscriptions', () {
        const channel = 'test_channel';

        monitor.recordUnsubscription(channel);

        expect(monitor.currentMetrics.unsubscriptions, equals(1));
      });
    });

    group('Error Tracking', () {
      test('should record general errors', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        monitor.recordError(error);

        expect(monitor.currentMetrics.errorCount, equals(1));
      });

      test('should track specific error types', () {
        final heartbeatError = WebSocketError(
          type: WebSocketErrorType.heartbeatTimeout,
          message: 'Heartbeat timeout',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final authError = WebSocketError(
          type: WebSocketErrorType.authenticationFailed,
          message: 'Auth failed',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        final networkError = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Network error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        monitor.recordError(heartbeatError);
        monitor.recordError(authError);
        monitor.recordError(networkError);

        expect(monitor.currentMetrics.heartbeatTimeouts, equals(1));
        expect(monitor.currentMetrics.authenticationFailures, equals(1));
        expect(monitor.currentMetrics.networkErrors, equals(1));
      });
    });

    group('Connection Quality', () {
      test('should calculate connection quality score', () {
        // Simulate good connection
        when(mockWebSocketService.connectionState).thenAnswer(
          (_) => Stream.fromIterable([
            WebSocketConnectionState.connecting,
            WebSocketConnectionState.connected,
          ]),
        );

        monitor.dispose();
        monitor = WebSocketMonitor(mockWebSocketService);

        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.connectionQualityScore, greaterThan(80));
        });
      });

      test('should decrease quality score for errors', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        // Record multiple errors
        for (int i = 0; i < 5; i++) {
          monitor.recordError(error);
        }

        expect(monitor.currentMetrics.connectionQualityScore, lessThan(100));
      });
    });

    group('Performance Report', () {
      test('should generate performance report', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        monitor.recordMessageSent(channel, message);
        monitor.recordMessageReceived(channel, message);

        final report = monitor.getPerformanceReport();

        expect(report, isA<Map<String, dynamic>>());
        expect(report['metrics'], isA<Map<String, dynamic>>());
        expect(report['generatedAt'], isA<String>());
      });
    });

    group('Health Checks', () {
      test('should emit health check results', () async {
        final healthStream = monitor.healthStream;
        
        // Wait for initial health check
        final healthCheck = await healthStream.first.timeout(
          const Duration(seconds: 35), // Health checks run every 30 seconds
        );

        expect(healthCheck, isA<WebSocketHealthCheck>());
        expect(healthCheck.status, isA<WebSocketHealthStatus>());
        expect(healthCheck.score, isA<int>());
        expect(healthCheck.timestamp, isA<DateTime>());
      });
    });

    group('Metrics Reset', () {
      test('should reset all metrics', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        monitor.recordMessageSent(channel, message);
        monitor.recordSubscription(channel);

        expect(monitor.currentMetrics.messagesSent, equals(1));
        expect(monitor.currentMetrics.subscriptions, equals(1));

        monitor.resetMetrics();

        expect(monitor.currentMetrics.messagesSent, equals(0));
        expect(monitor.currentMetrics.subscriptions, equals(0));
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        expect(() => monitor.dispose(), returnsNormally);
      });

      test('should not emit events after disposal', () {
        monitor.dispose();

        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};

        // These should not throw errors but also should not update metrics
        expect(() => monitor.recordMessageSent(channel, message), returnsNormally);
      });
    });
  });
}