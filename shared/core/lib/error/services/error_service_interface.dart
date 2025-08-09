import '../models/api_error.dart';
import '../models/app_error.dart';
import '../models/client_error.dart';
import '../models/network_error.dart';
import '../models/validation_error.dart';

/// Interface for the error service that manages application errors
abstract class IErrorService {
  /// Shows a generic application error
  void showError(AppError error);

  /// Shows an API-specific error
  void showApiError(ApiError error);

  /// Shows a validation error
  void showValidationError(ValidationError error);

  /// Shows a network connectivity error
  void showNetworkError(NetworkError error);

  /// Shows a client-side error
  void showClientError(ClientError error);

  /// Clears a specific error by its ID
  void clearError(String errorId);

  /// Clears all active errors
  void clearAllErrors();

  /// Clears all errors of a specific type
  void clearErrorsByType(String errorType);

  /// Returns a stream of all active errors
  Stream<List<AppError>> get errorStream;

  /// Returns a stream of the current priority error
  Stream<AppError?> get currentErrorStream;

  /// Returns whether there are any active errors
  bool get hasErrors;

  /// Returns the current list of active errors
  List<AppError> get activeErrors;

  /// Returns the current priority error (highest priority)
  AppError? get currentError;

  /// Disposes of the service and cleans up resources
  void dispose();
}