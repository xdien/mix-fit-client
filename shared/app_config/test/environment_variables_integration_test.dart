import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/app_config.dart';

void main() {
  group('EnvironmentVariables Integration Tests', () {
    test('should provide centralized access to environment variables', () {
      // Test that EnvironmentVariables provides access to all environment variables
      expect(EnvironmentVariables.apiEndpoint, isNotEmpty);
      expect(EnvironmentVariables.appName, isNotEmpty);
      expect(EnvironmentVariables.bundleId, isNotEmpty);
      expect(EnvironmentVariables.environment, isNotEmpty);
      expect(EnvironmentVariables.networkTimeout, isA<int>());
      expect(EnvironmentVariables.websocketUrl, isNotEmpty);
    });

    test('should provide consistent values across different access methods', () {
      // Test that values are consistent when accessed multiple times
      final apiEndpoint1 = EnvironmentVariables.apiEndpoint;
      final apiEndpoint2 = EnvironmentVariables.apiEndpoint;
      expect(apiEndpoint1, equals(apiEndpoint2));

      final appName1 = EnvironmentVariables.appName;
      final appName2 = EnvironmentVariables.appName;
      expect(appName1, equals(appName2));
    });

    test('should provide toMap method for debugging', () {
      final map = EnvironmentVariables.toMap();
      
      expect(map, isA<Map<String, dynamic>>());
      expect(map['apiEndpoint'], isNotEmpty);
      expect(map['appName'], isNotEmpty);
      expect(map['bundleId'], isNotEmpty);
      expect(map['environment'], isNotEmpty);
      expect(map['networkTimeout'], isA<int>());
      expect(map['websocketUrl'], isNotEmpty);
    });

    test('should work with ConfigIntegrationHelper', () {
      final helper = ConfigIntegrationHelper();
      
      // Test that helper can access environment variables
      expect(helper.getApiBaseUrl(), isNotEmpty);
      expect(helper.getAppName(), isNotEmpty);
      expect(helper.getBundleId(), isNotEmpty);
      expect(helper.getEnvironmentName(), isNotEmpty);
      expect(helper.getTimeout(), isA<int>());
    });

    test('should work with AppConfig', () {
      final appConfig = AppConfig();
      
      // Test that AppConfig can access environment variables
      expect(appConfig.endpoint, isNotEmpty);
      expect(appConfig.apiKey, isA<String>());
      expect(appConfig.debugMode, isA<bool>());
    });
  });
}
