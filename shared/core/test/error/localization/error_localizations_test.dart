import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/error/localization/error_localizations.dart';
import '../../../lib/error/models/error_type.dart';
import '../../../lib/error/models/network_error.dart';

void main() {
  group('ErrorLocalizations', () {
    group('forLocale', () {
      test('creates English localizations', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.locale, equals(const Locale('en')));
        expect(localizations.unknownError, equals('An unknown error occurred'));
        expect(localizations.retry, equals('Retry'));
        expect(localizations.dismiss, equals('Dismiss'));
      });

      test('creates Vietnamese localizations', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('vi'));
        
        expect(localizations.locale, equals(const Locale('vi')));
        expect(localizations.unknownError, equals('Đã xảy ra lỗi không xác định'));
        expect(localizations.retry, equals('Thử lại'));
        expect(localizations.dismiss, equals('Bỏ qua'));
      });

      test('creates Spanish localizations', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('es'));
        
        expect(localizations.locale, equals(const Locale('es')));
        expect(localizations.unknownError, equals('Se produjo un error desconocido'));
        expect(localizations.retry, equals('Reintentar'));
        expect(localizations.dismiss, equals('Descartar'));
      });

      test('falls back to English for unsupported locale', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('xx'));
        
        expect(localizations.locale, equals(const Locale('xx')));
        expect(localizations.unknownError, equals('An unknown error occurred'));
      });
    });

    group('isSupported', () {
      test('returns true for supported locales', () {
        expect(ErrorLocalizations.isSupported(const Locale('en')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('vi')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('es')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('fr')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('de')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('ja')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('ko')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('zh')), isTrue);
        expect(ErrorLocalizations.isSupported(const Locale('ar')), isTrue);
      });

      test('returns false for unsupported locales', () {
        expect(ErrorLocalizations.isSupported(const Locale('xx')), isFalse);
        expect(ErrorLocalizations.isSupported(const Locale('yy')), isFalse);
      });
    });

    group('getErrorTypeMessage', () {
      test('returns correct messages for error types', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getErrorTypeMessage(ErrorType.api), equals('API error occurred'));
        expect(localizations.getErrorTypeMessage(ErrorType.network), equals('Network error occurred'));
        expect(localizations.getErrorTypeMessage(ErrorType.validation), equals('Validation error'));
        expect(localizations.getErrorTypeMessage(ErrorType.authentication), equals('Authentication failed'));
        expect(localizations.getErrorTypeMessage(ErrorType.authorization), equals('Access denied'));
        expect(localizations.getErrorTypeMessage(ErrorType.client), equals('Client error occurred'));
        expect(localizations.getErrorTypeMessage(ErrorType.server), equals('Server error occurred'));
        expect(localizations.getErrorTypeMessage(ErrorType.offline), equals('You are currently offline'));
      });
    });

    group('getNetworkErrorMessage', () {
      test('returns correct messages for network error types', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.noConnection), 
               equals('No internet connection available'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.timeout), 
               equals('Connection timed out'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.dnsFailure), 
               equals('Unable to resolve server address'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.connectionRefused), 
               equals('Connection refused by server'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.certificateError), 
               equals('SSL certificate error'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.sslError), 
               equals('SSL certificate error'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.cancelled), 
               equals('Request was cancelled'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.poorQuality), 
               equals('Poor network quality detected'));
        expect(localizations.getNetworkErrorMessage(NetworkErrorType.unknown), 
               equals('Network error occurred'));
      });
    });

    group('getHttpStatusMessage', () {
      test('returns correct messages for HTTP status codes', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getHttpStatusMessage(400), equals('Bad request. Please check your input.'));
        expect(localizations.getHttpStatusMessage(401), equals('Authentication required. Please log in.'));
        expect(localizations.getHttpStatusMessage(403), equals('Access denied. You don\'t have permission.'));
        expect(localizations.getHttpStatusMessage(404), equals('The requested resource was not found.'));
        expect(localizations.getHttpStatusMessage(405), equals('Method not allowed.'));
        expect(localizations.getHttpStatusMessage(408), equals('Request timed out. Please try again.'));
        expect(localizations.getHttpStatusMessage(409), equals('Conflict occurred. Please refresh and try again.'));
        expect(localizations.getHttpStatusMessage(422), equals('Unable to process the request.'));
        expect(localizations.getHttpStatusMessage(429), equals('Too many requests. Please try again later.'));
        expect(localizations.getHttpStatusMessage(500), equals('Internal server error. Please try again later.'));
        expect(localizations.getHttpStatusMessage(502), equals('Bad gateway. Please try again later.'));
        expect(localizations.getHttpStatusMessage(503), equals('Service temporarily unavailable.'));
        expect(localizations.getHttpStatusMessage(504), equals('Gateway timeout. Please try again.'));
      });

      test('returns generic messages for unknown status codes', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getHttpStatusMessage(418), equals('Client error occurred')); // 4xx
        expect(localizations.getHttpStatusMessage(507), equals('Server error occurred')); // 5xx
        expect(localizations.getHttpStatusMessage(200), equals('An unknown error occurred')); // 2xx
      });
    });

    group('pluralization helpers', () {
      test('getValidationErrorCount handles singular and plural', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getValidationErrorCount(1), equals('Please fix the validation error'));
        expect(localizations.getValidationErrorCount(2), equals('Please fix 2 validation errors'));
        expect(localizations.getValidationErrorCount(5), equals('Please fix 5 validation errors'));
      });

      test('getErrorCount handles singular and plural', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getErrorCount(1), equals('1 error'));
        expect(localizations.getErrorCount(2), equals('2 errors'));
        expect(localizations.getErrorCount(10), equals('10 errors'));
      });

      test('getSimilarErrorCount handles singular and plural', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getSimilarErrorCount(1), equals('and 1 similar error'));
        expect(localizations.getSimilarErrorCount(3), equals('and 3 similar errors'));
      });
    });

    group('time-based messages', () {
      test('getRetryAfterMessage formats duration correctly', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getRetryAfterMessage(const Duration(seconds: 30)), 
               equals('Please try again in 30 seconds'));
        expect(localizations.getRetryAfterMessage(const Duration(seconds: 90)), 
               equals('Please try again in 1 minutes'));
        expect(localizations.getRetryAfterMessage(const Duration(minutes: 5)), 
               equals('Please try again in 5 minutes'));
      });
    });

    group('permission messages', () {
      test('getPermissionDeniedMessage formats permission correctly', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getPermissionDeniedMessage('camera'), 
               equals('Permission denied: camera'));
        expect(localizations.getPermissionDeniedMessage('location'), 
               equals('Permission denied: location'));
      });
    });

    group('specialized messages', () {
      test('returns correct specialized messages', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('en'));
        
        expect(localizations.getStorageFullMessage(), 
               equals('Device storage is full. Please free up space.'));
        expect(localizations.getDataCorruptionMessage(), 
               equals('Data corruption detected. Please refresh the app.'));
        expect(localizations.getMaintenanceMessage(), 
               equals('Server is under maintenance. Please try again later.'));
      });
    });

    group('Vietnamese localization', () {
      test('returns correct Vietnamese messages', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('vi'));
        
        expect(localizations.networkError, equals('Lỗi mạng đã xảy ra'));
        expect(localizations.serverError, equals('Lỗi máy chủ đã xảy ra'));
        expect(localizations.noConnection, equals('Không có kết nối internet'));
        expect(localizations.retry, equals('Thử lại'));
        expect(localizations.dismiss, equals('Bỏ qua'));
        expect(localizations.login, equals('Đăng nhập'));
        expect(localizations.contactSupport, equals('Liên hệ hỗ trợ'));
        expect(localizations.online, equals('Trực tuyến'));
        expect(localizations.offline, equals('Ngoại tuyến'));
      });

      test('handles Vietnamese pluralization', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('vi'));
        
        expect(localizations.getValidationErrorCount(1), equals('Vui lòng sửa lỗi xác thực'));
        expect(localizations.getValidationErrorCount(3), equals('Vui lòng sửa 3 lỗi xác thực'));
        expect(localizations.getErrorCount(1), equals('1 lỗi'));
        expect(localizations.getErrorCount(5), equals('5 lỗi'));
      });
    });

    group('Spanish localization', () {
      test('returns correct Spanish messages', () {
        final localizations = ErrorLocalizations.forLocale(const Locale('es'));
        
        expect(localizations.networkError, equals('Error de red'));
        expect(localizations.serverError, equals('Error del servidor'));
        expect(localizations.noConnection, equals('Sin conexión a internet'));
        expect(localizations.retry, equals('Reintentar'));
        expect(localizations.dismiss, equals('Descartar'));
        expect(localizations.login, equals('Iniciar sesión'));
        expect(localizations.contactSupport, equals('Contactar soporte'));
        expect(localizations.online, equals('En línea'));
        expect(localizations.offline, equals('Desconectado'));
      });
    });
  });
}