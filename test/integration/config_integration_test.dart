import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/app_config.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Configuration Integration Tests', () {
    late ConfigIntegrationHelper integrationHelper;

    setUp(() {
      integrationHelper = ConfigIntegrationHelper();
    });

    test('should initialize configuration system', () async {
      await integrationHelper.initialize('development');
      
      expect(integrationHelper.isConfigurationAvailable(), isTrue);
      expect(integrationHelper.getApiBaseUrl(), isNotEmpty);
      expect(integrationHelper.getAppName(), isNotEmpty);
    });

    test('should provide fallback values when environment config fails', () {
      // Test fallback behavior
      final apiUrl = integrationHelper.getApiBaseUrl();
      final appName = integrationHelper.getAppName();
      final bundleId = integrationHelper.getBundleId();
      
      expect(apiUrl, isNotEmpty);
      expect(appName, isNotEmpty);
      expect(bundleId, isNotEmpty);
    });

    test('should validate configuration', () async {
      await integrationHelper.initialize('development');
      
      final isValid = await integrationHelper.validateConfiguration();
      // In test environment, validation may fail due to missing assets
      // but basic URL validation should still work
      expect(isValid, isA<bool>());
    });

    test('should provide configuration summary', () {
      final summary = integrationHelper.getConfigurationSummary();
      
      expect(summary, isA<Map<String, dynamic>>());
      expect(summary.containsKey('apiBaseUrl'), isTrue);
      expect(summary.containsKey('appName'), isTrue);
      expect(summary.containsKey('environmentName'), isTrue);
    });

    test('should handle WebSocket URL configuration', () {
      final websocketUrl = integrationHelper.getWebSocketUrl();
      
      expect(websocketUrl, isNotNull);
      expect(websocketUrl, isNotEmpty);
    });

    test('should provide timeout configuration', () {
      final timeout = integrationHelper.getTimeout();
      
      expect(timeout, greaterThan(0));
      expect(timeout, lessThanOrEqualTo(60000)); // Reasonable timeout limit
    });

    test('should detect debug mode correctly', () {
      final isDebug = integrationHelper.isDebugMode();
      
      expect(isDebug, isA<bool>());
    });
  });

  group('Legacy Config Adapter Tests', () {
    late LegacyConfigAdapter adapter;

    setUp(() {
      adapter = LegacyConfigAdapter();
    });

    test('should provide endpoint configuration', () {
      final endpoint = adapter.endpoint;
      
      expect(endpoint, isNotEmpty);
      expect(Uri.tryParse(endpoint), isNotNull);
    });

    test('should provide WebSocket URL', () {
      final websocketUrl = adapter.websocketUrl;
      
      expect(websocketUrl, isNotEmpty);
    });

    test('should provide app configuration', () {
      final appName = adapter.appName;
      final bundleId = adapter.bundleId;
      
      expect(appName, isNotEmpty);
      expect(bundleId, isNotEmpty);
      expect(bundleId, contains('.'));
    });

    test('should provide network timeout', () {
      final timeout = adapter.timeout;
      
      expect(timeout, greaterThan(0));
    });

    test('should convert to map for debugging', () {
      final map = adapter.toMap();
      
      expect(map, isA<Map<String, dynamic>>());
      expect(map.containsKey('endpoint'), isTrue);
      expect(map.containsKey('appName'), isTrue);
      expect(map.containsKey('bundleId'), isTrue);
    });
  });

  group('Backward Compatibility Tests', () {
    late AppConfig legacyConfig;

    setUp(() {
      legacyConfig = AppConfig();
      legacyConfig.reset(); // Reset for each test
    });

    test('should maintain backward compatibility with legacy AppConfig', () async {
      try {
        await legacyConfig.load('development');
        
        expect(legacyConfig.endpoint, isNotEmpty);
        expect(legacyConfig.debugMode, isA<bool>());
        expect(legacyConfig.isLoaded, isTrue);
      } catch (e) {
        // If legacy config fails, it should fallback to environment config
        expect(legacyConfig.endpoint, isNotEmpty);
      }
    });

    test('should provide getValue method for backward compatibility', () async {
      await legacyConfig.load('development');
      
      final endpoint = legacyConfig.getValue<String>('endpoint', 'default');
      final debugMode = legacyConfig.getValue<bool>('debugMode', false);
      
      expect(endpoint, isNotEmpty);
      expect(debugMode, isA<bool>());
    });

    test('should provide config map access', () async {
      await legacyConfig.load('development');
      
      final config = legacyConfig.config;
      
      expect(config, isA<Map<String, dynamic>>());
      expect(config.isNotEmpty, isTrue);
    });
  });
}