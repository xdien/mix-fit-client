import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/network_status.dart';
import 'package:core/di/error_module.dart';

import 'network_connectivity_integration_test.mocks.dart';

@GenerateMocks([NetworkMonitor])
void main() {
  group('Network Connectivity Integration Tests', () {
    late GetIt getIt;
    late MockNetworkMonitor mockNetworkMonitor;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      mockNetworkMonitor = MockNetworkMonitor();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      // Replace network monitor with mock
      getIt.unregister<NetworkMonitor>();
      getIt.registerSingleton<NetworkMonitor>(mockNetworkMonitor);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('Connectivity State Changes', () {
      test('should update error store when device goes offline', () async {
        // Arrange
        when(mockNetworkMonitor.connectivityStream)
            .thenAnswer((_) => Stream.value(false));
        when(mockNetworkMonitor.qualityStream)
            .thenAnswer((_) => Stream.value(NetworkQuality.offline));
        when(mockNetworkMonitor.checkConnectivity())
            .thenAnswer((_) async => false);

        // Act - Simulate going offline
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.isOffline, isTrue);
        expect(errorStore.networkQuality, equals(NetworkQuality.offline));
        expect(errorStore.shouldShowErrorBar, isTrue);
      });

      test('should update error store when device comes back online', () async {
        // Arrange - Start offline
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        when(mockNetworkMonitor.connectivityStream)
            .thenAnswer((_) => Stream.value(true));
        when(mockNetworkMonitor.qualityStream)
            .thenAnswer((_) => Stream.value(NetworkQuality.good));
        when(mockNetworkMonitor.checkConnectivity())
            .thenAnswer((_) async => true);

        // Act - Simulate coming back online
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.good,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.isOffline, isFalse);
        expect(errorStore.networkQuality, equals(NetworkQuality.good));
        
        // Should show brief "connected" confirmation
        expect(errorStore.hasConnectionStatusMessage, isTrue);
      });

      test('should handle intermittent connectivity issues', () async {
        // Arrange
        when(mockNetworkMonitor.connectivityStream)
            .thenAnswer((_) => Stream.value(true));
        when(mockNetworkMonitor.qualityStream)
            .thenAnswer((_) => Stream.value(NetworkQuality.poor));
        when(mockNetworkMonitor.checkConnectivity())
            .thenAnswer((_) async => true);

        // Act - Simulate poor connection
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.poor,
          latency: const Duration(milliseconds: 2000),
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.isOffline, isFalse);
        expect(errorStore.networkQuality, equals(NetworkQuality.poor));
        expect(errorStore.shouldShowPoorConnectionWarning, isTrue);
      });
    });

    group('Network Error Handling', () {
      test('should show appropriate error for offline actions', () async {
        // Arrange - Set offline state
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        // Act - Attempt to perform online-only action
        final networkError = NetworkError(
          message: 'No internet connection. This action requires an internet connection.',
          networkType: NetworkErrorType.noConnection,
          isRetryable: true,
        );

        errorService.showError(networkError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as NetworkError;
        expect(error.networkType, equals(NetworkErrorType.noConnection));
        expect(error.isRetryable, isTrue);
        expect(error.actions, isNotNull);
        
        // Should have retry action that's disabled while offline
        final retryAction = error.actions!.firstWhere(
          (action) => action.id == 'retry',
        );
        expect(retryAction.isEnabled, isFalse);
      });

      test('should queue actions when offline and execute when online', () async {
        // Arrange - Start offline
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        // Act - Queue an action while offline
        final queuedAction = QueuedAction(
          id: 'test-action',
          type: 'api-request',
          data: {'endpoint': '/test', 'method': 'GET'},
          timestamp: DateTime.now(),
        );

        errorStore.queueOfflineAction(queuedAction);

        // Verify action is queued
        expect(errorStore.queuedActions.length, equals(1));
        expect(errorStore.queuedActions.first.id, equals('test-action'));

        // Come back online
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.good,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Queued actions should be processed
        expect(errorStore.queuedActions.isEmpty, isTrue);
        expect(errorStore.hasProcessedQueuedActions, isTrue);
      });
    });

    group('Network Quality Monitoring', () {
      test('should monitor network quality changes', () async {
        // Arrange
        final qualityStream = Stream.fromIterable([
          NetworkQuality.excellent,
          NetworkQuality.good,
          NetworkQuality.fair,
          NetworkQuality.poor,
        ]);

        when(mockNetworkMonitor.qualityStream)
            .thenAnswer((_) => qualityStream);

        // Act - Listen to quality changes
        final qualityChanges = <NetworkQuality>[];
        errorStore.networkQualityStream.listen((quality) {
          qualityChanges.add(quality);
        });

        // Simulate quality changes
        await for (final quality in qualityStream) {
          errorStore.updateNetworkStatus(NetworkStatus(
            isConnected: true,
            quality: quality,
            lastChecked: DateTime.now(),
          ));
          await Future.delayed(const Duration(milliseconds: 50));
        }

        // Assert
        expect(qualityChanges.length, equals(4));
        expect(qualityChanges, equals([
          NetworkQuality.excellent,
          NetworkQuality.good,
          NetworkQuality.fair,
          NetworkQuality.poor,
        ]));
      });

      test('should show warnings for poor network quality', () async {
        // Arrange
        when(mockNetworkMonitor.measureQuality())
            .thenAnswer((_) async => NetworkQuality.poor);

        // Act - Update to poor quality
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.poor,
          latency: const Duration(milliseconds: 3000),
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.networkQuality, equals(NetworkQuality.poor));
        expect(errorStore.shouldShowPoorConnectionWarning, isTrue);
        expect(errorStore.networkLatency, equals(const Duration(milliseconds: 3000)));
      });
    });

    group('Offline Feature Availability', () {
      test('should indicate which features are available offline', () async {
        // Arrange - Go offline
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        // Act - Check feature availability
        final offlineFeatures = errorStore.getOfflineAvailableFeatures();

        // Assert
        expect(offlineFeatures, isNotEmpty);
        expect(offlineFeatures, contains('view_cached_data'));
        expect(offlineFeatures, contains('create_draft'));
        expect(offlineFeatures, contains('edit_offline'));
        expect(offlineFeatures, isNot(contains('sync_data')));
        expect(offlineFeatures, isNot(contains('real_time_updates')));
      });

      test('should show appropriate messaging for offline-only actions', () async {
        // Arrange - Set offline
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        // Act - Try to perform online-only action
        final error = NetworkError(
          message: 'This feature requires an internet connection',
          networkType: NetworkErrorType.noConnection,
          metadata: {
            'feature': 'real_time_sync',
            'offline_alternative': 'save_as_draft',
          },
        );

        errorService.showError(error);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final storedError = errorStore.activeErrors.first as NetworkError;
        expect(storedError.metadata?['offline_alternative'], equals('save_as_draft'));
        
        // Should have action to save as draft
        final draftAction = storedError.actions?.firstWhere(
          (action) => action.id == 'save_draft',
          orElse: () => throw StateError('Draft action not found'),
        );
        expect(draftAction, isNotNull);
        expect(draftAction!.label, equals('Save as Draft'));
      });
    });

    group('Connection Recovery', () {
      test('should handle connection recovery gracefully', () async {
        // Arrange - Start with poor connection
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.poor,
          latency: const Duration(milliseconds: 2500),
          lastChecked: DateTime.now(),
        ));

        // Add some network-related errors
        final networkError = NetworkError(
          message: 'Request timed out due to poor connection',
          networkType: NetworkErrorType.timeout,
        );
        errorService.showError(networkError);

        await Future.delayed(const Duration(milliseconds: 100));
        expect(errorStore.hasErrors, isTrue);

        // Act - Connection improves
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.excellent,
          latency: const Duration(milliseconds: 50),
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.networkQuality, equals(NetworkQuality.excellent));
        expect(errorStore.shouldShowPoorConnectionWarning, isFalse);
        
        // Network-related errors should be auto-dismissed or marked as resolved
        final remainingNetworkErrors = errorStore.activeErrors
            .where((error) => error is NetworkError)
            .toList();
        expect(remainingNetworkErrors.length, lessThan(1));
      });
    });
  });
}

// Additional models for testing
class QueuedAction {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  QueuedAction({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
  });
}