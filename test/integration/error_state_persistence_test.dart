import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/client_error.dart';
import 'package:core/di/error_module.dart';

import 'error_state_persistence_test.mocks.dart';

@GenerateMocks([])
void main() {
  group('Error State Persistence Tests', () {
    late GetIt getIt;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('Navigation State Persistence', () {
      test('should handle global errors', () async {
        // Arrange
        final globalError = ApiError(
          message: 'Global API error',
          statusCode: 500,
          endpoint: '/api/global-service',
          method: 'GET',
          isGlobal: true,
          persistAcrossNavigation: true,
        );

        // Act - Add error
        errorService.showError(globalError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.activeErrors.first, equals(globalError));
      });

      test('should clear route-specific errors on navigation', () async {
        // Arrange
        final routeSpecificError = ValidationError(
          message: 'Form validation error',
          fieldErrors: {'name': ['Name is required']},
          formId: 'customer-form',
          isRouteSpecific: true,
          routePattern: '/customers/create',
        );

        final globalError = ApiError(
          message: 'Global error',
          statusCode: 500,
          endpoint: '/api/global',
          method: 'GET',
          isGlobal: true,
        );

        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/create');

        // Act - Add both errors
        errorService.showError(routeSpecificError);
        errorService.showError(globalError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.activeErrors.length, equals(2));

        // Navigate away from the route
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/list');

        errorStore.handleRouteChange('/customers/list', '/customers/create');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Route-specific error should be cleared
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.activeErrors.first, equals(globalError));
      });

      test('should maintain error context during navigation', () async {
        // Arrange
        final contextualError = ApiError(
          message: 'Contextual error',
          statusCode: 400,
          endpoint: '/api/customers/123',
          method: 'PUT',
          navigationContext: {
            'originalRoute': '/customers/123/edit',
            'entityId': '123',
            'action': 'update',
          },
        );

        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/123/edit');
        when(mockNavigationService.getRouteParameters())
            .thenReturn({'id': '123'});

        // Act - Add error with context
        errorService.showError(contextualError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to related route
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/123');

        errorStore.handleRouteChange('/customers/123', '/customers/123/edit');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error should maintain context
        expect(errorStore.hasErrors, isTrue);
        final persistedError = errorStore.activeErrors.first as ApiError;
        expect(persistedError.navigationContext?['originalRoute'], 
               equals('/customers/123/edit'));
        expect(persistedError.navigationContext?['entityId'], equals('123'));
        expect(persistedError.currentRoute, equals('/customers/123'));
      });

      test('should handle deep navigation with error context', () async {
        // Arrange
        final deepError = ClientError(
          message: 'Deep navigation error',
          stackTrace: 'Error in deep component',
          componentName: 'CustomerDetailView',
          navigationBreadcrumb: [
            '/dashboard',
            '/customers',
            '/customers/123',
            '/customers/123/orders',
            '/customers/123/orders/456',
          ],
        );

        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/123/orders/456');
        when(mockNavigationService.getBreadcrumb())
            .thenReturn([
              '/dashboard',
              '/customers',
              '/customers/123',
              '/customers/123/orders',
              '/customers/123/orders/456',
            ]);

        // Act - Add error at deep route
        errorService.showError(deepError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate back up the hierarchy
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/123');

        errorStore.handleRouteChange('/customers/123', '/customers/123/orders/456');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error should be accessible from parent route
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as ClientError;
        expect(error.isAccessibleFromRoute('/customers/123'), isTrue);
        expect(error.navigationBreadcrumb, contains('/customers/123'));
      });
    });

    group('App Lifecycle Persistence', () {
      test('should persist critical errors across app restarts', () async {
        // Arrange
        final criticalError = ApiError(
          message: 'Critical system error',
          statusCode: 500,
          endpoint: '/api/critical-service',
          method: 'GET',
          severity: ErrorSeverity.critical,
          persistAcrossRestarts: true,
        );

        when(mockLocalStorage.saveError(any))
            .thenAnswer((_) async => true);
        when(mockLocalStorage.loadPersistedErrors())
            .thenAnswer((_) async => [criticalError.toJson()]);

        // Act - Add critical error
        errorService.showError(criticalError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate app restart
        await errorStore.persistCriticalErrors();
        errorStore.clearAllErrors();
        expect(errorStore.hasErrors, isFalse);

        // Restore from persistence
        await errorStore.restorePersistedErrors();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Critical error should be restored
        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.activeErrors.length, equals(1));
        
        final restoredError = errorStore.activeErrors.first as ApiError;
        expect(restoredError.message, equals('Critical system error'));
        expect(restoredError.severity, equals(ErrorSeverity.critical));
      });

      test('should not persist temporary errors across app restarts', () async {
        // Arrange
        final temporaryError = ValidationError(
          message: 'Form validation error',
          fieldErrors: {'field': ['error']},
          formId: 'temp-form',
          isTemporary: true,
        );

        final networkError = NetworkError(
          message: 'Network timeout',
          networkType: NetworkErrorType.timeout,
          isTemporary: true,
        );

        when(mockLocalStorage.loadPersistedErrors())
            .thenAnswer((_) async => []);

        // Act - Add temporary errors
        errorService.showError(temporaryError);
        errorService.showError(networkError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.activeErrors.length, equals(2));

        // Simulate app restart
        await errorStore.persistCriticalErrors();
        errorStore.clearAllErrors();
        await errorStore.restorePersistedErrors();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Temporary errors should not be restored
        expect(errorStore.hasErrors, isFalse);
        verify(mockLocalStorage.saveError(any)).never();
      });

      test('should handle app backgrounding and foregrounding', () async {
        // Arrange
        final backgroundError = ApiError(
          message: 'Background sync error',
          statusCode: 408,
          endpoint: '/api/sync',
          method: 'POST',
          occurredInBackground: true,
        );

        // Act - App goes to background
        errorStore.handleAppLifecycleChange(AppLifecycleState.paused);
        
        // Error occurs while in background
        errorService.showError(backgroundError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.backgroundErrors.length, equals(1));

        // App comes to foreground
        errorStore.handleAppLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Background errors should be promoted to active
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.backgroundErrors.isEmpty, isTrue);
        
        final error = errorStore.activeErrors.first as ApiError;
        expect(error.occurredInBackground, isTrue);
        expect(error.wasPromotedFromBackground, isTrue);
      });

      test('should manage error queue during app state changes', () async {
        // Arrange - Fill error queue
        final errors = List.generate(7, (index) => ApiError(
          message: 'Error $index',
          statusCode: 400 + index,
          endpoint: '/api/test$index',
          method: 'GET',
        ));

        for (final error in errors) {
          errorService.showError(error);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        expect(errorStore.activeErrors.length, equals(5)); // Max queue size

        // Act - App goes to background
        errorStore.handleAppLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error queue should be preserved
        expect(errorStore.activeErrors.length, equals(5));
        expect(errorStore.queueOverflowCount, equals(2));

        // App resumes
        errorStore.handleAppLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 100));

        // Queue should still be intact
        expect(errorStore.activeErrors.length, equals(5));
      });
    });

    group('Session Persistence', () {
      test('should maintain error state during session changes', () async {
        // Arrange
        final sessionError = ApiError(
          message: 'Session-related error',
          statusCode: 401,
          endpoint: '/api/user-data',
          method: 'GET',
          sessionId: 'session-123',
        );

        when(mockNavigationService.getCurrentSession())
            .thenReturn('session-123');

        // Act - Add error for current session
        errorService.showError(sessionError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Session changes (e.g., user switches accounts)
        when(mockNavigationService.getCurrentSession())
            .thenReturn('session-456');

        errorStore.handleSessionChange('session-456', 'session-123');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Session-specific errors should be cleared
        expect(errorStore.hasErrors, isFalse);
        
        // But should be stored for potential restoration
        final sessionErrors = errorStore.getErrorsForSession('session-123');
        expect(sessionErrors.length, equals(1));
        expect(sessionErrors.first, equals(sessionError));
      });

      test('should restore session errors when switching back', () async {
        // Arrange
        final session1Error = ApiError(
          message: 'Session 1 error',
          statusCode: 400,
          endpoint: '/api/session1-data',
          method: 'GET',
          sessionId: 'session-1',
        );

        final session2Error = ApiError(
          message: 'Session 2 error',
          statusCode: 500,
          endpoint: '/api/session2-data',
          method: 'GET',
          sessionId: 'session-2',
        );

        // Act - Add errors for different sessions
        when(mockNavigationService.getCurrentSession())
            .thenReturn('session-1');
        errorService.showError(session1Error);
        await Future.delayed(const Duration(milliseconds: 100));

        // Switch to session 2
        when(mockNavigationService.getCurrentSession())
            .thenReturn('session-2');
        errorStore.handleSessionChange('session-2', 'session-1');
        errorService.showError(session2Error);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.activeErrors.first, equals(session2Error));

        // Switch back to session 1
        when(mockNavigationService.getCurrentSession())
            .thenReturn('session-1');
        errorStore.handleSessionChange('session-1', 'session-2');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Session 1 errors should be restored
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.activeErrors.first, equals(session1Error));
      });
    });

    group('Error History and Recovery', () {
      test('should maintain error history for debugging', () async {
        // Arrange
        final errors = List.generate(60, (index) => ApiError(
          message: 'Historical error $index',
          statusCode: 400,
          endpoint: '/api/test$index',
          method: 'GET',
        ));

        // Act - Add errors over time
        for (final error in errors) {
          errorService.showError(error);
          await Future.delayed(const Duration(milliseconds: 5));
          errorService.clearError(error.id);
          await Future.delayed(const Duration(milliseconds: 5));
        }

        // Assert - Should maintain last 50 errors in history
        final history = errorStore.getErrorHistory();
        expect(history.length, equals(50));
        expect(history.first.message, equals('Historical error 59')); // Most recent first
        expect(history.last.message, equals('Historical error 10')); // Oldest kept
      });

      test('should support error recovery from history', () async {
        // Arrange
        final recoverableError = ApiError(
          message: 'Recoverable error',
          statusCode: 500,
          endpoint: '/api/recoverable',
          method: 'GET',
          isRecoverable: true,
        );

        // Act - Add and clear error
        errorService.showError(recoverableError);
        await Future.delayed(const Duration(milliseconds: 100));
        errorService.clearError(recoverableError.id);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isFalse);

        // Recover error from history
        final recovered = await errorStore.recoverErrorFromHistory(recoverableError.id);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error should be recovered
        expect(recovered, isTrue);
        expect(errorStore.hasErrors, isTrue);
        
        final recoveredError = errorStore.activeErrors.first as ApiError;
        expect(recoveredError.message, equals('Recoverable error'));
        expect(recoveredError.wasRecovered, isTrue);
        expect(recoveredError.recoveredAt, isNotNull);
      });

      test('should handle error state corruption recovery', () async {
        // Arrange - Simulate corrupted error state
        final validError = ApiError(
          message: 'Valid error',
          statusCode: 400,
          endpoint: '/api/valid',
          method: 'GET',
        );

        errorService.showError(validError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate state corruption
        errorStore.simulateStateCorruption();

        // Act - Attempt recovery
        final recoveryResult = await errorStore.recoverFromCorruption();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Should recover to clean state
        expect(recoveryResult.wasSuccessful, isTrue);
        expect(recoveryResult.errorsRecovered, equals(1));
        expect(recoveryResult.errorsLost, equals(0));
        
        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.isStateHealthy, isTrue);
      });
    });

    group('Memory Management', () {
      test('should clean up old error references', () async {
        // Arrange - Create many errors over time
        for (int i = 0; i < 100; i++) {
          final error = ApiError(
            message: 'Error $i',
            statusCode: 400,
            endpoint: '/api/test$i',
            method: 'GET',
          );
          
          errorService.showError(error);
          await Future.delayed(const Duration(milliseconds: 5));
          
          if (i % 10 == 0) {
            // Clear some errors periodically
            errorService.clearError(error.id);
          }
        }

        // Act - Trigger cleanup
        await errorStore.performMemoryCleanup();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Memory usage should be optimized
        final memoryStats = errorStore.getMemoryStats();
        expect(memoryStats.activeErrorsCount, lessThanOrEqualTo(5)); // Max queue size
        expect(memoryStats.historyCount, lessThanOrEqualTo(50)); // Max history size
        expect(memoryStats.weakReferencesCleared, greaterThan(0));
      });

      test('should handle memory pressure gracefully', () async {
        // Arrange - Fill up error system
        for (int i = 0; i < 20; i++) {
          final error = ApiError(
            message: 'Memory pressure error $i',
            statusCode: 500,
            endpoint: '/api/test$i',
            method: 'GET',
          );
          errorService.showError(error);
        }

        // Act - Simulate memory pressure
        errorStore.handleMemoryPressure(MemoryPressureLevel.high);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Should reduce memory usage
        expect(errorStore.activeErrors.length, lessThanOrEqualTo(3)); // Reduced queue
        expect(errorStore.getErrorHistory().length, lessThanOrEqualTo(25)); // Reduced history
        
        final memoryStats = errorStore.getMemoryStats();
        expect(memoryStats.memoryPressureHandled, isTrue);
      });
    });
  });
}

