import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

@GenerateMocks([SharedPreferenceHelper])
import 'websocket_factory_test.mocks.dart';

void main() {
  group('WebSocketFactory', () {
    late MockSharedPreferenceHelper mockSharedPreferenceHelper;

    setUp(() {
      mockSharedPreferenceHelper = MockSharedPreferenceHelper();
      
      // Reset WebSocketManager instance before each test
      WebSocketManager.resetInstance();
    });

    tearDown(() {
      WebSocketManager.resetInstance();
    });

    group('WebSocket Service Creation', () {
      test('should create WebSocket service with default config', () {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        final service = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        expect(service, isA<WebSocketService>());
        expect(service.currentState, WebSocketConnectionState.disconnected);
      });

      test('should create WebSocket service with custom config', () {
        const customConfig = WebSocketConfig(
          url: 'ws://custom.com',
          reconnectInterval: Duration(seconds: 2),
          maxReconnectAttempts: 5,
          heartbeatInterval: Duration(seconds: 20),
          autoReconnect: false,
        );

        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        final service = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: customConfig,
        );

        expect(service, isA<WebSocketService>());
        expect(service.currentState, WebSocketConnectionState.disconnected);
      });
    });

    group('WebSocket Manager Initialization', () {
      test('should initialize WebSocket manager with default config', () {
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;
        expect(manager.webSocketService, isNotNull);
        expect(manager.currentState, WebSocketConnectionState.disconnected);
      });

      test('should initialize WebSocket manager with custom config', () {
        const customConfig = WebSocketConfig(
          url: 'ws://custom.com',
          reconnectInterval: Duration(seconds: 3),
          maxReconnectAttempts: 7,
          heartbeatInterval: Duration(seconds: 25),
          autoReconnect: true,
        );

        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => 'test-token');

        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
          config: customConfig,
        );

        final manager = WebSocketManager.instance;
        expect(manager.webSocketService, isNotNull);
        expect(manager.currentState, WebSocketConnectionState.disconnected);
      });
    });

    group('Configuration Creation', () {
      test('should create development configuration', () {
        final config = WebSocketFactory.createDevelopmentConfig();

        expect(config.url, equals('ws://localhost:3000/socket.io'));
        expect(config.reconnectInterval, equals(const Duration(seconds: 2)));
        expect(config.maxReconnectAttempts, equals(5));
        expect(config.heartbeatInterval, equals(const Duration(seconds: 15)));
        expect(config.autoReconnect, isTrue);
      });

      test('should create production configuration with HTTPS URL', () {
        const baseUrl = 'https://api.example.com';
        final config = WebSocketFactory.createProductionConfig(baseUrl);

        expect(config.url, equals('wss://api.example.com/socket.io'));
        expect(config.reconnectInterval, equals(const Duration(seconds: 10)));
        expect(config.maxReconnectAttempts, equals(15));
        expect(config.heartbeatInterval, equals(const Duration(minutes: 1)));
        expect(config.autoReconnect, isTrue);
      });

      test('should create production configuration with HTTP URL', () {
        const baseUrl = 'http://api.example.com';
        final config = WebSocketFactory.createProductionConfig(baseUrl);

        expect(config.url, equals('ws://api.example.com/socket.io'));
        expect(config.reconnectInterval, equals(const Duration(seconds: 10)));
        expect(config.maxReconnectAttempts, equals(15));
        expect(config.heartbeatInterval, equals(const Duration(minutes: 1)));
        expect(config.autoReconnect, isTrue);
      });

      test('should create production configuration with plain domain', () {
        const baseUrl = 'api.example.com';
        final config = WebSocketFactory.createProductionConfig(baseUrl);

        expect(config.url, equals('wss://api.example.com/socket.io'));
        expect(config.reconnectInterval, equals(const Duration(seconds: 10)));
        expect(config.maxReconnectAttempts, equals(15));
        expect(config.heartbeatInterval, equals(const Duration(minutes: 1)));
        expect(config.autoReconnect, isTrue);
      });

      test('should handle URL with existing socket.io path', () {
        const baseUrl = 'https://api.example.com/socket.io';
        final config = WebSocketFactory.createProductionConfig(baseUrl);

        expect(config.url, equals('wss://api.example.com/socket.io'));
      });
    });

    group('Singleton Pattern', () {
      test('should maintain singleton pattern for factory', () {
        final factory1 = WebSocketFactory.instance;
        final factory2 = WebSocketFactory.instance;

        expect(factory1, same(factory2));
      });
    });

    group('Integration', () {
      test('should create working WebSocket service with auth integration', () async {
        const testToken = 'integration-test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        final service = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        expect(service, isA<WebSocketService>());
        
        // Test subscription functionality
        service.subscribe('test-channel', (data) {});
        service.unsubscribe('test-channel');

        // Service should remain functional
        expect(service.currentState, WebSocketConnectionState.disconnected);
      });

      test('should create working WebSocket manager with auth integration', () async {
        const testToken = 'manager-integration-test-token';
        when(mockSharedPreferenceHelper.authToken)
            .thenAnswer((_) async => testToken);

        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;
        expect(manager.webSocketService, isNotNull);

        // Test manager functionality
        manager.subscribe('test-channel', (data) {});
        manager.unsubscribe('test-channel');

        expect(manager.currentState, WebSocketConnectionState.disconnected);
      });
    });

    group('Error Handling', () {
      test('should handle auth helper errors gracefully', () {
        when(mockSharedPreferenceHelper.authToken)
            .thenThrow(Exception('Storage error'));

        // Should not throw during service creation
        final service = WebSocketFactory.createWebSocketService(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        expect(service, isA<WebSocketService>());
      });

      test('should handle manager initialization errors gracefully', () {
        when(mockSharedPreferenceHelper.authToken)
            .thenThrow(Exception('Storage error'));

        // Should not throw during manager initialization
        WebSocketFactory.initializeWebSocketManager(
          sharedPreferenceHelper: mockSharedPreferenceHelper,
        );

        final manager = WebSocketManager.instance;
        expect(manager.webSocketService, isNotNull);
      });
    });
  });
}