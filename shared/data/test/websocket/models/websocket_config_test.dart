import 'package:flutter_test/flutter_test.dart';
import 'package:data/data.dart';

void main() {
  group('WebSocketConfig', () {
    test('should create WebSocketConfig with required fields', () {
      const config = WebSocketConfig(
        url: 'ws://localhost:3000',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
      );

      expect(config.url, equals('ws://localhost:3000'));
      expect(config.reconnectInterval, equals(const Duration(seconds: 5)));
      expect(config.maxReconnectAttempts, equals(5));
      expect(config.heartbeatInterval, equals(const Duration(seconds: 30)));
      expect(config.autoReconnect, isTrue); // Default value
    });

    test('should create WebSocketConfig with custom autoReconnect', () {
      const config = WebSocketConfig(
        url: 'wss://api.production.com',
        reconnectInterval: Duration(seconds: 10),
        maxReconnectAttempts: 10,
        heartbeatInterval: Duration(minutes: 1),
        autoReconnect: false,
      );

      expect(config.url, equals('wss://api.production.com'));
      expect(config.reconnectInterval, equals(const Duration(seconds: 10)));
      expect(config.maxReconnectAttempts, equals(10));
      expect(config.heartbeatInterval, equals(const Duration(minutes: 1)));
      expect(config.autoReconnect, isFalse);
    });

    test('should serialize to JSON correctly', () {
      const config = WebSocketConfig(
        url: 'ws://test.com',
        reconnectInterval: Duration(seconds: 15),
        maxReconnectAttempts: 3,
        heartbeatInterval: Duration(seconds: 45),
        autoReconnect: false,
      );

      final json = config.toJson();

      expect(json['url'], equals('ws://test.com'));
      expect(json['reconnectInterval'], equals(15000000)); // microseconds
      expect(json['maxReconnectAttempts'], equals(3));
      expect(json['heartbeatInterval'], equals(45000000)); // microseconds
      expect(json['autoReconnect'], isFalse);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'url': 'ws://example.com',
        'reconnectInterval': 20000000, // 20 seconds in microseconds
        'maxReconnectAttempts': 7,
        'heartbeatInterval': 60000000, // 60 seconds in microseconds
        'autoReconnect': true,
      };

      final config = WebSocketConfig.fromJson(json);

      expect(config.url, equals('ws://example.com'));
      expect(config.reconnectInterval, equals(const Duration(seconds: 20)));
      expect(config.maxReconnectAttempts, equals(7));
      expect(config.heartbeatInterval, equals(const Duration(seconds: 60)));
      expect(config.autoReconnect, isTrue);
    });

    test('should deserialize from JSON with default autoReconnect', () {
      final json = {
        'url': 'ws://example.com',
        'reconnectInterval': 5000000,
        'maxReconnectAttempts': 5,
        'heartbeatInterval': 30000000,
      };

      final config = WebSocketConfig.fromJson(json);

      expect(config.url, equals('ws://example.com'));
      expect(config.autoReconnect, isTrue); // Default value
    });

    test('should support equality comparison', () {
      const config1 = WebSocketConfig(
        url: 'ws://test.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );

      const config2 = WebSocketConfig(
        url: 'ws://test.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );

      const config3 = WebSocketConfig(
        url: 'ws://different.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should support copyWith functionality', () {
      const originalConfig = WebSocketConfig(
        url: 'ws://original.com',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );

      final updatedConfig = originalConfig.copyWith(
        url: 'ws://updated.com',
        maxReconnectAttempts: 10,
        autoReconnect: false,
      );

      expect(updatedConfig.url, equals('ws://updated.com'));
      expect(updatedConfig.reconnectInterval, equals(const Duration(seconds: 5)));
      expect(updatedConfig.maxReconnectAttempts, equals(10));
      expect(updatedConfig.heartbeatInterval, equals(const Duration(seconds: 30)));
      expect(updatedConfig.autoReconnect, isFalse);
    });

    test('should validate reasonable configuration values', () {
      // Test with production-like configuration
      const productionConfig = WebSocketConfig(
        url: 'wss://api.production.com/socket.io',
        reconnectInterval: Duration(seconds: 10),
        maxReconnectAttempts: 10,
        heartbeatInterval: Duration(minutes: 1),
        autoReconnect: true,
      );

      expect(productionConfig.url, contains('wss://'));
      expect(productionConfig.reconnectInterval.inSeconds, greaterThan(0));
      expect(productionConfig.maxReconnectAttempts, greaterThan(0));
      expect(productionConfig.heartbeatInterval.inSeconds, greaterThan(0));
    });

    test('should handle development configuration', () {
      const developmentConfig = WebSocketConfig(
        url: 'ws://localhost:3000/socket.io',
        reconnectInterval: Duration(seconds: 5),
        maxReconnectAttempts: 5,
        heartbeatInterval: Duration(seconds: 30),
        autoReconnect: true,
      );

      expect(developmentConfig.url, contains('localhost'));
      expect(developmentConfig.reconnectInterval.inSeconds, equals(5));
      expect(developmentConfig.maxReconnectAttempts, equals(5));
      expect(developmentConfig.heartbeatInterval.inSeconds, equals(30));
    });
  });
}