// Mock classes for testing
class MockNavigationService extends Mock {
  String getCurrentRoute() => '/';
  Map<String, String> getRouteParameters() => {};
  List<String> getBreadcrumb() => [];
  String getCurrentSession() => 'default-session';
}

class MockRouteObserver extends Mock {}

class MockLocalStorage extends Mock {
  Future<bool> saveError(Map<String, dynamic> errorData) async => true;
  Future<List<Map<String, dynamic>>> loadPersistedErrors() async => [];
}

// Extensions and additional classes for testing
extension ApiErrorTestExtensions on ApiError {
  bool get isGlobal => metadata?['isGlobal'] ?? false;
  bool get persistAcrossNavigation => metadata?['persistAcrossNavigation'] ?? false;
  bool get persistAcrossRestarts => metadata?['persistAcrossRestarts'] ?? false;
  bool get occurredInBackground => metadata?['occurredInBackground'] ?? false;
  bool get wasPromotedFromBackground => metadata?['wasPromotedFromBackground'] ?? false;
  String? get sessionId => metadata?['sessionId'];
  String? get currentRoute => metadata?['currentRoute'];
  Map<String, dynamic>? get navigationContext => metadata?['navigationContext'];
  bool get isRecoverable => metadata?['isRecoverable'] ?? false;
  bool get wasRecovered => metadata?['wasRecovered'] ?? false;
  DateTime? get recoveredAt => metadata?['recoveredAt'] != null 
      ? DateTime.parse(metadata!['recoveredAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'message': message,
    'statusCode': statusCode,
    'endpoint': endpoint,
    'method': method,
    'severity': severity.toString(),
    'metadata': metadata,
  };
}

extension ValidationErrorTestExtensions on ValidationError {
  bool get isRouteSpecific => metadata?['isRouteSpecific'] ?? false;
  String? get routePattern => metadata?['routePattern'];
  bool get isTemporary => metadata?['isTemporary'] ?? false;
}

extension ClientErrorTestExtensions on ClientError {
  List<String>? get navigationBreadcrumb => metadata?['navigationBreadcrumb']?.cast<String>();
  
