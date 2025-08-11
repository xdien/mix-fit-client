import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/error/config/error_system_config.dart';

void main() {
  group('ErrorSystemConfig', () {
    test('should create config with default values', () {
      const config = ErrorSystemConfig();

      expect(config.maxErrorQueueSize, equals(5));
      expect(config.showErrorBarByDefault, isTrue);
      expect(config.showNetworkStatus, isTrue);
      expect(config.enableErrorLogging, isTrue);
      expect(config.maxErrorHistorySize, equals(50));
      expect(config.enableErrorAnalytics, isFalse);
    });

    test('should create config with custom values', () {
      const config = ErrorSystemConfig(
        maxErrorQueueSize: 10,
        showErrorBarByDefault: false,
        enableErrorAnalytics: true,
      );

      expect(config.maxErrorQueueSize, equals(10));
      expect(config.showErrorBarByDefault, isFalse);
      expect(config.enableErrorAnalytics, isTrue);
    });

    test('should create copy with updated values', () {
      const originalConfig = ErrorSystemConfig();
      final updatedConfig = originalConfig.copyWith(
        maxErrorQueueSize: 8,
        enableErrorAnalytics: true,
      );

      expect(updatedConfig.maxErrorQueueSize, equals(8));
      expect(updatedConfig.enableErrorAnalytics, isTrue);
      expect(updatedConfig.showErrorBarByDefault, equals(originalConfig.showErrorBarByDefault));
    });

    group('predefined configurations', () {
      test('development config should have debug features enabled', () {
        const config = ErrorSystemConfig.development;

        expect(config.showErrorDetailsInDebug, isTrue);
        expect(config.enableErrorLogging, isTrue);
        expect(config.enableErrorAnalytics, isFalse);
        expect(config.maxErrorHistorySize, equals(100));
      });

      test('production config should have minimal debug features', () {
        const config = ErrorSystemConfig.production;

        expect(config.showErrorDetailsInDebug, isFalse);
        expect(config.enableErrorLogging, isTrue);
        expect(config.enableErrorAnalytics, isTrue);
        expect(config.maxErrorHistorySize, equals(25));
      });

      test('testing config should have fast timeouts', () {
        const config = ErrorSystemConfig.testing;

        expect(config.showErrorBarByDefault, isFalse);
        expect(config.enableErrorLogging, isFalse);
        expect(config.enableErrorAnalytics, isFalse);
        expect(config.autoDismissTimeouts[ErrorSeverity.info], 
               equals(const Duration(milliseconds: 100)));
      });
    });

    group('auto-dismiss timeouts', () {
      test('should have default timeouts for all severities', () {
        const config = ErrorSystemConfig();

        expect(config.autoDismissTimeouts[ErrorSeverity.info], 
               equals(const Duration(seconds: 3)));
        expect(config.autoDismissTimeouts[ErrorSeverity.warning], 
               equals(const Duration(seconds: 5)));
        expect(config.autoDismissTimeouts[ErrorSeverity.error], 
               equals(const Duration(seconds: 10)));
        expect(config.autoDismissTimeouts[ErrorSeverity.critical], 
               equals(Duration.zero));
      });

      test('should allow custom timeouts', () {
        const customTimeouts = {
          ErrorSeverity.info: Duration(seconds: 2),
          ErrorSeverity.warning: Duration(seconds: 4),
          ErrorSeverity.error: Duration(seconds: 8),
          ErrorSeverity.critical: Duration.zero,
        };

        const config = ErrorSystemConfig(autoDismissTimeouts: customTimeouts);

        expect(config.autoDismissTimeouts, equals(customTimeouts));
      });
    });
  });

  group('ErrorThemeConfig', () {
    test('should create theme with default values', () {
      const theme = ErrorThemeConfig();

      expect(theme.severityColors[ErrorSeverity.info], equals(Colors.blue));
      expect(theme.severityColors[ErrorSeverity.error], equals(Colors.red));
      expect(theme.animationDuration, equals(const Duration(milliseconds: 300)));
      expect(theme.elevation, equals(4.0));
    });

    test('should create copy with updated values', () {
      const originalTheme = ErrorThemeConfig();
      final updatedTheme = originalTheme.copyWith(
        elevation: 8.0,
        animationDuration: const Duration(milliseconds: 500),
      );

      expect(updatedTheme.elevation, equals(8.0));
      expect(updatedTheme.animationDuration, equals(const Duration(milliseconds: 500)));
      expect(updatedTheme.severityColors, equals(originalTheme.severityColors));
    });

    group('predefined themes', () {
      test('dark theme should have appropriate colors', () {
        const theme = ErrorThemeConfig.dark;

        expect(theme.severityColors[ErrorSeverity.info], equals(Colors.lightBlue));
        expect(theme.textColors[ErrorSeverity.info], equals(Colors.white));
        expect(theme.backgroundColors[ErrorSeverity.error], equals(const Color(0xFFB71C1C)));
      });

      test('high contrast theme should have high contrast colors', () {
        const theme = ErrorThemeConfig.highContrast;

        expect(theme.severityColors[ErrorSeverity.info], equals(Colors.black));
        expect(theme.backgroundColors[ErrorSeverity.info], equals(Colors.white));
        expect(theme.elevation, equals(8.0));
      });
    });

    group('theme methods', () {
      test('should get color for severity and type', () {
        const theme = ErrorThemeConfig();

        final primaryColor = theme.getColorForSeverity(ErrorSeverity.error, ErrorColorType.primary);
        final backgroundColor = theme.getColorForSeverity(ErrorSeverity.error, ErrorColorType.background);

        expect(primaryColor, equals(Colors.red));
        expect(backgroundColor, equals(const Color(0xFFFFEBEE)));
      });

      test('should get icon for severity', () {
        const theme = ErrorThemeConfig();

        final infoIcon = theme.getIconForSeverity(ErrorSeverity.info);
        final errorIcon = theme.getIconForSeverity(ErrorSeverity.error);

        expect(infoIcon, equals(Icons.info_outline));
        expect(errorIcon, equals(Icons.error_outline));
      });

      test('should create error decoration', () {
        const theme = ErrorThemeConfig();

        final decoration = theme.createErrorDecoration(ErrorSeverity.warning);

        expect(decoration.color, equals(const Color(0xFFFFF3E0)));
        expect(decoration.borderRadius, equals(theme.borderRadius));
        expect(decoration.border, isNotNull);
      });

      test('should create error text style', () {
        const theme = ErrorThemeConfig();

        final textStyle = theme.createErrorTextStyle(ErrorSeverity.error, isBold: true);

        expect(textStyle.color, equals(const Color(0xFFC62828)));
        expect(textStyle.fontWeight, equals(FontWeight.w600));
      });

      test('should adapt for high contrast', () {
        const theme = ErrorThemeConfig();

        final highContrastTheme = theme.adaptForHighContrast();

        expect(highContrastTheme.elevation, equals(theme.elevation * 2));
        expect(highContrastTheme.severityColors[ErrorSeverity.info], equals(Colors.black));
      });

      test('should adapt for reduced motion', () {
        const theme = ErrorThemeConfig();

        final reducedMotionTheme = theme.adaptForReducedMotion();

        expect(reducedMotionTheme.animationDuration, 
               equals(const Duration(milliseconds: 100)));
      });
    });
  });

  group('ErrorUserPreferences', () {
    test('should create preferences with default values', () {
      const preferences = ErrorUserPreferences();

      expect(preferences.showErrorBar, isTrue);
      expect(preferences.showNetworkStatus, isTrue);
      expect(preferences.enableAutoDismiss, isTrue);
      expect(preferences.enableSoundNotifications, isFalse);
      expect(preferences.displayPosition, equals(ErrorDisplayPosition.top));
    });

    test('should create copy with updated values', () {
      const originalPreferences = ErrorUserPreferences();
      final updatedPreferences = originalPreferences.copyWith(
        showErrorBar: false,
        enableSoundNotifications: true,
      );

      expect(updatedPreferences.showErrorBar, isFalse);
      expect(updatedPreferences.enableSoundNotifications, isTrue);
      expect(updatedPreferences.showNetworkStatus, equals(originalPreferences.showNetworkStatus));
    });

    group('JSON serialization', () {
      test('should convert to JSON', () {
        const preferences = ErrorUserPreferences(
          showErrorBar: false,
          enableVibration: true,
          displayPosition: ErrorDisplayPosition.bottom,
        );

        final json = preferences.toJson();

        expect(json['showErrorBar'], isFalse);
        expect(json['enableVibration'], isTrue);
        expect(json['displayPosition'], equals('bottom'));
      });

      test('should create from JSON', () {
        final json = {
          'showErrorBar': false,
          'showNetworkStatus': true,
          'enableAutoDismiss': false,
          'displayPosition': 'center',
          'enableVibration': false,
        };

        final preferences = ErrorUserPreferences.fromJson(json);

        expect(preferences.showErrorBar, isFalse);
        expect(preferences.showNetworkStatus, isTrue);
        expect(preferences.enableAutoDismiss, isFalse);
        expect(preferences.displayPosition, equals(ErrorDisplayPosition.center));
        expect(preferences.enableVibration, isFalse);
      });

      test('should handle missing JSON fields with defaults', () {
        final json = <String, dynamic>{};

        final preferences = ErrorUserPreferences.fromJson(json);

        expect(preferences.showErrorBar, isTrue);
        expect(preferences.showNetworkStatus, isTrue);
        expect(preferences.displayPosition, equals(ErrorDisplayPosition.top));
      });

      test('should handle custom timeouts in JSON', () {
        const customTimeouts = {
          ErrorSeverity.info: Duration(seconds: 2),
          ErrorSeverity.warning: Duration(seconds: 4),
        };

        const preferences = ErrorUserPreferences(customTimeouts: customTimeouts);
        final json = preferences.toJson();
        final restoredPreferences = ErrorUserPreferences.fromJson(json);

        expect(restoredPreferences.customTimeouts?[ErrorSeverity.info], 
               equals(const Duration(seconds: 2)));
        expect(restoredPreferences.customTimeouts?[ErrorSeverity.warning], 
               equals(const Duration(seconds: 4)));
      });
    });
  });

  group('ErrorConfigExtensions', () {
    test('should get auto-dismiss timeout for severity', () {
      const config = ErrorSystemConfig();

      final infoTimeout = config.getAutoDismissTimeout(ErrorSeverity.info);
      final criticalTimeout = config.getAutoDismissTimeout(ErrorSeverity.critical);

      expect(infoTimeout, equals(const Duration(seconds: 3)));
      expect(criticalTimeout, equals(Duration.zero));
    });

    test('should check if auto-dismiss is enabled', () {
      const config = ErrorSystemConfig();

      final shouldDismissInfo = config.shouldAutoDismiss(ErrorSeverity.info);
      final shouldDismissCritical = config.shouldAutoDismiss(ErrorSeverity.critical);

      expect(shouldDismissInfo, isTrue);
      expect(shouldDismissCritical, isFalse);
    });

    test('should respect user preference for auto-dismiss', () {
      const config = ErrorSystemConfig(
        userPreferences: ErrorUserPreferences(enableAutoDismiss: false),
      );

      final shouldDismissInfo = config.shouldAutoDismiss(ErrorSeverity.info);

      expect(shouldDismissInfo, isFalse);
    });

    test('should use custom timeout from user preferences', () {
      const customTimeouts = {
        ErrorSeverity.info: Duration(seconds: 10),
      };

      const config = ErrorSystemConfig(
        userPreferences: ErrorUserPreferences(customTimeouts: customTimeouts),
      );

      final timeout = config.getAutoDismissTimeout(ErrorSeverity.info);

      expect(timeout, equals(const Duration(seconds: 10)));
    });
  });
}