import 'package:flutter/material.dart';

import '../localization/error_localizations.dart';
import '../models/api_error.dart';
import '../models/app_error.dart';
import '../models/client_error.dart';
import '../models/error_action.dart';
import '../models/network_error.dart';
import '../models/validation_error.dart';
import 'error_factory.dart';

/// Factory for creating localized errors
class LocalizedErrorFactory {
  final ErrorLocalizations _localizations;

  LocalizedErrorFactory(this._localizations);

  /// Creates a localized error factory from context
  factory LocalizedErrorFactory.fromContext(BuildContext context) {
    return LocalizedErrorFactory(ErrorLocalizations.of(context));
  }

  /// Creates a localized error factory for a specific locale
  factory LocalizedErrorFactory.forLocale(Locale locale) {
    return LocalizedErrorFactory(ErrorLocalizations.forLocale(locale));
  }

  /// Creates a localized API error
  ApiError createApiError({
    required int statusCode,
    required String endpoint,
    required String method,
    String? message,
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.getHttpStatusMessage(statusCode);
    final localizedActions = actions ?? _createLocalizedApiActions(statusCode);

    return ErrorFactory.createApiError(
      statusCode: statusCode,
      endpoint: endpoint,
      method: method,
      message: localizedMessage,
      requestData: requestData,
      responseData: responseData,
      actions: localizedActions,
    );
  }

  /// Creates a localized network error
  NetworkError createNetworkError({
    required NetworkErrorType networkType,
    String? message,
    Duration? timeout,
    String? url,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.getNetworkErrorMessage(networkType);
    final localizedActions = actions ?? _createLocalizedNetworkActions(networkType);

    return ErrorFactory.createNetworkError(
      networkType: networkType,
      message: localizedMessage,
      timeout: timeout,
      url: url,
      actions: localizedActions,
    );
  }

  /// Creates a localized validation error
  ValidationError createValidationError({
    required Map<String, List<String>> fieldErrors,
    String? message,
    String? formId,
    List<ErrorAction>? actions,
  }) {
    final errorCount = fieldErrors.values.fold<int>(0, (sum, errors) => sum + errors.length);
    final localizedMessage = message ?? _localizations.getValidationErrorCount(errorCount);

    return ErrorFactory.createValidationError(
      fieldErrors: fieldErrors,
      message: localizedMessage,
      formId: formId,
      actions: actions,
    );
  }

  /// Creates a localized client error
  ClientError createClientError({
    required String message,
    String? stackTrace,
    String? componentName,
    String? context,
    List<ErrorAction>? actions,
  }) {
    return ErrorFactory.createClientError(
      message: message,
      stackTrace: stackTrace,
      componentName: componentName,
      context: context,
      actions: actions,
    );
  }

  /// Creates a localized no internet error
  NetworkError createNoInternetError({
    List<ErrorAction>? actions,
  }) {
    final localizedActions = actions ?? [
      _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createNetworkError(
      networkType: NetworkErrorType.noConnection,
      actions: localizedActions,
    );
  }

  /// Creates a localized timeout error
  NetworkError createTimeoutError({
    Duration? timeout,
    String? url,
    List<ErrorAction>? actions,
  }) {
    final localizedActions = actions ?? [
      _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createNetworkError(
      networkType: NetworkErrorType.timeout,
      timeout: timeout,
      url: url,
      actions: localizedActions,
    );
  }

  /// Creates a localized authentication error
  ApiError createAuthenticationError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.unauthorized;
    final localizedActions = actions ?? [
      _createLocalizedAction('login', _localizations.login, Icons.login, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createApiError(
      statusCode: 401,
      endpoint: '/auth',
      method: 'POST',
      message: localizedMessage,
      actions: localizedActions,
    );
  }

  /// Creates a localized authorization error
  ApiError createAuthorizationError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.forbidden;
    final localizedActions = actions ?? [
      _createLocalizedAction('contact_support', _localizations.contactSupport, Icons.support_agent, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createApiError(
      statusCode: 403,
      endpoint: '/api',
      method: 'GET',
      message: localizedMessage,
      actions: localizedActions,
    );
  }

  /// Creates a localized maintenance error
  ApiError createMaintenanceError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.getMaintenanceMessage();
    final localizedActions = actions ?? [
      _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createApiError(
      statusCode: 503,
      endpoint: '/api',
      method: 'GET',
      message: localizedMessage,
      actions: localizedActions,
    );
  }

  /// Creates a localized rate limit error
  ApiError createRateLimitError({
    String? message,
    Duration? retryAfter,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? (retryAfter != null
        ? _localizations.getRetryAfterMessage(retryAfter)
        : _localizations.tooManyRequests);

    final localizedActions = actions ?? [
      _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createApiError(
      statusCode: 429,
      endpoint: '/api',
      method: 'GET',
      message: localizedMessage,
      actions: localizedActions,
    );
  }

  /// Creates a localized data corruption error
  ClientError createDataCorruptionError({
    String? message,
    String? componentName,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.getDataCorruptionMessage();
    final localizedActions = actions ?? [
      _createLocalizedAction('refresh', _localizations.refresh, Icons.refresh, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createClientError(
      message: localizedMessage,
      stackTrace: StackTrace.current.toString(),
      componentName: componentName,
      context: 'data_corruption',
      actions: localizedActions,
    );
  }

  /// Creates a localized permission error
  ClientError createPermissionError({
    String? message,
    String? permission,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? (permission != null
        ? _localizations.getPermissionDeniedMessage(permission)
        : _localizations.getPermissionDeniedMessage('unknown'));

    final localizedActions = actions ?? [
      _createLocalizedAction('settings', _localizations.openSettings, Icons.settings, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createClientError(
      message: localizedMessage,
      stackTrace: StackTrace.current.toString(),
      context: 'permission_denied',
      actions: localizedActions,
    );
  }

  /// Creates a localized storage full error
  ClientError createStorageFullError({
    String? message,
    List<ErrorAction>? actions,
  }) {
    final localizedMessage = message ?? _localizations.getStorageFullMessage();
    final localizedActions = actions ?? [
      _createLocalizedAction('manage_storage', _localizations.manageStorage, Icons.storage, () {}),
      _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
    ];

    return createClientError(
      message: localizedMessage,
      stackTrace: StackTrace.current.toString(),
      context: 'storage_full',
      actions: localizedActions,
    );
  }

  /// Creates localized validation field errors
  Map<String, List<String>> createLocalizedFieldErrors({
    Map<String, List<String>>? customErrors,
    bool emailRequired = false,
    bool emailInvalid = false,
    bool phoneRequired = false,
    bool phoneInvalid = false,
    bool passwordRequired = false,
    bool passwordTooShort = false,
    bool passwordTooWeak = false,
    bool passwordsDoNotMatch = false,
    bool urlInvalid = false,
    bool dateInvalid = false,
    bool valueTooSmall = false,
    bool valueTooLarge = false,
  }) {
    final errors = <String, List<String>>{};

    // Add custom errors first
    if (customErrors != null) {
      errors.addAll(customErrors);
    }

    // Add standard validation errors
    if (emailRequired) {
      errors['email'] = [...(errors['email'] ?? []), _localizations.fieldRequired];
    }
    if (emailInvalid) {
      errors['email'] = [...(errors['email'] ?? []), _localizations.invalidEmail];
    }

    if (phoneRequired) {
      errors['phone'] = [...(errors['phone'] ?? []), _localizations.fieldRequired];
    }
    if (phoneInvalid) {
      errors['phone'] = [...(errors['phone'] ?? []), _localizations.invalidPhoneNumber];
    }

    if (passwordRequired) {
      errors['password'] = [...(errors['password'] ?? []), _localizations.fieldRequired];
    }
    if (passwordTooShort) {
      errors['password'] = [...(errors['password'] ?? []), _localizations.passwordTooShort];
    }
    if (passwordTooWeak) {
      errors['password'] = [...(errors['password'] ?? []), _localizations.passwordTooWeak];
    }

    if (passwordsDoNotMatch) {
      errors['confirmPassword'] = [...(errors['confirmPassword'] ?? []), _localizations.passwordsDoNotMatch];
    }

    if (urlInvalid) {
      errors['url'] = [...(errors['url'] ?? []), _localizations.invalidUrl];
    }

    if (dateInvalid) {
      errors['date'] = [...(errors['date'] ?? []), _localizations.invalidDate];
    }

    if (valueTooSmall) {
      errors['value'] = [...(errors['value'] ?? []), _localizations.valueTooSmall];
    }

    if (valueTooLarge) {
      errors['value'] = [...(errors['value'] ?? []), _localizations.valueTooLarge];
    }

    return errors;
  }

  // Private helper methods

  List<ErrorAction> _createLocalizedApiActions(int statusCode) {
    if (statusCode >= 500 || statusCode == 408 || statusCode == 429) {
      return [
        _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    } else if (statusCode == 401) {
      return [
        _createLocalizedAction('login', _localizations.login, Icons.login, () {}),
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    } else if (statusCode == 403) {
      return [
        _createLocalizedAction('contact_support', _localizations.contactSupport, Icons.support_agent, () {}),
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    } else {
      return [
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    }
  }

  List<ErrorAction> _createLocalizedNetworkActions(NetworkErrorType networkType) {
    if (networkType.isRetryable) {
      return [
        _createLocalizedAction('retry', _localizations.retry, Icons.refresh, () {}),
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    } else {
      return [
        _createLocalizedAction('contact_support', _localizations.contactSupport, Icons.support_agent, () {}),
        _createLocalizedAction('dismiss', _localizations.dismiss, Icons.close, () {}),
      ];
    }
  }

  ErrorAction _createLocalizedAction(
    String id,
    String label,
    IconData? icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    return ErrorAction(
      id: id,
      label: label,
      icon: icon,
      onPressed: onPressed,
      isPrimary: isPrimary,
      isDestructive: isDestructive,
    );
  }
}