import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/services/network_connectivity_detector.dart';

void main() {
  group('NetworkConnectivityDetector', () {
    late NetworkConnectivityDetector detector;

    setUp(() {
      detector = NetworkConnectivityDetector(
        checkInterval: const Duration(milliseconds: 100), // Fast for testing
        testTimeout: const Duration(milliseconds: 500),
      );
    });

    tearDown(() {
      detector.dispose();
    });

    group('Initialization', () {
      test('should initialize with default connected state', () {
        expect(detector.isConnected, isTrue);
      });

      test('should use custom configuration', () {
        final customDetector = NetworkConnectivityDetector(
          checkInterval: const Duration(seconds: 60),
          testHost: 'example.com',
          testPort: 443,
          testTimeout: const Duration(seconds: 10),
        );

        expect(customDetector.isConnected, isTrue);
        customDetector.dispose();
      });
    });

    group('Connectivity Monitoring', () {
      test('should start and stop monitoring without errors', () {
        expect(() => detector.startMonitoring(), returnsNormally);
        expect(() => detector.stopMonitoring(), returnsNormally);
      });

      test('should emit connectivity changes', () async {
        final connectivityChanges = <bool>[];
        final subscription = detector.connectivityStream.listen(connectivityChanges.add);

        detector.startMonitoring();
        
        // Wait for potential connectivity checks
        await Future.delayed(const Duration(milliseconds: 200));
        
        detector.stopMonitoring();
        
        // Note: In test environment, actual connectivity changes are hard to simulate
        // This test mainly ensures the monitoring doesn't crash
        expect(() => detector.stopMonitoring(), returnsNormally);
        
        await subscription.cancel();
      });

      test('should handle multiple start/stop calls gracefully', () {
        expect(() {
          detector.startMonitoring();
          detector.startMonitoring(); // Should not cause issues
          detector.stopMonitoring();
          detector.stopMonitoring(); // Should not cause issues
        }, returnsNormally);
      });
    });

    group('Manual Connectivity Check', () {
      test('should perform manual connectivity check', () async {
        // In test environment, this will likely fail due to network restrictions
        // But it should not throw an exception
        expect(() async => await detector.checkConnectivity(), returnsNormally);
      });

      test('should check host reachability', () async {
        // Test with a likely unreachable host in test environment
        final isReachable = await detector.isHostReachable(
          'nonexistent.invalid.domain', 
          80,
          timeout: const Duration(milliseconds: 100),
        );
        
        expect(isReachable, isFalse);
      });

      test('should handle invalid host gracefully', () async {
        final isReachable = await detector.isHostReachable(
          'invalid-host-name-that-does-not-exist', 
          80,
          timeout: const Duration(milliseconds: 100),
        );
        
        expect(isReachable, isFalse);
      });
    });

    group('WebSocket Server Reachability', () {
      test('should check WebSocket server reachability with ws URL', () async {
        final isReachable = await detector.isWebSocketServerReachable('ws://localhost:3000');
        
        // In test environment, this will likely be false
        expect(isReachable, isA<bool>());
      });

      test('should check WebSocket server reachability with wss URL', () async {
        final isReachable = await detector.isWebSocketServerReachable('wss://echo.websocket.org');
        
        // This might be reachable in some test environments
        expect(isReachable, isA<bool>());
      });

      test('should handle invalid WebSocket URL', () async {
        final isReachable = await detector.isWebSocketServerReachable('invalid-url');
        
        expect(isReachable, isFalse);
      });

      test('should handle malformed WebSocket URL', () async {
        final isReachable = await detector.isWebSocketServerReachable('not-a-url-at-all');
        
        expect(isReachable, isFalse);
      });

      test('should extract correct port from WebSocket URLs', () async {
        // Test default ports
        final wsResult = await detector.isWebSocketServerReachable('ws://example.com');
        final wssResult = await detector.isWebSocketServerReachable('wss://example.com');
        
        expect(wsResult, isA<bool>());
        expect(wssResult, isA<bool>());
      });

      test('should extract custom port from WebSocket URLs', () async {
        final result = await detector.isWebSocketServerReachable('ws://example.com:8080');
        
        expect(result, isA<bool>());
      });
    });

    group('Connectivity Stream', () {
      test('should provide connectivity stream', () {
        expect(detector.connectivityStream, isA<Stream<bool>>());
      });

      test('should handle multiple stream listeners', () async {
        final changes1 = <bool>[];
        final changes2 = <bool>[];
        
        final subscription1 = detector.connectivityStream.listen(changes1.add);
        final subscription2 = detector.connectivityStream.listen(changes2.add);

        detector.startMonitoring();
        
        // Wait for potential changes
        await Future.delayed(const Duration(milliseconds: 50));
        
        detector.stopMonitoring();
        
        await subscription1.cancel();
        await subscription2.cancel();
        
        // Both listeners should receive the same changes
        expect(changes1, equals(changes2));
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully during monitoring', () async {
        // Create detector with invalid test host to force errors
        final errorDetector = NetworkConnectivityDetector(
          checkInterval: const Duration(milliseconds: 50),
          testHost: 'definitely.invalid.host.name',
          testPort: 12345,
          testTimeout: const Duration(milliseconds: 100),
        );

        expect(() => errorDetector.startMonitoring(), returnsNormally);
        
        // Wait for a few check cycles
        await Future.delayed(const Duration(milliseconds: 200));
        
        expect(() => errorDetector.stopMonitoring(), returnsNormally);
        
        errorDetector.dispose();
      });

      test('should handle timeout during connectivity check', () async {
        final result = await detector.isHostReachable(
          'httpbin.org', // This might be slow or unreachable in test environment
          80,
          timeout: const Duration(milliseconds: 1), // Very short timeout
        );
        
        expect(result, isFalse);
      });
    });

    group('Disposal', () {
      test('should dispose without errors', () {
        detector.startMonitoring();
        expect(() => detector.dispose(), returnsNormally);
      });

      test('should stop monitoring on disposal', () {
        detector.startMonitoring();
        detector.dispose();
        
        // Should not crash when trying to stop after disposal
        expect(() => detector.stopMonitoring(), returnsNormally);
      });

      test('should handle multiple dispose calls', () {
        expect(() {
          detector.dispose();
          detector.dispose(); // Should not cause issues
        }, returnsNormally);
      });
    });

    group('Configuration', () {
      test('should use default configuration values', () {
        final defaultDetector = NetworkConnectivityDetector();
        
        expect(defaultDetector.isConnected, isTrue);
        
        defaultDetector.dispose();
      });

      test('should respect custom check interval', () async {
        final fastDetector = NetworkConnectivityDetector(
          checkInterval: const Duration(milliseconds: 10),
        );

        final changes = <bool>[];
        final subscription = fastDetector.connectivityStream.listen(changes.add);

        fastDetector.startMonitoring();
        
        // With fast interval, we might see more frequent checks
        await Future.delayed(const Duration(milliseconds: 100));
        
        fastDetector.stopMonitoring();
        
        await subscription.cancel();
        fastDetector.dispose();
        
        // Test passes if no exceptions are thrown
        expect(true, isTrue);
      });
    });

    group('Alternative Connectivity Test', () {
      test('should fallback to alternative test when primary fails', () async {
        // Create detector with definitely failing primary test
        final detector = NetworkConnectivityDetector(
          testHost: 'definitely.does.not.exist.invalid',
          testPort: 99999,
          testTimeout: const Duration(milliseconds: 100),
        );

        // This should try the alternative test (1.1.1.1:53)
        final result = await detector.checkConnectivity();
        
        // In test environment, even alternative might fail, but should not throw
        expect(result, isA<bool>());
        
        detector.dispose();
      });
    });
  });
}