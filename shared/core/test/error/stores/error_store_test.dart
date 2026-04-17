import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/error_severity.dart';
import 'package:core/error/models/error_type.dart';
import 'package:core/error/models/network_status.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/stores/error_store.dart';

import 'error_store_test.mocks.dart';

@GenerateMocks([IErrorService, NetworkMonitor])
void main() {
  group('ErrorStore', () {
    late ErrorStore errorStore;
    late MockIErrorService mockErrorService;
    late MockNetworkMonitor mockNetworkMonitor;
    late StreamController<List<AppError>> errorStreamController;
    late StreamController<AppError?> currentErrorStreamController;
    late StreamController<NetworkStatus> networkStatusStreamController;

    setUp(() {
      mockErrorService = MockIErrorService();
      mockNetworkMonitor = MockNetworkMonitor();
      
      // Set up stream controllers
      errorStreamController = StreamController<List<AppError>>.broadcast();
      currentErrorStreamController = StreamController<AppError?>.broadcast();
      networkStatusStreamController = StreamController<NetworkStatus>.broadcast();
      
      // Mock the streams
      when(mockErrorService.errorStream).thenAnswer((_) => errorStreamController.stream);
      when(mockErrorService.currentErrorStream).thenAnswer((_) => currentErrorStreamController.stream);
      when(mockNetworkMonitor.statusStream).thenAnswer((_) => networkStatusStreamController.stream);
      
      // Mock initial states
      when(mockErrorService.activeErrors).thenReturn([]);
      when(mockErrorService.currentError).thenReturn(null);
      when(mockErrorService.hasErrors).thenReturn(false);
      when(mockNetworkMonitor.currentStatus).thenReturn(NetworkStatus.online());
      
      errorStore = ErrorStore(mockErrorService, mockNetworkMonitor);
    });

    tearDown(() {
      errorStore.dispose();
      errorStreamController.close();
      currentErrorStreamController.close();
      networkStatusStreamController.close();
    });

    group('Observable Properties', () {
      test('should initialize with default values', () {
        expect(errorStore.activeErrors, isEmpty);
        expect(errorStore.currentError, isNull);
        expect(errorStore.isOffline, isFalse);
        expect(errorStore.networkQuality, NetworkQuality.good);
        expect(errorStore.isErrorBarVisible, isTrue);
        expect(errorStore.isErrorBarMinimized, isFalse);
        expect(errorStore.showErrorDetailsFlag, isFalse);
        expect(errorStore.autoHideNonCriticalErrors, isTrue);
        expect(errorStore.autoHideDuration, const Duration(seconds: 15));
        expect(errorStore.showNetworkStatusInBar, isTrue);
      });

      test('should update activeErrors when error stream emits', () async {
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([testError]);
        await Future.delayed(Duration.zero); // Allow stream to process

        expect(errorStore.activeErrors, hasLength(1));
        expect(errorStore.activeErrors.first.id, testError.id);
      });

      test('should update currentError when current error stream emits', () async {
        final testError = ApiError(
          message: 'Current error',
          statusCode: 404,
          endpoint: '/current',
          method: 'GET',
        );

        currentErrorStreamController.add(testError);
        await Future.delayed(Duration.zero);

        expect(errorStore.currentError, isNotNull);
        expect(errorStore.currentError!.id, testError.id);
      });

      test('should update network status when network stream emits', () async {
        final offlineStatus = NetworkStatus.offline();

        networkStatusStreamController.add(offlineStatus);
        await Future.delayed(Duration.zero);

        expect(errorStore.isOffline, isTrue);
        expect(errorStore.networkQuality, NetworkQuality.offline);
        expect(errorStore.networkStatus, equals(offlineStatus));
      });
    });

    group('Computed Properties', () {
      test('hasErrors should return true when activeErrors is not empty', () async {
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([testError]);
        await Future.delayed(Duration.zero);

        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.hasActiveErrors, isTrue);
        expect(errorStore.errorCount, equals(1));
      });

      test('priorityError should return error with highest priority', () async {
        final lowPriorityError = ApiError(
          message: 'Low priority',
          statusCode: 400, // Error severity
          endpoint: '/test',
          method: 'GET',
        );

        final highPriorityError = ApiError(
          message: 'High priority',
          statusCode: 500, // Critical severity
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([lowPriorityError, highPriorityError]);
        await Future.delayed(Duration.zero);

        expect(errorStore.priorityError, isNotNull);
        expect(errorStore.priorityError!.id, highPriorityError.id);
        expect(errorStore.priorityError!.severity, ErrorSeverity.critical);
      });

      test('shouldShowErrorBar should be true when has errors or offline', () async {
        // Test with errors
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([testError]);
        await Future.delayed(Duration.zero);

        expect(errorStore.shouldShowErrorBar, isTrue);

        // Clear errors and test with offline status
        errorStreamController.add([]);
        networkStatusStreamController.add(NetworkStatus.offline());
        await Future.delayed(Duration.zero);

        expect(errorStore.shouldShowErrorBar, isTrue);
      });

      test('errorBarTitle should return appropriate message', () async {
        // Test with error
        final testError = ApiError(
          message: 'API Error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([testError]);
        await Future.delayed(Duration.zero);

        expect(errorStore.errorBarTitle, equals('API Error'));

        // Test with offline status
        errorStreamController.add([]);
        networkStatusStreamController.add(NetworkStatus.offline());
        await Future.delayed(Duration.zero);

        expect(errorStore.errorBarTitle, equals('No internet connection'));
      });

      test('networkStatusText should return appropriate status text', () async {
        // Test excellent connection
        networkStatusStreamController.add(NetworkStatus.online(quality: NetworkQuality.excellent));
        await Future.delayed(Duration.zero);

        expect(errorStore.networkStatusText, equals('Excellent connection'));

        // Test offline
        networkStatusStreamController.add(NetworkStatus.offline());
        await Future.delayed(Duration.zero);

        expect(errorStore.networkStatusText, equals('Offline'));
      });

      test('hasNetworkIssues should be true for offline or poor quality', () async {
        // Test offline
        networkStatusStreamController.add(NetworkStatus.offline());
        await Future.delayed(Duration.zero);

        expect(errorStore.hasNetworkIssues, isTrue);

        // Test poor quality
        networkStatusStreamController.add(NetworkStatus.online(quality: NetworkQuality.poor));
        await Future.delayed(Duration.zero);

        expect(errorStore.hasNetworkIssues, isTrue);

        // Test good quality
        networkStatusStreamController.add(NetworkStatus.online(quality: NetworkQuality.good));
        await Future.delayed(Duration.zero);

        expect(errorStore.hasNetworkIssues, isFalse);
      });
    });

    group('Error Management Actions', () {
      test('addError should call error service showError', () {
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStore.addError(testError);

        verify(mockErrorService.showError(testError)).called(1);
      });

      test('removeError should call error service clearError', () {
        const errorId = 'test-error-id';

        errorStore.removeError(errorId);

        verify(mockErrorService.clearError(errorId)).called(1);
      });

      test('clearAllErrors should call error service clearAllErrors', () {
        errorStore.clearAllErrors();

        verify(mockErrorService.clearAllErrors()).called(1);
      });

      test('clearErrorsByType should call error service clearErrorsByType', () {
        const errorType = 'api';

        errorStore.clearErrorsByType(errorType);

        verify(mockErrorService.clearErrorsByType(errorType)).called(1);
      });
    });

    group('Error Bar Visibility Actions', () {
      test('showErrorBar should set visibility and minimize state', () {
        errorStore.hideErrorBar();
        errorStore.minimizeErrorBar();

        errorStore.showErrorBar();

        expect(errorStore.isErrorBarVisible, isTrue);
        expect(errorStore.isErrorBarMinimized, isFalse);
      });

      test('hideErrorBar should set visibility to false', () {
        errorStore.hideErrorBar();

        expect(errorStore.isErrorBarVisible, isFalse);
      });

      test('minimizeErrorBar should set minimized to true', () {
        errorStore.minimizeErrorBar();

        expect(errorStore.isErrorBarMinimized, isTrue);
      });

      test('expandErrorBar should set minimized to false', () {
        errorStore.minimizeErrorBar();
        errorStore.expandErrorBar();

        expect(errorStore.isErrorBarMinimized, isFalse);
      });

      test('toggleErrorBarMinimized should toggle minimized state', () {
        expect(errorStore.isErrorBarMinimized, isFalse);

        errorStore.toggleErrorBarMinimized();
        expect(errorStore.isErrorBarMinimized, isTrue);

        errorStore.toggleErrorBarMinimized();
        expect(errorStore.isErrorBarMinimized, isFalse);
      });
    });

    group('Error Details Actions', () {
      test('showErrorDetails should set showErrorDetailsFlag to true', () {
        errorStore.showErrorDetails();

        expect(errorStore.showErrorDetailsFlag, isTrue);
      });

      test('hideErrorDetails should set showErrorDetailsFlag to false', () {
        errorStore.showErrorDetails();
        errorStore.hideErrorDetails();

        expect(errorStore.showErrorDetailsFlag, isFalse);
      });

      test('toggleErrorDetails should toggle showErrorDetailsFlag state', () {
        expect(errorStore.showErrorDetailsFlag, isFalse);

        errorStore.toggleErrorDetails();
        expect(errorStore.showErrorDetailsFlag, isTrue);

        errorStore.toggleErrorDetails();
        expect(errorStore.showErrorDetailsFlag, isFalse);
      });
    });

    group('User Preferences Actions', () {
      test('setAutoHideNonCriticalErrors should update preference', () {
        errorStore.setAutoHideNonCriticalErrors(false);

        expect(errorStore.autoHideNonCriticalErrors, isFalse);
      });

      test('setAutoHideDuration should update duration', () {
        const newDuration = Duration(seconds: 30);

        errorStore.setAutoHideDuration(newDuration);

        expect(errorStore.autoHideDuration, equals(newDuration));
      });

      test('setShowNetworkStatusInBar should update preference', () {
        errorStore.setShowNetworkStatusInBar(false);

        expect(errorStore.showNetworkStatusInBar, isFalse);
      });
    });

    group('Network Status Integration', () {
      test('should show error bar when network goes offline', () async {
        errorStore.hideErrorBar();

        networkStatusStreamController.add(NetworkStatus.offline());
        await Future.delayed(Duration.zero);

        expect(errorStore.isErrorBarVisible, isTrue);
      });

      test('should show error bar when network quality becomes poor', () async {
        errorStore.hideErrorBar();

        networkStatusStreamController.add(NetworkStatus.online(quality: NetworkQuality.poor));
        await Future.delayed(Duration.zero);

        expect(errorStore.isErrorBarVisible, isTrue);
      });

      test('should auto-minimize when connection is restored and no errors', () async {
        // Set up initial state with errors
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );

        errorStreamController.add([testError]);
        await Future.delayed(Duration.zero);

        expect(errorStore.isErrorBarVisible, isTrue);

        // Clear errors and restore good connection
        errorStreamController.add([]);
        networkStatusStreamController.add(NetworkStatus.online(quality: NetworkQuality.good));
        await Future.delayed(Duration.zero);

        // Wait for the auto-minimize timer (3 seconds + small buffer)
        await Future.delayed(const Duration(seconds: 4));

        expect(errorStore.isErrorBarMinimized, isTrue);
      });
    });

    group('Auto-Hide Functionality', () {
      test('shouldAutoHideCurrentError should return true for auto-dismissible errors', () async {
        final autoDismissError = ApiError(
          message: 'Auto dismiss error',
          statusCode: 400, // Error severity - should auto-dismiss
          endpoint: '/test',
          method: 'GET',
        );

        currentErrorStreamController.add(autoDismissError);
        await Future.delayed(Duration.zero);

        expect(errorStore.shouldAutoHideCurrentError, isFalse); // Error severity doesn't auto-dismiss
      });

      test('shouldAutoHideCurrentError should return false for critical errors', () async {
        final criticalError = ApiError(
          message: 'Critical error',
          statusCode: 500, // Critical severity - should not auto-dismiss
          endpoint: '/test',
          method: 'GET',
        );

        currentErrorStreamController.add(criticalError);
        await Future.delayed(Duration.zero);

        expect(errorStore.shouldAutoHideCurrentError, isFalse);
      });

      test('should not auto-hide when autoHideNonCriticalErrors is false', () async {
        errorStore.setAutoHideNonCriticalErrors(false);

        final autoDismissError = ApiError(
          message: 'Auto dismiss error',
          statusCode: 300, // Warning severity - would auto-dismiss if enabled
          endpoint: '/test',
          method: 'GET',
        );

        currentErrorStreamController.add(autoDismissError);
        await Future.delayed(Duration.zero);

        expect(errorStore.shouldAutoHideCurrentError, isFalse);
      });
    });

    group('Dispose', () {
      test('should clean up resources when disposed', () {
        errorStore.dispose();

        // Verify that the store is properly disposed
        expect(errorStore.activeErrors, isEmpty);
        expect(errorStore.currentError, isNull);
        expect(errorStore.networkStatus, isNull);
      });
    });
  });
}