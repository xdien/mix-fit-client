import '../models/app_error.dart';
import '../models/api_error.dart';
import '../models/validation_error.dart';
import '../models/network_error.dart';
import '../models/client_error.dart';
import '../models/error_severity.dart';
import '../services/error_service_interface.dart';

/// Helper class for migrating existing error handling to the shared error system
class ErrorMigrationHelper {
  final IErrorService _errorService;

  ErrorMigrationHelper(this._errorService);

  /// Migrates a generic exception to the shared error system
  void migrateException(Exception exception, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final error = ClientError.withMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: exception.toString(),
      stackTrace: StackTrace.current.toString(),
      componentName: context,
      metadata: metadata ?? {},
    );
    _errorService.showError(error);
  }

  /// Migrates validation errors to the shared error system
  void migrateValidationErrors(Map<String, List<String>> fieldErrors, {
    String? formId,
    String? context,
  }) {
    final error = ValidationError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: 'Validation failed',
      fieldErrors: fieldErrors,
      formId: formId,
    );
    _errorService.showError(error);
  }

  /// Migrates network/connectivity errors to the shared error system
  void migrateNetworkError(String message, {
    String? url,
    Duration? timeout,
    NetworkErrorType? type,
  }) {
    final error = NetworkError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      networkType: type ?? NetworkErrorType.unknown,
      url: url,
      timeout: timeout,
    );
    _errorService.showError(error);
  }

  /// Migrates sync errors to the shared error system
  void migrateSyncError(String message, {
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final error = ClientError.withMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      stackTrace: StackTrace.current.toString(),
      componentName: 'SyncService',
      metadata: {
        if (details != null) 'details': details,
        ...?metadata ?? {},
      },
    );
    _errorService.showError(error);
  }

  /// Migrates customer-specific errors to the shared error system
  void migrateCustomerError(String message, {
    String? customerId,
    String? operation,
    Map<String, dynamic>? customerData,
  }) {
    final error = ClientError.withMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      stackTrace: StackTrace.current.toString(),
      componentName: 'CustomerManagement',
      metadata: {
        if (customerId != null) 'customerId': customerId,
        if (operation != null) 'operation': operation,
        if (customerData != null) 'customerData': customerData,
      },
    );
    _errorService.showError(error);
  }

  /// Migrates authentication errors to the shared error system
  void migrateAuthError(String message, {
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? requestData,
  }) {
    if (statusCode != null && endpoint != null) {
      final error = ApiError(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        statusCode: statusCode,
        endpoint: endpoint,
        method: 'POST', // Most auth operations are POST
        requestData: requestData,
      );
      _errorService.showError(error);
    } else {
      final error = ClientError.withMetadata(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        message: message,
        stackTrace: StackTrace.current.toString(),
        componentName: 'Authentication',
        metadata: requestData ?? {},
      );
      _errorService.showError(error);
    }
  }

  /// Migrates websocket errors to the shared error system
  void migrateWebSocketError(String message, {
    String? channel,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final error = NetworkError.withMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      networkType: NetworkErrorType.websocket,
      metadata: {
        if (channel != null) 'channel': channel,
        if (operation != null) 'operation': operation,
        ...metadata ?? {},
      },
    );
    _errorService.showError(error);
  }

  /// Helper method to replace direct error store usage
  void replaceErrorStoreUsage(String errorMessage, {
    String? context,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final error = ClientError(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: errorMessage,
      stackTrace: StackTrace.current.toString(),
      componentName: context,
    );
    _errorService.showError(error);
  }
}