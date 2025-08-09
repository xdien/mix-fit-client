import 'package:flutter_test/flutter_test.dart';
import '../lib/error/error_system.dart';

void main() {
  group('Error System Foundation Tests', () {
    test('should create API error with correct properties', () {
      final error = ApiError(
        message: 'Server error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
      );

      expect(error.message, equals('Server error'));
      expect(error.statusCode, equals(500));
      expect(error.endpoint, equals('/api/test'));
      expect(error.method, equals('GET'));
      expect(error.severity, equals(ErrorSeverity.critical));
      expect(error.type, equals(ErrorType.api));
      expect(error.isServerError, isTrue);
      expect(error.isRetryable, isTrue);
    });

    test('should create network error with correct properties', () {
      final error = NetworkError(
        message: 'No connection',
        networkType: NetworkErrorType.noConnection,
      );

      expect(error.message, equals('No connection'));
      expect(error.networkType, equals(NetworkErrorType.noConnection));
      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.type, equals(ErrorType.network));
      expect(error.isOffline, isTrue);
      expect(error.isRetryable, isTrue);
    });

    test('should create validation error with field errors', () {
      final fieldErrors = {
        'email': ['Invalid email format'],
        'password': ['Password too short', 'Password must contain numbers'],
      };

      final error = ValidationError(
        message: 'Validation failed',
        fieldErrors: fieldErrors,
        formId: 'login_form',
      );

      expect(error.message, equals('Validation failed'));
      expect(error.fieldErrors, equals(fieldErrors));
      expect(error.formId, equals('login_form'));
      expect(error.errorCount, equals(3));
      expect(error.hasFieldError('email'), isTrue);
      expect(error.hasFieldError('username'), isFalse);
      expect(error.getFirstFieldError('email'), equals('Invalid email format'));
    });

    test('should create client error with stack trace', () {
      final error = ClientError(
        message: 'Null pointer exception',
        stackTrace: 'Stack trace line 1\nStack trace line 2',
        componentName: 'UserService',
        context: 'During user login',
      );

      expect(error.message, equals('Null pointer exception'));
      expect(error.stackTrace, contains('Stack trace line 1'));
      expect(error.componentName, equals('UserService'));
      expect(error.context, equals('During user login'));
      expect(error.hasStackTrace, isTrue);
      expect(error.hasComponentContext, isTrue);
    });

    test('should create error actions with correct properties', () {
      var actionTriggered = false;
      final action = ErrorAction(
        id: 'test_action',
        label: 'Test Action',
        icon: null,
        onPressed: () => actionTriggered = true,
        isPrimary: true,
      );

      expect(action.id, equals('test_action'));
      expect(action.label, equals('Test Action'));
      expect(action.isPrimary, isTrue);
      expect(actionTriggered, isFalse);

      action.onPressed();
      expect(actionTriggered, isTrue);
    });

    test('should create network status with correct properties', () {
      final status = NetworkStatus(
        isConnected: true,
        quality: NetworkQuality.good,
        latency: const Duration(milliseconds: 100),
      );

      expect(status.isConnected, isTrue);
      expect(status.quality, equals(NetworkQuality.good));
      expect(status.latency?.inMilliseconds, equals(100));
      expect(status.isGoodEnough, isTrue);
      expect(status.isOffline, isFalse);
    });

    test('should create offline network status', () {
      final status = NetworkStatus.offline();

      expect(status.isConnected, isFalse);
      expect(status.quality, equals(NetworkQuality.offline));
      expect(status.isOffline, isTrue);
      expect(status.isGoodEnough, isFalse);
    });

    test('should use error factory to create common errors', () {
      final noInternetError = ErrorFactory.createNoInternetError();
      expect(noInternetError.networkType, equals(NetworkErrorType.noConnection));
      expect(noInternetError.message, equals('No internet connection available'));

      final timeoutError = ErrorFactory.createTimeoutError();
      expect(timeoutError.networkType, equals(NetworkErrorType.timeout));
      expect(timeoutError.message, equals('Request timed out'));

      final authError = ErrorFactory.createAuthenticationError();
      expect(authError.statusCode, equals(401));
      expect(authError.message, equals('Authentication failed'));
    });

    test('should handle error severity priorities correctly', () {
      expect(ErrorSeverity.critical.priority, greaterThan(ErrorSeverity.error.priority));
      expect(ErrorSeverity.error.priority, greaterThan(ErrorSeverity.warning.priority));
      expect(ErrorSeverity.warning.priority, greaterThan(ErrorSeverity.info.priority));

      expect(ErrorSeverity.info.shouldAutoDismiss, isTrue);
      expect(ErrorSeverity.critical.shouldAutoDismiss, isFalse);
    });

    test('should handle network quality priorities correctly', () {
      expect(NetworkQuality.excellent.priority, greaterThan(NetworkQuality.good.priority));
      expect(NetworkQuality.good.priority, greaterThan(NetworkQuality.fair.priority));
      expect(NetworkQuality.fair.priority, greaterThan(NetworkQuality.poor.priority));
      expect(NetworkQuality.poor.priority, greaterThan(NetworkQuality.offline.priority));

      expect(NetworkQuality.excellent.isGoodEnough, isTrue);
      expect(NetworkQuality.good.isGoodEnough, isTrue);
      expect(NetworkQuality.fair.isGoodEnough, isFalse);
      expect(NetworkQuality.offline.isOnline, isFalse);
    });
  });
}