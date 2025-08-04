import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/services/websocket_monitoring_service.dart';
import 'package:data/websocket/models/websocket_debug_event.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';

import '../stores/websocket_aware_store_test.mocks.dart';

void main() {
  group('WebSocketMonitoringService', () {
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

    group('Initialization', () {
      test('should not be initialized by default', () {
        expect(monitoringService.isInitialized, isFalse);
      });

      test('should initialize with default configuration', () async {
        await monitoringService.initialize();

        expect(monitoringService.isInitialized, isTrue);
        expect(monitoringService.debugConfig, isA<WebSocketDebugConfig>());
        expect(monitoringService.monitor, isNotNull);
        expect(monitoringService.debugLogger, isNotNull);
        expect(monitoringService.devTools, isNotNull);
        expect(monitoringService.analytics, isNotNull);
      });

      test('should initialize with custom configuration', () async {
        final customConfig = const WebSocketDebugConfig(
          enableLogging: false,
          enableEventTracking: true,
          logLevel: WebSocketDebugLogLevel.error,
          maxEventsInMemory: 500,
        );

        await monitoringService.initialize(
          debugConfig: customConfig,
          enableAnalytics: false,
          enableDevTools: false,
        );

        expect(monitoringService.isInitialized, isTrue);
        expect(monitoringService.debugConfig, equals(customConfig));
      });

      test('should not reinitialize if already initialized', () async {
        await monitoringService.initialize();
        expect(monitoringService.isInitialized, isTrue);

        // Try to initialize again
        await monitoringService.initialize();
        
        // Should still be initialized without issues
        expect(monitoringService.isInitialized, isTrue);
      });

      test('should provide update stream', () {
        expect(monitoringService.updateStream, isA<Stream<WebSocketMonitoringUpdate>>());
      });
    });

    group('Monitoring Updates', () {
      setUp(() async {
        await monitoringService.initialize();
      });

      test('should emit initialization update', () async {
        // Dispose and reinitialize to test initialization update
        monitoringService.dispose();
        monitoringService = WebSocketMonitoringService(mockWebSocketService);

        final updateStream = monitoringService.updateStream;
        final updates = <WebSocketMonitoringUpdate>[];
        
        final subscription = updateStream.listen((update) {
          updates.add(update);
        });

        await monitoringService.initialize();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(updates.isNotEmpty, isTrue);
        expect(updates.any((u) => u.type == WebSocketMonitoringUpdateType.initialization), isTrue);

        await subscription.cancel();
      });

      test('should emit connection state updates', () async {
        final updateStream = monitoringService.updateStream;
        final updates = <WebSocketMonitoringUpdate>[];
        
        final subscription = updateStream.listen((update) {
          if (update.type == WebSocketMonitoringUpdateType.connectionState) {
            updates.add(update);
          }
        });

        // Simulate connection state change
        when(mockWebSocketService.connectionState).thenAnswer(
          (_) => Stream.fromIterable([WebSocketConnectionState.connected]),
        );

        // Trigger state change by creating new monitoring service
        monitoringService.dispose();
        monitoringService = WebSocketMonitoringService(mockWebSocketService);
        await monitoringService.initialize();

        await Future.delayed(const Duration(milliseconds: 50));

        expect(updates.isNotEmpty, isTrue);
        expect(updates.first.data['state'], equals('connected'));

        await subscription.cancel();
      });
    });

    group('Recording Methods', () {
      setUp(() async {
        await monitoringService.initialize();
      });

      test('should record message sent', () {
        const channel = 'test_channel';
        final data = {'type': 'test', 'message': 'hello'};

        monitoringService.recordMessageSent(channel, data);

        expect(monitoringService.monitor.currentMetrics.messagesSent, equals(1));
        expect(monitoringService.debugLogger.events.any((e) => 
          e.type == WebSocketDebugEventType.messageSent && e.channel == channel
        ), isTrue);
      });

      test('should record message received', () {
        const channel = 'test_channel';
        final data = {'type': 'test', 'message': 'hello'};
        const processingTime = Duration(milliseconds: 25);

        monitoringService.recordMessageReceived(channel, data, processingTime: processingTime);

        expect(monitoringService.monitor.currentMetrics.messagesReceived, equals(1));
        expect(monitoringService.debugLogger.events.any((e) => 
          e.type == WebSocketDebugEventType.messageReceived && 
          e.channel == channel &&
          e.duration == processingTime
        ), isTrue);
      });

      test('should record subscription', () {
        const channel = 'test_channel';

        monitoringService.recordSubscription(channel);

        expect(monitoringService.monitor.currentMetrics.subscriptions, equals(1));
        expect(monitoringService.debugLogger.events.any((e) => 
          e.type == WebSocketDebugEventType.subscriptionAdded && e.channel == channel
        ), isTrue);
      });

      test('should record unsubscription', () {
        const channel = 'test_channel';

        monitoringService.recordUnsubscription(channel);

        expect(monitoringService.monitor.currentMetrics.unsubscriptions, equals(1));
        expect(monitoringService.debugLogger.events.any((e) => 
          e.type == WebSocketDebugEventType.subscriptionRemoved && e.channel == channel
        ), isTrue);
      });

      test('should record error', () {
        final error = WebSocketError(
          type: WebSocketErrorType.networkError,
          message: 'Test error',
          timestamp: DateTime.now(),
          isRecoverable: true,
        );
        const context = 'test_context';

        monitoringService.recordError(error, context: context);

        expect(monitoringService.monitor.currentMetrics.errorCount, equals(1));
        expect(monitoringService.debugLogger.events.any((e) => 
          e.type == WebSocketDebugEventType.error && 
          e.error == error &&
          e.data!['context'] == context
        ), isTrue);
      });

      test('should not record when not initialized', () {
        monitoringService.dispose();
        monitoringService = WebSocketMonitoringService(mockWebSocketService);

        const channel = 'test_channel';
        final data = {'type': 'test'};

        // Should not throw errors but also should not record
        expect(() => monitoringService.recordMessageSent(channel, data), returnsNormally);
      });
    });

    group('Configuration Management', () {
      setUp(() async {
        await monitoringService.initialize();
      });

      test('should update debug configuration', () async {
        final newConfig = const WebSocketDebugConfig(
          enableLogging: false,
          enableEventTracking: true,
          logLevel: WebSocketDebugLogLevel.warning,
        );

        final updateStream = monitoringService.updateStream;
        final updates = <WebSocketMonitoringUpdate>[];
        
        final subscription = updateStream.listen((update) {
          if (update.type == WebSocketMonitoringUpdateType.configuration) {
            updates.add(update);
          }
        });

        monitoringService.updateDebugConfig(newConfig);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(monitoringService.debugConfig, equals(newConfig));
        expect(updates.isNotEmpty, isTrue);
        expect(updates.first.data['setting'], equals('debugConfig'));

        await subscription.cancel();
      });

      test('should set analytics enabled', () async {
        final updateStream = monitoringService.updateStream;
        final updates = <WebSocketMonitoringUpdate>[];
        
        final subscription = updateStream.listen((update) {
          if (update.type == WebSocketMonitoringUpdateType.configuration) {
            updates.add(update);
          }
        });

        monitoringService.setAnalyticsEnabled(false);

        await Future.delayed(const Duration(milliseconds: 10));

        expect(monitoringService.analytics.isEnabled, isFalse);
        expect(updates.any((u) => 
          u.data['setting'] == 'analyticsEnabled' && u.data['value'] == false
        ), isTrue);

        await subscription.cancel();
      });
    });

    group('Reporting', () {
      setUp(() async {
        await monitoringService.initialize();
      });

      test('should generate monitoring report', () {
        const channel = 'test_channel';
        final data = {'type': 'test'};

        monitoringService.recordMessageSent(channel, data);

        final report = monitoringService.getMonitoringReport();

        expect(report, isA<Map<String, dynamic>>());
        expect(report['timestamp'], isA<String>());
        expect(report['isInitialized'], isTrue);
        expect(report['debugConfig'], isA<Map<String, dynamic>>());
        expect(report['serviceStatus'], isA<Map<String, dynamic>>());
        expect(report['metrics'], isA<Map<String, dynamic>>());
        expect(report['debugReport'], isA<Map<String, dynamic>>());
        expect(report['analyticsSummary'], isA<Map<String, dynamic>>());
      });

      test('should return error when not initialized', () {
        monitoringService.dispose();
        monitoringService = WebSocketMonitoringService(mockWebSocketService);

        final report = monitoringService.getMonitoringReport();

        expect(report['error'], equals('Monitoring service not initialized'));
      });

      test('should export all data', () {
        const channel = 'test_channel';
        final data = {'type': 'test'};

        monitoringService.recordMessageSent(channel, data);

        final exportData = monitoringService.exportAllData();

        expect(exportData, isA<Map<String, dynamic>>());
        expect(exportData['debugReport'], isA<Map<String, dynamic>>());
        expect(exportData['debugSession'], isA<Map<String, dynamic>>());
        expect(exportData['performanceReport'], isA<Map<String, dynamic>>());
        expect(exportData['exportedAt'], isA<String>());
      });

      test('should reset all data', () async {
        const channel = 'test_channel';
        final data = {'type': 'test'};

        monitoringService.recordMessageSent(channel, data);
        monitoringService.debugLogger.logConnectionAttempt('ws://test.com');

        expect(monitoringService.monitor.currentMetrics.messagesSent, equals(1));
        expect(monitoringService.debugLogger.events.length, equals(1));

        final updateStream = monitoringService.updateStream;
        final updates = <WebSocketMonitoringUpdate>[];
        
        final subscription = updateStream.listen((update) {
          if (update.type == WebSocketMonitoringUpdateType.reset) {
            updates.add(update);
          }
        });

        monitoringService.resetAllData();

        await Future.delayed(const Duration(milliseconds: 10));

        expect(monitoringService.monitor.currentMetrics.messagesSent, equals(0));
        expect(monitoringService.debugLogger.events.length, equals(0));
        expect(updates.isNotEmpty, isTrue);

        await subscription.cancel();
      });
    });

    group('Disposal', () {
      test('should dispose resources properly', () async {
        await monitoringService.initialize();

        expect(() => monitoringService.dispose(), returnsNormally);
        expect(monitoringService.isInitialized, isFalse);
      });

      test('should not dispose if not initialized', () {
        expect(() => monitoringService.dispose(), returnsNormally);
      });

      test('should not accept operations after disposal', () async {
        await monitoringService.initialize();
        monitoringService.dispose();

        const channel = 'test_channel';
        final data = {'type': 'test'};

        // Should not throw errors but also should not record
        expect(() => monitoringService.recordMessageSent(channel, data), returnsNormally);
      });
    });
  });

  group('WebSocketMonitoringUpdate', () {
    test('should create update with required fields', () {
      final timestamp = DateTime.now();
      final update = WebSocketMonitoringUpdate(
        type: WebSocketMonitoringUpdateType.metrics,
        timestamp: timestamp,
        data: {'test': 'value'},
      );

      expect(update.type, equals(WebSocketMonitoringUpdateType.metrics));
      expect(update.timestamp, equals(timestamp));
      expect(update.data['test'], equals('value'));
    });

    test('should convert to JSON', () {
      final timestamp = DateTime.now();
      final update = WebSocketMonitoringUpdate(
        type: WebSocketMonitoringUpdateType.connectionState,
        timestamp: timestamp,
        data: {'state': 'connected'},
      );

      final json = update.toJson();

      expect(json['type'], equals('connectionState'));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['data'], equals({'state': 'connected'}));
    });

    test('should have string representation', () {
      final update = WebSocketMonitoringUpdate(
        type: WebSocketMonitoringUpdateType.debugEvent,
        timestamp: DateTime.now(),
        data: {},
      );

      final string = update.toString();

      expect(string, contains('WebSocketMonitoringUpdate'));
      expect(string, contains('debugEvent'));
    });
  });
}