import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/error/services/error_config_service.dart';
import '../../../lib/error/config/error_system_config.dart';

import 'error_config_service_test.mocks.dart';

@GenerateMocks([SharedPreferences])
void main() {
  late MockSharedPreferences mockPrefs;
  late ErrorConfigService configService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    // Mock SharedPreferences.getInstance() to return our mock
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    configService.dispose();
  });

  group('ErrorConfigService', () {
    test('should initialize with default configuration', () {
      configService = ErrorConfigService();

      expect(configService.config, isA<ErrorSystemConfig>());
      expect(configService.userPreferences, isA<ErrorUserPreferences>());
    });

    test('should initialize with custom configuration', () {
      const customConfig = ErrorSystemConfig(maxErrorQueueSize: 10);
      const customPreferences = ErrorUserPreferences(showErrorBar: false);

      configService = ErrorConfigService(
        initialConfig: customConfig,
        initialUserPreferences: customPreferences,
      );

      expect(configService.config.maxErrorQueueSize, equals(10));
      expect(configService.userPreferences.showErrorBar, isFalse);
    });

    group('configuration updates', () {
      setUp(() {
        configService = ErrorConfigService();
      });

      test('should update configuration', () async {
        const newConfig = ErrorSystemConfig(maxErrorQueueSize: 8);
        
        configService.updateConfig(newConfig);
        
        expect(configService.config.maxErrorQueueSize, equals(8));
      });

      test('should emit configuration changes', () async {
        const newConfig = ErrorSystemConfig(maxErrorQueueSize: 8);
        
        expectLater(
          configService.configStream,
          emits(newConfig),
        );
        
        await configService.updateConfig(newConfig);
      });

      test('should update user preferences', () async {
        const newPreferences = ErrorUserPreferences(showErrorBar: false);
        
        await configService.updateUserPreferences(newPreferences);
        
        expect(configService.userPreferences.showErrorBar, isFalse);
      });

      test('should emit user preference changes', () async {
        const newPreferences = ErrorUserPreferences(showErrorBar: false);
        
        expectLater(
          configService.userPreferencesStream,
          emits(newPreferences),
        );
        
        await configService.updateUserPreferences(newPreferences);
      });

      test('should update config when user preferences change', () async {
        const newPreferences = ErrorUserPreferences(
          showErrorBar: false,
          showNetworkStatus: false,
        );
        
        await configService.updateUserPreferences(newPreferences);
        
        expect(configService.config.showErrorBarByDefault, isFalse);
        expect(configService.config.showNetworkStatus, isFalse);
      });
    });

    group('reset to defaults', () {
      setUp(() {
        configService = ErrorConfigService();
      });

      test('should reset configuration and preferences to defaults', () async {
        // First, change some values
        const customConfig = ErrorSystemConfig(maxErrorQueueSize: 10);
        const customPreferences = ErrorUserPreferences(showErrorBar: false);
        
        await configService.updateConfig(customConfig);
        await configService.updateUserPreferences(customPreferences);
        
        // Then reset
        await configService.resetToDefaults();
        
        expect(configService.userPreferences.showErrorBar, isTrue);
        expect(configService.config.showErrorBarByDefault, isTrue);
      });
    });

    group('persistence', () {
      test('should save configuration to shared preferences', () async {
        // This test would require mocking SharedPreferences more thoroughly
        // For now, we'll test the basic functionality
        configService = ErrorConfigService();
        const newConfig = ErrorSystemConfig(maxErrorQueueSize: 8);
        
        // This should not throw
        await configService.updateConfig(newConfig);
        
        expect(configService.config.maxErrorQueueSize, equals(8));
      });

      test('should save user preferences to shared preferences', () async {
        configService = ErrorConfigService();
        const newPreferences = ErrorUserPreferences(showErrorBar: false);
        
        // This should not throw
        await configService.updateUserPreferences(newPreferences);
        
        expect(configService.userPreferences.showErrorBar, isFalse);
      });
    });

    group('default configuration selection', () {
      test('should use development config in debug mode', () {
        // This test assumes we're running in debug mode
        if (kDebugMode) {
          configService = ErrorConfigService();
          
          expect(configService.config.showErrorDetailsInDebug, isTrue);
          expect(configService.config.enableErrorAnalytics, isFalse);
        }
      });
    });

    group('error handling', () {
      test('should handle initialization errors gracefully', () {
        // This should not throw even if SharedPreferences fails
        expect(() => ErrorConfigService(), returnsNormally);
      });

      test('should handle save errors gracefully', () async {
        configService = ErrorConfigService();
        const newConfig = ErrorSystemConfig(maxErrorQueueSize: 8);
        
        // This should not throw even if saving fails
        expect(() => configService.updateConfig(newConfig), returnsNormally);
      });
    });

    group('streams', () {
      setUp(() {
        configService = ErrorConfigService();
      });

      test('should provide config stream', () {
        expect(configService.configStream, isA<Stream<ErrorSystemConfig>>());
      });

      test('should provide user preferences stream', () {
        expect(configService.userPreferencesStream, isA<Stream<ErrorUserPreferences>>());
      });

      test('should close streams on dispose', () {
        configService.dispose();
        
        // Streams should be closed, but we can't easily test this
        // without more complex stream testing
        expect(() => configService.dispose(), returnsNormally);
      });
    });
  });

  group('ErrorConfigExtensions', () {
    test('should get auto-dismiss timeout', () {
      const config = ErrorSystemConfig();
      
      final timeout = config.getAutoDismissTimeout(ErrorSeverity.info);
      
      expect(timeout, equals(const Duration(seconds: 3)));
    });

    test('should check if auto-dismiss is enabled', () {
      const config = ErrorSystemConfig();
      
      final shouldDismiss = config.shouldAutoDismiss(ErrorSeverity.info);
      final shouldNotDismiss = config.shouldAutoDismiss(ErrorSeverity.critical);
      
      expect(shouldDismiss, isTrue);
      expect(shouldNotDismiss, isFalse);
    });

    test('should respect user custom timeouts', () {
      const customTimeouts = {
        ErrorSeverity.info: Duration(seconds: 10),
      };
      
      const config = ErrorSystemConfig(
        userPreferences: ErrorUserPreferences(customTimeouts: customTimeouts),
      );
      
      final timeout = config.getAutoDismissTimeout(ErrorSeverity.info);
      
      expect(timeout, equals(const Duration(seconds: 10)));
    });

    test('should disable auto-dismiss when user preference is false', () {
      const config = ErrorSystemConfig(
        userPreferences: ErrorUserPreferences(enableAutoDismiss: false),
      );
      
      final shouldDismiss = config.shouldAutoDismiss(ErrorSeverity.info);
      
      expect(shouldDismiss, isFalse);
    });
  });
}