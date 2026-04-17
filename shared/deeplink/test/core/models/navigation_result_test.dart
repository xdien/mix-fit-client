import 'package:flutter_test/flutter_test.dart';
import 'package:deeplink/core/models/navigation_result.dart';

void main() {
  group('NavigationStatus', () {
    test('should provide correct descriptions', () {
      expect(NavigationStatus.success.description, equals('Navigation completed successfully'));
      expect(NavigationStatus.permissionDenied.description, equals('Permission denied for this route'));
      expect(NavigationStatus.routeNotFound.description, equals('Route not found'));
    });

    test('should identify success and error states', () {
      expect(NavigationStatus.success.isSuccess, isTrue);
      expect(NavigationStatus.success.isError, isFalse);
      
      expect(NavigationStatus.permissionDenied.isSuccess, isFalse);
      expect(NavigationStatus.permissionDenied.isError, isTrue);
    });
  });

  group('NavigationResult', () {
    test('should create successful result', () {
      final result = NavigationResult.success(
        targetScreen: 'DeviceListScreen',
        message: 'Navigation completed',
      );

      expect(result.status, equals(NavigationStatus.success));
      expect(result.targetScreen, equals('DeviceListScreen'));
      expect(result.message, equals('Navigation completed'));
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('should create failure result', () {
      final result = NavigationResult.failure(
        status: NavigationStatus.routeNotFound,
        message: 'Route not found',
        errorDetails: 'The requested route does not exist',
      );

      expect(result.status, equals(NavigationStatus.routeNotFound));
      expect(result.message, equals('Route not found'));
      expect(result.errorDetails, equals('The requested route does not exist'));
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
    });

    test('should create permission denied result', () {
      final result = NavigationResult.permissionDenied(
        message: 'Access denied',
        fallbackRoute: 'DashboardScreen',
      );

      expect(result.status, equals(NavigationStatus.permissionDenied));
      expect(result.message, equals('Access denied'));
      expect(result.fallbackRoute, equals('DashboardScreen'));
    });

    test('should create route not found result', () {
      final result = NavigationResult.routeNotFound(
        message: 'Route not found',
        requestedRoute: 'iot/unknown-feature',
      );

      expect(result.status, equals(NavigationStatus.routeNotFound));
      expect(result.message, equals('Route not found'));
      expect(result.metadata['requestedRoute'], equals('iot/unknown-feature'));
    });

    test('should serialize to and from JSON', () {
      final result = NavigationResult.success(
        targetScreen: 'DeviceListScreen',
        message: 'Navigation completed',
        metadata: {'userId': '123'},
      );

      final json = result.toJson();
      final restored = NavigationResult.fromJson(json);

      expect(restored.status, equals(result.status));
      expect(restored.message, equals(result.message));
      expect(restored.targetScreen, equals(result.targetScreen));
      expect(restored.metadata, equals(result.metadata));
    });

    test('should support equality comparison', () {
      final timestamp = DateTime.now();
      final result1 = NavigationResult(
        status: NavigationStatus.success,
        message: 'Success',
        targetScreen: 'TestScreen',
        timestamp: timestamp,
      );

      final result2 = NavigationResult(
        status: NavigationStatus.success,
        message: 'Success',
        targetScreen: 'TestScreen',
        timestamp: timestamp,
      );

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
    });

    test('should create copy with modified properties', () {
      final original = NavigationResult.success(
        targetScreen: 'OriginalScreen',
        message: 'Original message',
      );

      final modified = original.copyWith(
        message: 'Modified message',
        targetScreen: 'ModifiedScreen',
      );

      expect(modified.status, equals(original.status));
      expect(modified.message, equals('Modified message'));
      expect(modified.targetScreen, equals('ModifiedScreen'));
    });
  });
}