import 'package:flutter_test/flutter_test.dart';
import 'package:deeplink/core/models/deeplink_request.dart';

void main() {
  group('DeeplinkRequest', () {
    test('should create a valid deeplink request', () {
      final request = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-list',
        parameters: {'type': 'sensor', 'status': 'active'},
        originalUrl: 'iot://iot/device-list?type=sensor&status=active',
        timestamp: DateTime.now(),
      );

      expect(request.isValid(), isTrue);
      expect(request.scheme, equals('iot'));
      expect(request.module, equals('iot'));
      expect(request.feature, equals('device-list'));
      expect(request.parameters['type'], equals('sensor'));
      expect(request.parameters['status'], equals('active'));
    });

    test('should detect invalid deeplink request', () {
      final request = DeeplinkRequest(
        scheme: '',
        module: 'iot',
        feature: 'device-list',
        parameters: {},
        originalUrl: '',
        timestamp: DateTime.now(),
      );

      expect(request.isValid(), isFalse);
    });

    test('should convert to string correctly', () {
      final request = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-list',
        parameters: {'type': 'sensor', 'status': 'active'},
        originalUrl: 'iot://iot/device-list?type=sensor&status=active',
        timestamp: DateTime.now(),
      );

      final urlString = request.toString();
      expect(urlString, contains('iot://iot/device-list'));
      expect(urlString, contains('type=sensor'));
      expect(urlString, contains('status=active'));
    });

    test('should handle empty parameters', () {
      final request = DeeplinkRequest(
        scheme: 'iot',
        module: 'settings',
        feature: 'preferences',
        parameters: {},
        originalUrl: 'iot://settings/preferences',
        timestamp: DateTime.now(),
      );

      expect(request.toString(), equals('iot://settings/preferences'));
    });

    test('should serialize to and from JSON', () {
      final timestamp = DateTime.now();
      final request = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-detail',
        parameters: {'id': '123'},
        originalUrl: 'iot://iot/device-detail?id=123',
        timestamp: timestamp,
      );

      final json = request.toJson();
      final restored = DeeplinkRequest.fromJson(json);

      expect(restored.scheme, equals(request.scheme));
      expect(restored.module, equals(request.module));
      expect(restored.feature, equals(request.feature));
      expect(restored.parameters, equals(request.parameters));
      expect(restored.originalUrl, equals(request.originalUrl));
      expect(restored.timestamp, equals(request.timestamp));
    });

    test('should support equality comparison', () {
      final timestamp = DateTime.now();
      final request1 = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-list',
        parameters: {'type': 'sensor'},
        originalUrl: 'iot://iot/device-list?type=sensor',
        timestamp: timestamp,
      );

      final request2 = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-list',
        parameters: {'type': 'sensor'},
        originalUrl: 'iot://iot/device-list?type=sensor',
        timestamp: timestamp,
      );

      expect(request1, equals(request2));
      expect(request1.hashCode, equals(request2.hashCode));
    });

    test('should create copy with modified properties', () {
      final original = DeeplinkRequest(
        scheme: 'iot',
        module: 'iot',
        feature: 'device-list',
        parameters: {'type': 'sensor'},
        originalUrl: 'iot://iot/device-list?type=sensor',
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(
        feature: 'device-detail',
        parameters: {'id': '123'},
      );

      expect(modified.scheme, equals(original.scheme));
      expect(modified.module, equals(original.module));
      expect(modified.feature, equals('device-detail'));
      expect(modified.parameters, equals({'id': '123'}));
      expect(modified.originalUrl, equals(original.originalUrl));
    });
  });
}