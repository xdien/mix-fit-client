import 'package:flutter_test/flutter_test.dart';
import 'package:app_config/app_config.dart';

void main() {
  test('EnvironmentConfig can be created from JSON', () {
    final json = {
      'environment': {
        'name': 'development',
        'display_name': 'Development Environment',
      },
      'app': {
        'name': 'Test App',
        'bundle_id': 'com.test.app',
      },
      'network': {
        'api_base_url': 'http://localhost:3000',
      },
    };

    final config = EnvironmentConfig.fromJson(json);

    expect(config.environment.name, 'development');
    expect(config.app.name, 'Test App');
    expect(config.network.apiBaseUrl, 'http://localhost:3000');
  });

  test('ConfigValidator validates bundle ID correctly', () {
    final validResult = ConfigValidator.validateBundleId('com.example.app');
    expect(validResult.isValid, true);

    final invalidResult = ConfigValidator.validateBundleId('invalid-bundle-id');
    expect(invalidResult.isValid, false);
  });
}