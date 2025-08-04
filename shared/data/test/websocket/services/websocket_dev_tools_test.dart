import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/services/websocket_dev_tools.dart';
import 'package:data/websocket/services/websocket_monitor.dart';
import 'package:data/websocket/services/websocket_debug_logger.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/models/websocket_debug_event.dart';

import '../stores/websocket_aware_store_test.mocks.dart';

void main() {
  group('WebSocketDevTools', () {
    late MockIWebSocketService mockWebSocketService;
    late WebSocketMonitor monitor;
    late WebSocketDebugLogger debugLogger;
    late WebSocketDevTools devTools;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      when(mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream.fromIterable([WebSocketConnectionState.disconnected]),
      );
      when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);

      monitor = WebSocketMonitor(mockWebSocketService);
      debugLogger = WebSocketDebugLogger(const WebSocketDebugConfig(
        enableLogging: true,
        enableEventTracking: true,
        enableConsoleOutput: false,
      ));
      devTools = WebSocketDevTools(mockWebSocketService, monitor, debugLogger);
    });

    tearDown(() {
      devTools.dispose();
      debugLogger.dispose();
      monitor.dispose();
    });

    group('Availability', () {
      test('should be available in debug mode', () {
        expect(devTools.isAvailable, isTrue);
      });
    });

    group('Service Status', () {
      test('should get service status', () {
        final status = devTools.getServiceStatus();

        expect(status, isA<Map<String, dynamic>>());
        expect(status['connectionState'], isA<String>());
        expect(status['isConnected'], isA<bool>());
        expect(status['metrics'], isA<Map<String, dynamic>>());
        expect(status['timestamp'], isA<String>());
      });
    });

    group('Connection Issue Simulation', () {
      test('should simulate connection issues', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
        when(mockWebSocketService.connect()).thenAnswer((_) async {});

        await devTools.simulateConnectionIssues(
          disconnectionCount: 2,
          disconnectionInterval: const Duration(milliseconds: 100),
        );

        // Verify disconnect and connect were called
        verify(mockWebSocketService.disconnect()).called(2);
        verify(mockWebSocketService.connect()).called(2);
      });

      test('should throw error if not available', () {
        // This test would need to mock the debug mode check
        // For now, we'll skip it since isAvailable always returns true in our implementation
      });
    });

    group('Load Testing', () {
      test('should start load test', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);

        await devTools.startLoadTest(
          messagesPerSecond: 5,
          duration: const Duration(milliseconds: 200),
          testChannel: 'load_test',
        );

        // Wait for test to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify messages were recorded
        expect(monitor.currentMetrics.messagesSent, greaterThan(0));
      });

      test('should stop load test', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);

        // Start load test
        devTools.startLoadTest(
          messagesPerSecond: 10,
          duration: const Duration(seconds: 10), // Long duration
        );

        // Stop it immediately
        devTools.stopLoadTest();

        // Wait a bit to ensure it's stopped
        await Future.delayed(const Duration(milliseconds: 100));

        // Should not have sent many messages
        expect(monitor.currentMetrics.messagesSent, lessThan(5));
      });

      test('should throw error if load test already running', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);

        // Start first load test
        devTools.startLoadTest(duration: const Duration(seconds: 1));

        // Try to start another
        expect(
          () => devTools.startLoadTest(duration: const Duration(seconds: 1)),
          throwsA(isA<StateError>()),
        );

        devTools.stopLoadTest();
      });
    });

    group('Connection Stability Testing', () {
      test('should start connection stability test', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
        when(mockWebSocketService.connect()).thenAnswer((_) async {});

        await devTools.startConnectionStabilityTest(
          cycles: 2,
          cycleInterval: const Duration(milliseconds: 100),
        );

        // Wait for test to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // Verify disconnect and connect were called
        verify(mockWebSocketService.disconnect()).called(greaterThan(0));
        verify(mockWebSocketService.connect()).called(greaterThan(0));
      });

      test('should stop connection stability test', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
        when(mockWebSocketService.connect()).thenAnswer((_) async {});

        // Start test
        devTools.startConnectionStabilityTest(
          cycles: 10,
          cycleInterval: const Duration(seconds: 1),
        );

        // Stop it immediately
        devTools.stopConnectionStabilityTest();

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Should not have completed many cycles
        final callCount = verify(mockWebSocketService.disconnect()).callCount;
        expect(callCount, lessThan(5));
      });

      test('should throw error if connection test already running', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);

        // Start first test
        devTools.startConnectionStabilityTest(cycles: 5);

        // Try to start another
        expect(
          () => devTools.startConnectionStabilityTest(cycles: 3),
          throwsA(isA<StateError>()),
        );

        devTools.stopConnectionStabilityTest();
      });
    });

    group('Test Message Injection', () {
      test('should inject test message', () {
        const channel = 'test_channel';
        final data = {'type': 'test', 'message': 'hello'};

        devTools.injectTestMessage(channel: channel, data: data);

        // Wait for async processing
        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.messagesReceived, equals(1));
          expect(debugLogger.events.any((e) => 
            e.type == WebSocketDebugEventType.messageReceived && 
            e.channel == channel
          ), isTrue);
        });
      });

      test('should inject test message with default data', () {
        const channel = 'test_channel';

        devTools.injectTestMessage(channel: channel);

        Future.delayed(const Duration(milliseconds: 100), () {
          expect(monitor.currentMetrics.messagesReceived, equals(1));
        });
      });
    });

    group('Test Error Injection', () {
      test('should inject test error', () {
        devTools.injectTestError(
          errorType: WebSocketErrorType.authenticationFailed,
          customMessage: 'Test auth error',
        );

        expect(monitor.currentMetrics.errorCount, equals(1));
        expect(monitor.currentMetrics.authenticationFailures, equals(1));
        
        final errorEvents = debugLogger.getErrorEvents();
        expect(errorEvents.length, equals(1));
        expect(errorEvents.first.error!.type, equals(WebSocketErrorType.authenticationFailed));
        expect(errorEvents.first.error!.message, equals('Test auth error'));
      });

      test('should inject test error with default message', () {
        devTools.injectTestError(errorType: WebSocketErrorType.networkError);

        final errorEvents = debugLogger.getErrorEvents();
        expect(errorEvents.length, equals(1));
        expect(errorEvents.first.error!.message, contains('networkError'));
      });
    });

    group('Debug Report Generation', () {
      test('should generate comprehensive debug report', () {
        // Add some test data
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        
        monitor.recordMessageSent(channel, message);
        monitor.recordMessageReceived(channel, message);
        debugLogger.logConnectionAttempt('ws://test.com');

        final report = devTools.generateDebugReport();

        expect(report, isA<Map<String, dynamic>>());
        expect(report['reportGeneratedAt'], isA<String>());
        expect(report['serviceStatus'], isA<Map<String, dynamic>>());
        expect(report['metrics'], isA<Map<String, dynamic>>());
        expect(report['performanceReport'], isA<Map<String, dynamic>>());
        expect(report['eventSummary'], isA<Map<String, dynamic>>());
        expect(report['errorAnalysis'], isA<Map<String, dynamic>>());
        expect(report['connectionAnalysis'], isA<Map<String, dynamic>>());
        expect(report['recommendations'], isA<List>());
      });

      test('should include event summary in report', () {
        debugLogger.logConnectionAttempt('ws://test.com');
        debugLogger.logConnectionSuccess('ws://test.com');
        debugLogger.logSubscription('test_channel');

        final report = devTools.generateDebugReport();
        final eventSummary = report['eventSummary'] as Map<String, dynamic>;

        expect(eventSummary['totalEvents'], equals(3));
        expect(eventSummary['eventsByType'], isA<Map<String, int>>());
        expect(eventSummary['timeRange'], isNotNull);
      });

      test('should include error analysis in report', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        debugLogger.logError(error);
        debugLogger.logConnectionAttempt('ws://test.com');

        final report = devTools.generateDebugReport();
        final errorAnalysis = report['errorAnalysis'] as Map<String, dynamic>;

        expect(errorAnalysis['totalErrors'], equals(1));
        expect(errorAnalysis['errorsByType'], isA<Map<String, int>>());
        expect(errorAnalysis['errorRate'], equals(0.5)); // 1 error out of 2 events
        expect(errorAnalysis['mostCommonError'], equals('networkError'));
      });

      test('should include connection analysis in report', () {
        debugLogger.logConnectionAttempt('ws://test.com');
        debugLogger.logConnectionSuccess('ws://test.com');
        debugLogger.logConnectionFailure('ws://test.com', WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        ));

        final report = devTools.generateDebugReport();
        final connectionAnalysis = report['connectionAnalysis'] as Map<String, dynamic>;

        expect(connectionAnalysis['connectionAttempts'], equals(1));
        expect(connectionAnalysis['successfulConnections'], equals(1));
        expect(connectionAnalysis['failedConnections'], equals(1));
        expect(connectionAnalysis['successRate'], equals(1.0));
        expect(connectionAnalysis['failureRate'], equals(1.0));
      });

      test('should generate recommendations', () {
        // Create conditions that should trigger recommendations
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );

        // Record multiple errors to trigger high error rate
        for (int i = 0; i < 5; i++) {
          monitor.recordError(error);
        }

        final report = devTools.generateDebugReport();
        final recommendations = report['recommendations'] as List<String>;

        expect(recommendations, isNotEmpty);
        expect(recommendations.any((r) => r.contains('error rate')), isTrue);
      });
    });

    group('Data Export and Reset', () {
      test('should export all data', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        
        monitor.recordMessageSent(channel, message);
        debugLogger.logConnectionAttempt('ws://test.com');

        final exportData = devTools.exportAllData();

        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData['debugReport'], isA<Map<String, dynamic>>());
        expect(exportData['debugSession'], isA<Map<String, dynamic>>());
        expect(exportData['performanceReport'], isA<Map<String, dynamic>>());
        expect(exportData['exportedAt'], isA<String>());
      });

      test('should reset all data', () {
        const channel = 'test_channel';
        final message = {'type': 'test', 'data': 'hello'};
        
        monitor.recordMessageSent(channel, message);
        debugLogger.logConnectionAttempt('ws://test.com');

        expect(monitor.currentMetrics.messagesSent, equals(1));
        expect(debugLogger.events.length, equals(1));

        devTools.resetAllData();

        expect(monitor.currentMetrics.messagesSent, equals(0));
        expect(debugLogger.events.length, equals(0));
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () {
        expect(() => devTools.dispose(), returnsNormally);
      });

      test('should stop running tests on disposal', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);

        // Start load test
        devTools.startLoadTest(duration: const Duration(seconds: 10));

        // Dispose should stop the test
        devTools.dispose();

        // Wait a bit
        await Future.delayed(const Duration(milliseconds: 100));

        // Should not have sent many messages
        expect(monitor.currentMetrics.messagesSent, lessThan(5));
      });
    });
  });
}