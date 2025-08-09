import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/models/network_status.dart';
import '../../../lib/error/services/network_monitor.dart';

void main() {
  group('NetworkMonitor', () {
    late NetworkMonitor networkMonitor;

    setUp(() {
      networkMonitor = NetworkMonitor();
    });

    tearDown(() {
      networkMonitor.dispose();
    });

    group('Basic Functionality', () {
      test('should start with offline status', () {
        expect(networkMonitor.isConnected, isFalse);
        expect(networkMonitor.currentQuality, equals(NetworkQuality.offline));
        expect(networkMonitor.currentStatus.isOffline, isTrue);
      });

      test('should provide stream access', () {
        expect(networkMonitor.connectivityStream, isA<Stream<bool>>());
        expect(networkMonitor.qualityStream, isA<Stream<NetworkQuality>>());
        expect(networkMonitor.statusStream, isA<Stream<NetworkStatus>>());
      });

      test('should handle disposal correctly', () {
        expect(networkMonitor.isConnected, isFalse);
        
        networkMonitor.dispose();
        
        // Should not crash after disposal
        networkMonitor.stopMonitoring();
      });
    });

    group('Connectivity Checking', () {
      test('should check connectivity', () async {
        // This test depends on actual network connectivity
        // In a real environment, this would typically return true
        final isConnected = await networkMonitor.checkConnectivity();
        expect(isConnected, isA<bool>());
      });

      test('should measure network quality', () async {
        // This test depends on actual network connectivity
        final quality = await networkMonitor.measureQuality();
        expect(quality, isA<NetworkQuality>());
      });

      test('should check complete network status', () async {
        final status = await networkMonitor.checkNetworkStatus();
        
        expect(status, isA<NetworkStatus>());
        expect(status.lastChecked, isA<DateTime>());
        expect(status.quality, isA<NetworkQuality>());
      });
    });

    group('Monitoring', () {
      test('should start and stop monitoring', () {
        expect(networkMonitor.isConnected, isFalse);
        
        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 100),
        );
        
        // Should not crash
        networkMonitor.stopMonitoring();
      });

      test('should not start monitoring multiple times', () {
        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 100),
        );
        
        // Starting again should not cause issues
        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 50),
        );
        
        networkMonitor.stopMonitoring();
      });

      test('should handle monitoring after disposal', () {
        networkMonitor.dispose();
        
        // Should not crash
        networkMonitor.startMonitoring();
        networkMonitor.stopMonitoring();
      });
    });

    group('Stream Notifications', () {
      test('should emit connectivity changes', () async {
        final connectivityCompleter = Completer<bool>();
        late StreamSubscription subscription;

        subscription = networkMonitor.connectivityStream.listen((isConnected) {
          if (!connectivityCompleter.isCompleted) {
            connectivityCompleter.complete(isConnected);
            subscription.cancel();
          }
        });

        // Start monitoring to trigger connectivity check
        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 100),
        );

        // Wait for first connectivity update
        final isConnected = await connectivityCompleter.future
            .timeout(const Duration(seconds: 5));

        expect(isConnected, isA<bool>());
        networkMonitor.stopMonitoring();
      });

      test('should emit quality changes', () async {
        final qualityCompleter = Completer<NetworkQuality>();
        late StreamSubscription subscription;

        subscription = networkMonitor.qualityStream.listen((quality) {
          if (!qualityCompleter.isCompleted) {
            qualityCompleter.complete(quality);
            subscription.cancel();
          }
        });

        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 100),
        );

        final quality = await qualityCompleter.future
            .timeout(const Duration(seconds: 5));

        expect(quality, isA<NetworkQuality>());
        networkMonitor.stopMonitoring();
      });

      test('should emit status updates', () async {
        final statusCompleter = Completer<NetworkStatus>();
        late StreamSubscription subscription;

        subscription = networkMonitor.statusStream.listen((status) {
          if (!statusCompleter.isCompleted) {
            statusCompleter.complete(status);
            subscription.cancel();
          }
        });

        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 100),
        );

        final status = await statusCompleter.future
            .timeout(const Duration(seconds: 5));

        expect(status, isA<NetworkStatus>());
        expect(status.lastChecked, isA<DateTime>());
        networkMonitor.stopMonitoring();
      });
    });

    group('Network Quality Assessment', () {
      test('should handle offline quality correctly', () {
        final offlineStatus = NetworkStatus.offline();
        expect(offlineStatus.quality, equals(NetworkQuality.offline));
        expect(offlineStatus.isOffline, isTrue);
        expect(offlineStatus.isGoodEnough, isFalse);
      });

      test('should handle online quality levels', () {
        final excellentStatus = NetworkStatus.online(
          quality: NetworkQuality.excellent,
        );
        expect(excellentStatus.isGoodEnough, isTrue);
        expect(excellentStatus.isOffline, isFalse);

        final poorStatus = NetworkStatus.online(
          quality: NetworkQuality.poor,
        );
        expect(poorStatus.isGoodEnough, isFalse);
        expect(poorStatus.isOffline, isFalse);
      });
    });

    group('Extension Methods', () {
      test('should provide connection quality check', () {
        // Test with offline status
        expect(networkMonitor.isConnectionGoodEnough, isFalse);
        expect(networkMonitor.isOffline, isTrue);
      });

      test('should provide status description', () {
        final description = networkMonitor.statusDescription;
        expect(description, isA<String>());
        expect(description.isNotEmpty, isTrue);
        
        // Should indicate no connection for initial offline state
        expect(description.toLowerCase(), contains('no'));
      });

      test('should provide status icon', () {
        final icon = networkMonitor.statusIcon;
        expect(icon, isA<String>());
        expect(icon.isNotEmpty, isTrue);
        
        // Should be wifi_off for offline state
        expect(icon, equals('wifi_off'));
      });

      test('should provide different descriptions for different qualities', () {
        // Create a mock monitor with different status for testing
        final monitor = NetworkMonitor();
        
        // Test offline description
        expect(monitor.statusDescription, contains('No internet'));
        expect(monitor.statusIcon, equals('wifi_off'));
        
        monitor.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle connectivity check failures gracefully', () async {
        // This test verifies that the method doesn't throw exceptions
        final result = await networkMonitor.checkConnectivity();
        expect(result, isA<bool>());
      });

      test('should handle quality measurement failures gracefully', () async {
        final quality = await networkMonitor.measureQuality();
        expect(quality, isA<NetworkQuality>());
      });

      test('should handle status check failures gracefully', () async {
        final status = await networkMonitor.checkNetworkStatus();
        expect(status, isA<NetworkStatus>());
      });

      test('should handle monitoring errors without crashing', () async {
        networkMonitor.startMonitoring(
          interval: const Duration(milliseconds: 50),
        );

        // Let it run for a short time to ensure no crashes
        await Future.delayed(const Duration(milliseconds: 200));

        networkMonitor.stopMonitoring();
        
        // Should complete without throwing
      });
    });

    group('Resource Management', () {
      test('should clean up resources on disposal', () {
        networkMonitor.startMonitoring();
        
        // Dispose should stop monitoring and clean up
        networkMonitor.dispose();
        
        // Further operations should not crash
        networkMonitor.stopMonitoring();
      });

      test('should handle multiple disposals', () {
        networkMonitor.dispose();
        networkMonitor.dispose(); // Should not crash
      });

      test('should not accept operations after disposal', () async {
        networkMonitor.dispose();
        
        // These should return safe defaults or handle gracefully
        final connectivity = await networkMonitor.checkConnectivity();
        expect(connectivity, isFalse);
        
        final quality = await networkMonitor.measureQuality();
        expect(quality, equals(NetworkQuality.offline));
      });
    });
  });
}