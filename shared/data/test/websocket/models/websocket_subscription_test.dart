import 'package:flutter_test/flutter_test.dart';
import 'package:data/data.dart';

void main() {
  group('WebSocketSubscription', () {
    test('should create WebSocketSubscription with required fields', () {
      final subscribedAt = DateTime.now();
      void mockCallback(dynamic data) {}

      final subscription = WebSocketSubscription(
        channel: 'customer',
        callback: mockCallback,
        subscribedAt: subscribedAt,
      );

      expect(subscription.channel, equals('customer'));
      expect(subscription.callback, equals(mockCallback));
      expect(subscription.subscribedAt, equals(subscribedAt));
      expect(subscription.isActive, isTrue); // Default value
    });

    test('should create WebSocketSubscription with custom isActive', () {
      final subscribedAt = DateTime.now();
      void mockCallback(dynamic data) {}

      final subscription = WebSocketSubscription(
        channel: 'inventory',
        callback: mockCallback,
        subscribedAt: subscribedAt,
        isActive: false,
      );

      expect(subscription.channel, equals('inventory'));
      expect(subscription.callback, equals(mockCallback));
      expect(subscription.subscribedAt, equals(subscribedAt));
      expect(subscription.isActive, isFalse);
    });

    test('should support equality comparison', () {
      final subscribedAt = DateTime.now();
      void mockCallback1(dynamic data) {}
      void mockCallback2(dynamic data) {}

      final subscription1 = WebSocketSubscription(
        channel: 'orders',
        callback: mockCallback1,
        subscribedAt: subscribedAt,
        isActive: true,
      );

      final subscription2 = WebSocketSubscription(
        channel: 'orders',
        callback: mockCallback1,
        subscribedAt: subscribedAt,
        isActive: true,
      );

      final subscription3 = WebSocketSubscription(
        channel: 'orders',
        callback: mockCallback2,
        subscribedAt: subscribedAt,
        isActive: true,
      );

      expect(subscription1, equals(subscription2));
      expect(subscription1, isNot(equals(subscription3)));
    });

    test('should support copyWith functionality', () {
      final originalSubscribedAt = DateTime.now();
      final newSubscribedAt = DateTime.now().add(const Duration(minutes: 1));
      void mockCallback(dynamic data) {}
      void newCallback(dynamic data) {}

      final originalSubscription = WebSocketSubscription(
        channel: 'original',
        callback: mockCallback,
        subscribedAt: originalSubscribedAt,
        isActive: true,
      );

      final updatedSubscription = originalSubscription.copyWith(
        channel: 'updated',
        callback: newCallback,
        isActive: false,
      );

      expect(updatedSubscription.channel, equals('updated'));
      expect(updatedSubscription.callback, equals(newCallback));
      expect(updatedSubscription.subscribedAt, equals(originalSubscribedAt));
      expect(updatedSubscription.isActive, isFalse);
    });

    test('should handle different callback types', () {
      final subscribedAt = DateTime.now();

      // Test with different callback signatures
      void simpleCallback(dynamic data) {
        // Simple callback
      }

      void typedCallback(dynamic data) {
        // Typed callback - can handle any dynamic data
      }

      final subscription1 = WebSocketSubscription(
        channel: 'test1',
        callback: simpleCallback,
        subscribedAt: subscribedAt,
      );

      final subscription2 = WebSocketSubscription(
        channel: 'test2',
        callback: typedCallback,
        subscribedAt: subscribedAt,
      );

      expect(subscription1.callback, equals(simpleCallback));
      expect(subscription2.callback, equals(typedCallback));
    });

    test('should handle channel naming conventions', () {
      final subscribedAt = DateTime.now();
      void mockCallback(dynamic data) {}

      final userSpecificSubscription = WebSocketSubscription(
        channel: 'user.123',
        callback: mockCallback,
        subscribedAt: subscribedAt,
      );

      final featureSubscription = WebSocketSubscription(
        channel: 'inventory',
        callback: mockCallback,
        subscribedAt: subscribedAt,
      );

      final roleBasedSubscription = WebSocketSubscription(
        channel: 'admin',
        callback: mockCallback,
        subscribedAt: subscribedAt,
      );

      expect(userSpecificSubscription.channel, equals('user.123'));
      expect(featureSubscription.channel, equals('inventory'));
      expect(roleBasedSubscription.channel, equals('admin'));
    });

    test('should track subscription timing', () {
      final beforeSubscription = DateTime.now();
      void mockCallback(dynamic data) {}

      final subscription = WebSocketSubscription(
        channel: 'timing-test',
        callback: mockCallback,
        subscribedAt: DateTime.now(),
      );

      final afterSubscription = DateTime.now();

      expect(subscription.subscribedAt.isAfter(beforeSubscription) ||
             subscription.subscribedAt.isAtSameMomentAs(beforeSubscription), isTrue);
      expect(subscription.subscribedAt.isBefore(afterSubscription) ||
             subscription.subscribedAt.isAtSameMomentAs(afterSubscription), isTrue);
    });

    test('should support active/inactive state management', () {
      final subscribedAt = DateTime.now();
      void mockCallback(dynamic data) {}

      final activeSubscription = WebSocketSubscription(
        channel: 'active-channel',
        callback: mockCallback,
        subscribedAt: subscribedAt,
        isActive: true,
      );

      final inactiveSubscription = activeSubscription.copyWith(isActive: false);

      expect(activeSubscription.isActive, isTrue);
      expect(inactiveSubscription.isActive, isFalse);
      expect(inactiveSubscription.channel, equals('active-channel'));
      expect(inactiveSubscription.callback, equals(mockCallback));
    });

    test('should handle callback execution context', () {
      final subscribedAt = DateTime.now();
      var callbackExecuted = false;
      var receivedData;

      void testCallback(dynamic data) {
        callbackExecuted = true;
        receivedData = data;
      }

      final subscription = WebSocketSubscription(
        channel: 'callback-test',
        callback: testCallback,
        subscribedAt: subscribedAt,
      );

      // Simulate callback execution
      const testData = {'test': 'data'};
      subscription.callback(testData);

      expect(callbackExecuted, isTrue);
      expect(receivedData, equals(testData));
    });
  });
}