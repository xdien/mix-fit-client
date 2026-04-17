import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/error_type.dart';
import '../models/network_error.dart';
import 'error_messages.dart';

/// Provides localized error messages and labels
class ErrorLocalizations {
  final Locale locale;
  final ErrorMessages _messages;

  ErrorLocalizations._(this.locale, this._messages);

  /// Creates ErrorLocalizations for the given locale
  static ErrorLocalizations of(BuildContext context) {
    return Localizations.of<ErrorLocalizations>(context, ErrorLocalizations) ??
        ErrorLocalizations._(const Locale('en'), ErrorMessages.en());
  }

  /// Creates ErrorLocalizations for a specific locale
  static ErrorLocalizations forLocale(Locale locale) {
    final messages = _getMessagesForLocale(locale);
    return ErrorLocalizations._(locale, messages);
  }

  /// Supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'), // English
    Locale('vi'), // Vietnamese
    Locale('es'), // Spanish
    Locale('fr'), // French
    Locale('de'), // German
    Locale('ja'), // Japanese
    Locale('ko'), // Korean
    Locale('zh'), // Chinese
    Locale('ar'), // Arabic
  ];

  /// Checks if a locale is supported
  static bool isSupported(Locale locale) {
    return supportedLocales.any((supported) => 
        supported.languageCode == locale.languageCode);
  }

  // Generic error messages
  String get unknownError => _messages.unknownError;
  String get networkError => _messages.networkError;
  String get serverError => _messages.serverError;
  String get clientError => _messages.clientError;
  String get validationError => _messages.validationError;

  // API error messages
  String get badRequest => _messages.badRequest;
  String get unauthorized => _messages.unauthorized;
  String get forbidden => _messages.forbidden;
  String get notFound => _messages.notFound;
  String get methodNotAllowed => _messages.methodNotAllowed;
  String get requestTimeout => _messages.requestTimeout;
  String get conflict => _messages.conflict;
  String get unprocessableEntity => _messages.unprocessableEntity;
  String get tooManyRequests => _messages.tooManyRequests;
  String get internalServerError => _messages.internalServerError;
  String get badGateway => _messages.badGateway;
  String get serviceUnavailable => _messages.serviceUnavailable;
  String get gatewayTimeout => _messages.gatewayTimeout;

  // Network error messages
  String get noConnection => _messages.noConnection;
  String get connectionTimeout => _messages.connectionTimeout;
  String get dnsFailure => _messages.dnsFailure;
  String get connectionRefused => _messages.connectionRefused;
  String get certificateError => _messages.certificateError;
  String get requestCancelled => _messages.requestCancelled;
  String get poorNetworkQuality => _messages.poorNetworkQuality;

  // Action labels
  String get retry => _messages.retry;
  String get dismiss => _messages.dismiss;
  String get details => _messages.details;
  String get login => _messages.login;
  String get contactSupport => _messages.contactSupport;
  String get refresh => _messages.refresh;
  String get openSettings => _messages.openSettings;
  String get manageStorage => _messages.manageStorage;
  String get tryAgain => _messages.tryAgain;
  String get cancel => _messages.cancel;
  String get ok => _messages.ok;

  // Network status messages
  String get online => _messages.online;
  String get offline => _messages.offline;
  String get connecting => _messages.connecting;
  String get connected => _messages.connected;
  String get disconnected => _messages.disconnected;
  String get reconnecting => _messages.reconnecting;
  String get connectionLost => _messages.connectionLost;
  String get connectionRestored => _messages.connectionRestored;

  // Network quality messages
  String get excellentConnection => _messages.excellentConnection;
  String get goodConnection => _messages.goodConnection;
  String get fairConnection => _messages.fairConnection;
  String get poorConnection => _messages.poorConnection;

  // Validation messages
  String get fieldRequired => _messages.fieldRequired;
  String get invalidEmail => _messages.invalidEmail;
  String get invalidPhoneNumber => _messages.invalidPhoneNumber;
  String get passwordTooShort => _messages.passwordTooShort;
  String get passwordTooWeak => _messages.passwordTooWeak;
  String get passwordsDoNotMatch => _messages.passwordsDoNotMatch;
  String get invalidUrl => _messages.invalidUrl;
  String get invalidDate => _messages.invalidDate;
  String get valueTooSmall => _messages.valueTooSmall;
  String get valueTooLarge => _messages.valueTooLarge;

  // Error type messages
  String getErrorTypeMessage(ErrorType type) {
    switch (type) {
      case ErrorType.api:
        return _messages.apiError;
      case ErrorType.network:
        return networkError;
      case ErrorType.validation:
        return validationError;
      case ErrorType.authentication:
        return _messages.authenticationError;
      case ErrorType.authorization:
        return _messages.authorizationError;
      case ErrorType.client:
        return clientError;
      case ErrorType.server:
        return serverError;
      case ErrorType.offline:
        return _messages.offlineError;
    }
  }

  // Network error type messages
  String getNetworkErrorMessage(NetworkErrorType type) {
    switch (type) {
      case NetworkErrorType.noConnection:
        return noConnection;
      case NetworkErrorType.timeout:
        return connectionTimeout;
      case NetworkErrorType.dnsFailure:
        return dnsFailure;
      case NetworkErrorType.connectionRefused:
        return connectionRefused;
      case NetworkErrorType.certificateError:
      case NetworkErrorType.sslError:
        return certificateError;
      case NetworkErrorType.cancelled:
        return requestCancelled;
      case NetworkErrorType.poorQuality:
        return poorNetworkQuality;
      case NetworkErrorType.unknown:
        return networkError;
    }
  }

  // HTTP status code messages
  String getHttpStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return badRequest;
      case 401:
        return unauthorized;
      case 403:
        return forbidden;
      case 404:
        return notFound;
      case 405:
        return methodNotAllowed;
      case 408:
        return requestTimeout;
      case 409:
        return conflict;
      case 422:
        return unprocessableEntity;
      case 429:
        return tooManyRequests;
      case 500:
        return internalServerError;
      case 502:
        return badGateway;
      case 503:
        return serviceUnavailable;
      case 504:
        return gatewayTimeout;
      default:
        if (statusCode >= 500) {
          return serverError;
        } else if (statusCode >= 400) {
          return clientError;
        } else {
          return unknownError;
        }
    }
  }

  // Pluralization helpers
  String getValidationErrorCount(int count) {
    if (count == 1) {
      return _messages.oneValidationError;
    } else {
      return _messages.multipleValidationErrors.replaceAll('{count}', count.toString());
    }
  }

  String getErrorCount(int count) {
    if (count == 1) {
      return _messages.oneError;
    } else {
      return _messages.multipleErrors.replaceAll('{count}', count.toString());
    }
  }

  String getSimilarErrorCount(int count) {
    if (count == 1) {
      return _messages.oneSimilarError;
    } else {
      return _messages.multipleSimilarErrors.replaceAll('{count}', count.toString());
    }
  }

  // Time-based messages
  String getRetryAfterMessage(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds <= 60) {
      return _messages.retryAfterSeconds.replaceAll('{seconds}', seconds.toString());
    } else {
      final minutes = duration.inMinutes;
      return _messages.retryAfterMinutes.replaceAll('{minutes}', minutes.toString());
    }
  }

  // Permission messages
  String getPermissionDeniedMessage(String permission) {
    return _messages.permissionDenied.replaceAll('{permission}', permission);
  }

  // Storage messages
  String getStorageFullMessage() => _messages.storageFullMessage;

  // Data corruption messages
  String getDataCorruptionMessage() => _messages.dataCorruptionMessage;

  // Maintenance messages
  String getMaintenanceMessage() => _messages.maintenanceMessage;

  // Private helper methods
  static ErrorMessages _getMessagesForLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return ErrorMessages.en();
      case 'vi':
        return ErrorMessages.vi();
      case 'es':
        return ErrorMessages.es();
      case 'fr':
        return ErrorMessages.fr();
      case 'de':
        return ErrorMessages.de();
      case 'ja':
        return ErrorMessages.ja();
      case 'ko':
        return ErrorMessages.ko();
      case 'zh':
        return ErrorMessages.zh();
      case 'ar':
        return ErrorMessages.ar();
      default:
        return ErrorMessages.en(); // Fallback to English
    }
  }
}

/// Delegate for ErrorLocalizations
class ErrorLocalizationsDelegate extends LocalizationsDelegate<ErrorLocalizations> {
  const ErrorLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ErrorLocalizations.isSupported(locale);

  @override
  Future<ErrorLocalizations> load(Locale locale) {
    return SynchronousFuture<ErrorLocalizations>(
      ErrorLocalizations.forLocale(locale),
    );
  }

  @override
  bool shouldReload(ErrorLocalizationsDelegate old) => false;
}