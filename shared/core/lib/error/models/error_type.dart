/// Defines the different types of errors that can occur in the application
enum ErrorType {
  /// API-related errors (HTTP requests, server responses)
  api,
  
  /// Network connectivity errors
  network,
  
  /// Data validation errors
  validation,
  
  /// Authentication errors (login, token expiration)
  authentication,
  
  /// Authorization errors (insufficient permissions)
  authorization,
  
  /// Client-side errors (app crashes, unexpected states)
  client,
  
  /// Server-side errors (500 errors, service unavailable)
  server,
  
  /// Offline mode errors
  offline;

  /// Returns whether this error type typically requires user action
  bool get requiresUserAction {
    switch (this) {
      case ErrorType.api:
      case ErrorType.network:
      case ErrorType.authentication:
      case ErrorType.server:
        return true;
      case ErrorType.validation:
      case ErrorType.authorization:
      case ErrorType.client:
      case ErrorType.offline:
        return false;
    }
  }

  /// Returns whether this error type should be logged for debugging
  bool get shouldLog {
    switch (this) {
      case ErrorType.client:
      case ErrorType.server:
      case ErrorType.api:
        return true;
      case ErrorType.network:
      case ErrorType.validation:
      case ErrorType.authentication:
      case ErrorType.authorization:
      case ErrorType.offline:
        return false;
    }
  }
}