  bool isAccessibleFromRoute(String route) {
    final breadcrumb = navigationBreadcrumb;
    return breadcrumb?.contains(route) ?? false;
  }
}

extension NetworkErrorTestExtensions on NetworkError {
  bool get isTemporary => metadata?['isTemporary'] ?? true;
}

extension ErrorStoreTestExtensions on ErrorStore {
  List<dynamic> get backgroundErrors => [];
  int get queueOverflowCount => 0;
  bool get isStateHealthy => true;
  
  void handleRouteChange(String newRoute, String oldRoute) {}
  void handleAppLifecycleChange(AppLifecycleState state) {}
  void handleSessionChange(String newSession, String oldSession) {}
  List<dynamic> getErrorsForSession(String sessionId) => [];
  List<dynamic> getErrorHistory() => [];
  Future<bool> recoverErrorFromHistory(String errorId) async => false;
  Future<void> persistCriticalErrors() async {}
  Future<void> restorePersistedErrors() async {}
  void simulateStateCorruption() {}
  Future<RecoveryResult> recoverFromCorruption() async => RecoveryResult(
    wasSuccessful: true,
    errorsRecovered: 0,
    errorsLost: 0,
  );
  Future<void> performMemoryCleanup() async {}
  void handleMemoryPressure(MemoryPressureLevel level) {}
  MemoryStats getMemoryStats() => MemoryStats(
    activeErrorsCount: 0,
    historyCount: 0,
    weakReferencesCleared: 0,
    memoryPressureHandled: false,
  );
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum NetworkErrorType {
  timeout,
  noConnection,
  serverError,
}

enum MemoryPressureLevel {
  low,
  medium,
  high,
  critical,
}

class RecoveryResult {
  final bool wasSuccessful;
  final int errorsRecovered;
  final int errorsLost;

  RecoveryResult({
    required this.wasSuccessful,
    required this.errorsRecovered,
    required this.errorsLost,
  });
}

class MemoryStats {
  final int activeErrorsCount;
  final int historyCount;
  final int weakReferencesCleared;
  final bool memoryPressureHandled;

  MemoryStats({
    required this.activeErrorsCount,
    required this.historyCount,
    required this.weakReferencesCleared,
    required this.memoryPressureHandled,
  });
}