import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/services/websocket_monitoring_service.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/models/websocket_debug_event.dart';

import '../stores/websocket_aware_store_test.mocks.dart';

void main() {
  group('WebSocket Monitoring Integration', () {
    late MockIWebSocketService mockWebSocketService;
    late WebSocketMonitoringService monitoringService;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      when(mockWebSocketService.connectionState).thenAnswer(
        (_) => Stream.fromIterable([WebSocketConnectionState.disconnected]),
      );
      when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
      
      monitoringService = WebSocketMonitoringService(mockWebSocketService);
    });

    tearDown(() {
      if (monitoringService.isInitialized) {
        monitoringService.dispose();
      }
    });

    test('should initialize all monitoring components', () async {
      await monitoringService.initialize();

      expect(monitoringService.isInitialized, isTrue);
      expect(monitoringService.monitor, isNotNull);
      expect(monitoringService.debugLogger, isNotNull);
      expect(monitoringService.devTools, isNotNull);
      expect(monitoringService.analytics, isNotNull);
    });

    test('should track complete WebSocket lifecycle', () async {
      await monitoringService.initialize();

      // Record various WebSocket operations
      const channel = 'test_channel';
      final message = {'type': 'test', 'data': 'hello'};
      
      // Record subscription
      monitoringService.recordSubscription(channel);
      
      // Record messages
      monitoringService.recordMessageSent(channel, message);
      monitoringService.recordMessageReceived(channel, message);
      
      // Record error
      final error = WebSocketError(
        type: WebSocketErrorType.networkError,
        message: 'Test error',
        timestamp: DateTime.now(),
        isRecoverable: true,
      );
      monitoringService.recordError(error);
      
      // Record unsubscription
      monitoringService.recordUnsubscription(channel);

      // Verify metrics were recorded
      final metrics = monitoringService.monitor.currentMetrics;
      expect(metrics.subscriptions, equals(1));
      expect(metrics.messagesSent, equals(1));
      expect(metrics.messagesReceived, equals(1));
      expect(metrics.errorCount, equals(1));
      expect(metrics.unsubscriptions, equals(1));

      // Verify debug events were logged
      final debugEvents = monitoringService.debugLogger.events;
      expect(debugEvents.length, greaterThanOrEqualTo(5));
      expect(debugEvents.any((e) => e.type == WebSocketDebugEventType.subscriptionAdded), isTrue);
      expect(debugEvents.any((e) => e.type == WebSocketDebugEventType.messageSent), isTrue);
      expect(debugEvents.any((e) => e.type == WebSocketDebugEventType.messageReceived), isTrue);
      expect(debugEvents.any((e) => e.type == WebSocketDebugEventType.error), isTrue);
      expect(debugEvents.any((e) => e.type == WebSocketDebugEventType.subscriptionRemoved), isTrue);
    });

    test('should generate comprehensive monitoring report', () async {
      await monitoringService.initialize();

      // Add some test data
      const channel = 'test_channel';
      final message = {'type': 'test', 'data': 'hello'};
      
      monitoringService.recordMessageSent(channel, message);
      monitoringService.recordMessageReceived(channel, message);

      final report = monitoringService.getMonitoringReport();

      expect(report, isA<Map<String, dynamic>>());
      expect(report['isInitialized'], isTrue);
      expect(report['metrics'], isA<Map<String, dynamic>>());
      expect(report['debugReport'], isA<Map<String, dynamic>>());
      expect(report['analyticsSummary'], isA<Map<String, dynamic>>());
      
      // Verify metrics in report
      final metrics = report['metrics'] as Map<String, dynamic>;
      expect(metrics['messagesSent'], equals(1));
      expect(metrics['messagesReceived'], equals(1));
    });

    test('should handle configuration updates', () async {
      await monitoringService.initialize();

      final newConfig = const WebSocketDebugConfig(
        enableLogging: false,
        enableEventTracking: true,
        logLevel: WebSocketDebugLogLevel.error,
      );

      monitoringService.updateDebugConfig(newConfig);

      expect(monitoringService.debugConfig, equals(newConfig));
      
      // Should have logged the configuration change
      final debugEvents = monitoringService.debugLogger.events;
      expect(debugEvents.any((e) => 
        e.type == WebSocketDebugEventType.configurationChange &&
        e.data!['setting'] == 'debugConfig'
      ), isTrue);
    });

    test('should emit monitoring updates', () async {
      final updateStream = monitoringService.updateStream;
      final updates = <WebSocketMonitoringUpdate>[];
      
      final subscription = updateStream.listen((update) {
        updates.add(update);
      });

      await monitoringService.initialize();

      // Wait for initialization update
      await Future.delayed(const Duration(milliseconds: 10));

      expect(updates.isNotEmpty, isTrue);
      expect(updates.any((u) => u.type == WebSocketMonitoringUpdateType.initialization), isTrue);

      await subscription.cancel();
    });

    test('should reset all monitoring data', () async {
      await monitoringService.initialize();

      // Add some test data
      const channel = 'test_channel';
      final message = {'type': 'test', 'data': 'hello'};
      
      monitoringService.recordMessageSent(channel, message);
      monitoringService.debugLogger.logConnectionAttempt('ws://test.com');

      expect(monitoringService.monitor.currentMetrics.messagesSent, equals(1));
      expect(monitoringService.debugLogger.events.length, greaterThanOrEqualTo(1));

      monitoringService.resetAllData();

      expect(monitoringService.monitor.currentMetrics.messagesSent, equals(0));
      expect(monitoringService.debugLogger.events.length, equals(0));
    });

    test('should export all monitoring data', () async {
      await monitoringService.initialize();

      // Add some test data
      const channel = 'test_channel';
      final message = {'type': 'test', 'data': 'hello'};
      
      monitoringService.recordMessageSent(channel, message);

      final exportData = monitoringService.exportAllData();

      expect(exportData, isA<Map<String, dynamic>>());
      expect(exportData['debugReport'], isA<Map<String, dynamic>>());
      expect(exportData['debugSession'], isA<Map<String, dynamic>>());
      expect(exportData['performanceReport'], isA<Map<String, dynamic>>());
      expect(exportData['exportedAt'], isA<String>());
    });

    test('should handle analytics enable/disable', () async {
      await monitoringService.initialize();

      expect(monitoringService.analytics.isEnabled, isTrue);

      monitoringService.setAnalyticsEnabled(false);

      expect(monitoringService.analytics.isEnabled, isFalse);

      monitoringService.setAnalyticsEnabled(true);

      expect(monitoringService.analytics.isEnabled, isTrue);
    });

    test('should work with development tools', () async {
      await monitoringService.initialize();

      expect(monitoringService.devTools.isAvailable, isTrue);

      final serviceStatus = monitoringService.devTools.getServiceStatus();
      expect(serviceStatus, isA<Map<String, dynamic>>());
      expect(serviceStatus['connectionState'], isA<String>());
      expect(serviceStatus['metrics'], isA<Map<String, dynamic>>());

      // Test error injection
      monitoringService.devTools.injectTestError(
        errorType: WebSocketErrorType.networkError,
        customMessage: 'Test error injection',
      );

      expect(monitoringService.monitor.currentMetrics.errorCount, equals(1));
      expect(monitoringService.debugLogger.events.any((e) => 
        e.type == WebSocketDebugEventType.error &&
        e.error?.message == 'Test error injection'
      ), isTrue);
    });

    test('should dispose all resources properly', () async {
      await monitoringService.initialize();

      expect(() => monitoringService.dispose(), returnsNormally);
      expect(monitoringService.isInitialized, isFalse);
    });
  });
}