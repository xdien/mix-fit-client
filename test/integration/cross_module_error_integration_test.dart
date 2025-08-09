import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/client_error.dart';
import 'package:core/di/error_module.dart';

// Mock modules for testing
@GenerateMocks([
  CustomerModule,
  AuthModule,
  WebSocketService,
  NavigationService,
])
void main() {
  group('Cross-Module Error Integration Tests', () {
    late GetIt getIt;
    late IErrorService errorService;
    late ErrorStore errorStore;
    late MockCustomerModule mockCustomerModule;
    late MockAuthModule mockAuthModule;
    late MockWebSocketService mockWebSocketService;
    late MockNavigationService mockNavigationService;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      // Initialize mocks
      mockCustomerModule = MockCustomerModule();
      mockAuthModule = MockAuthModule();
      mockWebSocketService = MockWebSocketService();
      mockNavigationService = MockNavigationService();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      // Register mocks
      getIt.registerSingleton<CustomerModule>(mockCustomerModule);
      getIt.registerSingleton<AuthModule>(mockAuthModule);
      getIt.registerSingleton<WebSocketService>(mockWebSocketService);
      getIt.registerSingleton<NavigationService>(mockNavigationService);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('Customer Module Integration', () {
      test('should handle customer API errors from customer module', () async {
        // Arrange
        when(mockCustomerModule.createCustomer(any))
            .thenThrow(ApiError(
              message: 'Customer validation failed',
              statusCode: 422,
              endpoint: '/api/customers',
              method: 'POST',
              responseData: {
                'errors': {
                  'email': ['Email already exists'],
                  'phone': ['Invalid phone format'],
                }
              },
            ));

        // Act - Simulate customer module calling error service
        try {
          await mockCustomerModule.createCustomer({'email': 'test@test.com'});
        } catch (error) {
          if (error is ApiError) {
            errorService.showError(error);
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final capturedError = errorStore.activeErrors.first as ApiError;
        expect(capturedError.statusCode, equals(422));
        expect(capturedError.endpoint, equals('/api/customers'));
        expect(capturedError.responseData?['errors'], isNotNull);
      });

      test('should handle customer module validation errors', () async {
        // Arrange
        final validationError = ValidationError(
          message: 'Customer form validation failed',
          fieldErrors: {
            'name': ['Name is required'],
            'email': ['Invalid email format'],
            'address': ['Address is too short'],
          },
          formId: 'customer-form',
          moduleId: 'customer',
        );

        // Act
        errorService.showError(validationError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as ValidationError;
        expect(error.moduleId, equals('customer'));
        expect(error.formId, equals('customer-form'));
        expect(error.fieldErrors.keys.length, equals(3));
      });

      test('should integrate customer errors with navigation context', () async {
        // Arrange
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/create');
        when(mockNavigationService.getRouteContext())
            .thenReturn({'module': 'customer', 'action': 'create'});

        final customerError = ApiError(
          message: 'Failed to create customer',
          statusCode: 500,
          endpoint: '/api/customers',
          method: 'POST',
        );

        // Act
        errorService.showError(customerError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as ApiError;
        expect(error.navigationContext, isNotNull);
        expect(error.navigationContext?['module'], equals('customer'));
        expect(error.navigationContext?['action'], equals('create'));
      });
    });

    group('Authentication Module Integration', () {
      test('should handle auth errors and trigger re-authentication', () async {
        // Arrange
        final authError = ApiError(
          message: 'Authentication token expired',
          statusCode: 401,
          endpoint: '/api/protected-resource',
          method: 'GET',
          errorType: ApiErrorType.authentication,
        );

        when(mockAuthModule.refreshToken())
            .thenAnswer((_) async => true);

        // Act
        errorService.showError(authError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Execute re-auth action
        final reAuthAction = authError.actions!.firstWhere(
          (action) => action.id == 'reauth',
        );
        
        await reAuthAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockAuthModule.refreshToken()).called(1);
        expect(errorStore.hasErrors, isFalse); // Should be cleared after successful re-auth
      });

      test('should handle auth module logout on critical auth errors', () async {
        // Arrange
        final criticalAuthError = ApiError(
          message: 'Invalid credentials',
          statusCode: 401,
          endpoint: '/api/login',
          method: 'POST',
          errorType: ApiErrorType.authentication,
          severity: ErrorSeverity.critical,
        );

        when(mockAuthModule.logout())
            .thenAnswer((_) async => {});
        when(mockNavigationService.navigateToLogin())
            .thenAnswer((_) async => {});

        // Act
        errorService.showError(criticalAuthError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Should trigger automatic logout for critical auth errors
        final logoutAction = criticalAuthError.actions!.firstWhere(
          (action) => action.id == 'logout',
        );
        
        await logoutAction.onPressed();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockAuthModule.logout()).called(1);
        verify(mockNavigationService.navigateToLogin()).called(1);
      });

      test('should propagate auth state changes to error store', () async {
        // Arrange
        when(mockAuthModule.authStateStream)
            .thenAnswer((_) => Stream.fromIterable([
              AuthState.authenticated,
              AuthState.unauthenticated,
              AuthState.authenticated,
            ]));

        // Act - Listen to auth state changes
        final authStates = <AuthState>[];
        mockAuthModule.authStateStream.listen((state) {
          authStates.add(state);
          errorStore.updateAuthState(state);
        });

        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(authStates.length, equals(3));
        expect(errorStore.currentAuthState, equals(AuthState.authenticated));
        
        // Auth-related errors should be cleared when authenticated
        expect(errorStore.hasAuthenticationErrors, isFalse);
      });
    });

    group('WebSocket Service Integration', () {
      test('should handle WebSocket connection errors', () async {
        // Arrange
        final wsError = ClientError(
          message: 'WebSocket connection failed',
          stackTrace: 'WebSocket error stack trace',
          componentName: 'WebSocketService',
          errorCode: 'WS_CONNECTION_FAILED',
        );

        when(mockWebSocketService.connectionState)
            .thenReturn(WebSocketState.disconnected);

        // Act
        errorService.showError(wsError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        final error = errorStore.activeErrors.first as ClientError;
        expect(error.componentName, equals('WebSocketService'));
        expect(error.errorCode, equals('WS_CONNECTION_FAILED'));
        
        // Should have reconnect action
        final reconnectAction = error.actions!.firstWhere(
          (action) => action.id == 'reconnect',
        );
        expect(reconnectAction.label, equals('Reconnect'));
      });

      test('should integrate WebSocket errors with network status', () async {
        // Arrange
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        final wsError = ClientError(
          message: 'WebSocket disconnected due to network issues',
          componentName: 'WebSocketService',
          errorCode: 'WS_NETWORK_ERROR',
        );

        // Act
        errorService.showError(wsError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.hasErrors, isTrue);
        expect(errorStore.isOffline, isTrue);
        
        // WebSocket error should be correlated with network status
        final error = errorStore.activeErrors.first as ClientError;
        expect(error.isNetworkRelated, isTrue);
        
        // Reconnect action should be disabled while offline
        final reconnectAction = error.actions!.firstWhere(
          (action) => action.id == 'reconnect',
        );
        expect(reconnectAction.isEnabled, isFalse);
      });

      test('should handle WebSocket reconnection on network recovery', () async {
        // Arrange - Start with WebSocket error due to network issues
        final wsError = ClientError(
          message: 'WebSocket connection lost',
          componentName: 'WebSocketService',
          errorCode: 'WS_CONNECTION_LOST',
          isNetworkRelated: true,
        );

        errorService.showError(wsError);
        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: false,
          quality: NetworkQuality.offline,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));
        expect(errorStore.hasErrors, isTrue);

        // Act - Network comes back online
        when(mockWebSocketService.reconnect())
            .thenAnswer((_) async => true);

        errorStore.updateNetworkStatus(NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.good,
          lastChecked: DateTime.now(),
        ));

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - WebSocket should auto-reconnect
        verify(mockWebSocketService.reconnect()).called(1);
        
        // Network-related WebSocket errors should be cleared
        final remainingWsErrors = errorStore.activeErrors
            .where((error) => error is ClientError && 
                   (error as ClientError).componentName == 'WebSocketService' &&
                   error.isNetworkRelated)
            .toList();
        expect(remainingWsErrors.isEmpty, isTrue);
      });
    });

    group('Navigation Integration', () {
      test('should preserve error context during navigation', () async {
        // Arrange
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/list');

        final error = ApiError(
          message: 'Failed to load customers',
          statusCode: 500,
          endpoint: '/api/customers',
          method: 'GET',
        );

        errorService.showError(error);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.hasErrors, isTrue);

        // Act - Navigate to different route
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/customers/create');

        errorStore.updateNavigationContext('/customers/create');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error should still be present with updated context
        expect(errorStore.hasErrors, isTrue);
        final persistedError = errorStore.activeErrors.first as ApiError;
        expect(persistedError.currentRoute, equals('/customers/create'));
        expect(persistedError.originalRoute, equals('/customers/list'));
      });

      test('should clear route-specific errors on navigation', () async {
        // Arrange
        final routeSpecificError = ValidationError(
          message: 'Form validation failed',
          fieldErrors: {'field': ['error']},
          formId: 'customer-form',
          isRouteSpecific: true,
          route: '/customers/create',
        );

        final globalError = ApiError(
          message: 'Global API error',
          statusCode: 500,
          endpoint: '/api/global',
          method: 'GET',
          isRouteSpecific: false,
        );

        errorService.showError(routeSpecificError);
        errorService.showError(globalError);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(errorStore.activeErrors.length, equals(2));

        // Act - Navigate away from the route
        when(mockNavigationService.getCurrentRoute())
            .thenReturn('/dashboard');

        errorStore.updateNavigationContext('/dashboard');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Route-specific error should be cleared, global error should remain
        expect(errorStore.activeErrors.length, equals(1));
        expect(errorStore.activeErrors.first, equals(globalError));
      });
    });

    group('Module Error Coordination', () {
      test('should coordinate errors across multiple modules', () async {
        // Arrange - Errors from different modules
        final customerError = ApiError(
          message: 'Customer API error',
          statusCode: 400,
          endpoint: '/api/customers',
          method: 'POST',
          moduleId: 'customer',
        );

        final authError = ApiError(
          message: 'Auth token expired',
          statusCode: 401,
          endpoint: '/api/auth/refresh',
          method: 'POST',
          moduleId: 'auth',
        );

        final wsError = ClientError(
          message: 'WebSocket error',
          componentName: 'WebSocketService',
          moduleId: 'websocket',
        );

        // Act
        errorService.showError(customerError);
        errorService.showError(authError);
        errorService.showError(wsError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.activeErrors.length, equals(3));
        
        // Should prioritize auth errors
        expect(errorStore.priorityError, equals(authError));
        
        // Should group errors by module
        final errorsByModule = errorStore.getErrorsByModule();
        expect(errorsByModule['customer']?.length, equals(1));
        expect(errorsByModule['auth']?.length, equals(1));
        expect(errorsByModule['websocket']?.length, equals(1));
      });

      test('should handle cascading errors across modules', () async {
        // Arrange - Auth error that causes other modules to fail
        final authError = ApiError(
          message: 'Authentication failed',
          statusCode: 401,
          endpoint: '/api/auth/login',
          method: 'POST',
          moduleId: 'auth',
          severity: ErrorSeverity.critical,
        );

        // Act - Auth error triggers cascading failures
        errorService.showError(authError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Simulate cascading errors
        final customerError = ApiError(
          message: 'Unauthorized access to customers',
          statusCode: 401,
          endpoint: '/api/customers',
          method: 'GET',
          moduleId: 'customer',
          causedBy: authError.id,
        );

        final wsError = ClientError(
          message: 'WebSocket authentication failed',
          componentName: 'WebSocketService',
          moduleId: 'websocket',
          causedBy: authError.id,
        );

        errorService.showError(customerError);
        errorService.showError(wsError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(errorStore.activeErrors.length, equals(3));
        
        // Should identify cascading relationship
        final cascadingErrors = errorStore.getCascadingErrors(authError.id);
        expect(cascadingErrors.length, equals(2));
        expect(cascadingErrors, contains(customerError));
        expect(cascadingErrors, contains(wsError));
        
        // Resolving root cause should resolve cascading errors
        errorService.clearError(authError.id);
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(errorStore.activeErrors.isEmpty, isTrue);
      });
    });

    group('Error State Synchronization', () {
      test('should synchronize error states across modules', () async {
        // Arrange
        final sharedError = ApiError(
          message: 'Shared service error',
          statusCode: 503,
          endpoint: '/api/shared-service',
          method: 'GET',
          affectedModules: ['customer', 'auth', 'websocket'],
        );

        // Act
        errorService.showError(sharedError);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - All affected modules should be notified
        verify(mockCustomerModule.handleSharedError(sharedError)).called(1);
        verify(mockAuthModule.handleSharedError(sharedError)).called(1);
        verify(mockWebSocketService.handleSharedError(sharedError)).called(1);
        
        // Error should be marked as affecting multiple modules
        expect(errorStore.hasMultiModuleErrors, isTrue);
        final multiModuleErrors = errorStore.getMultiModuleErrors();
        expect(multiModuleErrors, contains(sharedError));
      });
    });
  });
}

// Mock classes and enums for testing
class MockCustomerModule extends Mock {
  Future<void> createCustomer(Map<String, dynamic> data) async {}
  void handleSharedError(ApiError error) {}
}

class MockAuthModule extends Mock {
  Future<bool> refreshToken() async => true;
  Future<void> logout() async {}
  void handleSharedError(ApiError error) {}
  Stream<AuthState> get authStateStream => Stream.empty();
}

class MockWebSocketService extends Mock {
  WebSocketState get connectionState => WebSocketState.connected;
  Future<bool> reconnect() async => true;
  void handleSharedError(ApiError error) {}
}

class MockNavigationService extends Mock {
  String getCurrentRoute() => '/';
  Map<String, dynamic> getRouteContext() => {};
  Future<void> navigateToLogin() async {}
}

enum AuthState {
  authenticated,
  unauthenticated,
  loading,
}

enum WebSocketState {
  connected,
  disconnected,
  connecting,
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

// Additional extensions for testing
extension ApiErrorExtensions on ApiError {
  String? get moduleId => metadata?['moduleId'];
  String? get causedBy => metadata?['causedBy'];
  List<String>? get affectedModules => metadata?['affectedModules']?.cast<String>();
  String? get currentRoute => metadata?['currentRoute'];
  String? get originalRoute => metadata?['originalRoute'];
  ApiErrorType? get errorType => metadata?['errorType'];
  Map<String, dynamic>? get navigationContext => metadata?['navigationContext'];
}

extension ValidationErrorExtensions on ValidationError {
  String? get moduleId => metadata?['moduleId'];
  bool get isRouteSpecific => metadata?['isRouteSpecific'] ?? false;
  String? get route => metadata?['route'];
}

extension ClientErrorExtensions on ClientError {
  String? get moduleId => metadata?['moduleId'];
  String? get errorCode => metadata?['errorCode'];
  bool get isNetworkRelated => metadata?['isNetworkRelated'] ?? false;
  String? get causedBy => metadata?['causedBy'];
}

extension ErrorStoreExtensions on ErrorStore {
  void updateAuthState(AuthState state) {}
  void updateNavigationContext(String route) {}
  bool get hasAuthenticationErrors => false;
  bool get hasConnectionStatusMessage => false;
  bool get shouldShowPoorConnectionWarning => false;
  bool get hasFieldValidationGuidance => false;
  Set<String> get highlightedFields => {};
  bool get hasProcessedQueuedActions => false;
  bool get hasMultiModuleErrors => false;
  AuthState get currentAuthState => AuthState.unauthenticated;
  List<QueuedAction> get queuedActions => [];
  Stream<NetworkQuality> get networkQualityStream => Stream.empty();
  Duration? get networkLatency => null;
  
  FieldGuidance? getFieldGuidance(String field) => null;
  List<String> getOfflineAvailableFeatures() => [];
  void queueOfflineAction(QueuedAction action) {}
  void clearFieldError(String field) {}
  ErrorResolutionHistory? getErrorResolutionHistory(String errorId) => null;
  ResolutionAnalytics getResolutionAnalytics() => ResolutionAnalytics(
    totalErrors: 0,
    resolvedErrors: 0,
    resolutionRate: 0.0,
    commonResolutionMethods: [],
  );
  Map<String, List<dynamic>> getErrorsByModule() => {};
  List<dynamic> getCascadingErrors(String rootErrorId) => [];
  List<dynamic> getMultiModuleErrors() => [];
}

class FieldGuidance {
  final List<String> errors;
  final String? suggestion;

  FieldGuidance({required this.errors, this.suggestion});
}

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

class NetworkStatus {
  final bool isConnected;
  final NetworkQuality quality;
  final Duration? latency;
  final DateTime lastChecked;

  NetworkStatus({
    required this.isConnected,
    required this.quality,
    this.latency,
    required this.lastChecked,
  });
}

enum NetworkQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}

enum ApiErrorType {
  authentication,
  authorization,
  validation,
  server,
  client,
}

class ErrorResolutionHistory {
  final int attempts;
  final DateTime? lastAttemptAt;
  final bool wasSuccessful;
  final String resolutionMethod;

  ErrorResolutionHistory({
    required this.attempts,
    this.lastAttemptAt,
    required this.wasSuccessful,
    required this.resolutionMethod,
  });
}

class ResolutionAnalytics {
  final int totalErrors;
  final int resolvedErrors;
  final double resolutionRate;
  final Duration? averageResolutionTime;
  final List<String> commonResolutionMethods;

  ResolutionAnalytics({
    required this.totalErrors,
    required this.resolvedErrors,
    required this.resolutionRate,
    this.averageResolutionTime,
    required this.commonResolutionMethods,
  });
}