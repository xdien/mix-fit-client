import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/build_config_factory.dart';
import '../config/build_config_generator.dart';

/// Example usage of BuildConfigManager for different scenarios
class BuildConfigUsageExample {
  
  /// Example 1: Create build config for current environment
  static Future<void> exampleCurrentEnvironment() async {
    print('=== Example 1: Current Environment ===');
    
    final factory = BuildConfigFactory.instance;
    final buildConfig = await factory.createCurrent();
    
    print('Application ID: ${buildConfig.applicationId}');
    print('Application Name: ${buildConfig.applicationName}');
    print('Build Variant: ${buildConfig.buildVariant}');
    print('Is Debug Build: ${buildConfig.isDebugBuild}');
    print('Environment: ${buildConfig.flavor}');
    
    // Generate build settings
    final settings = buildConfig.getBuildSettings();
    print('Build Settings: $settings');
  }

  /// Example 2: Create build config for specific environments
  static Future<void> exampleSpecificEnvironments() async {
    print('\n=== Example 2: Specific Environments ===');
    
    final factory = BuildConfigFactory.instance;
    
    // Development environment
    try {
      final devConfig = await factory.createDevelopment();
      print('Development Config:');
      print('  - App Name: ${devConfig.applicationName}');
      print('  - Bundle ID: ${devConfig.applicationId}');
      print('  - Build Variant: ${devConfig.buildVariant}');
      print('  - Debug Mode: ${devConfig.isDebugBuild}');
    } catch (e) {
      print('Development config not available: $e');
    }
    
    // Production environment
    try {
      final prodConfig = await factory.createProduction();
      print('Production Config:');
      print('  - App Name: ${prodConfig.applicationName}');
      print('  - Bundle ID: ${prodConfig.applicationId}');
      print('  - Build Variant: ${prodConfig.buildVariant}');
      print('  - Debug Mode: ${prodConfig.isDebugBuild}');
      print('  - Should Obfuscate: ${prodConfig.shouldObfuscate}');
    } catch (e) {
      print('Production config not available: $e');
    }
  }

  /// Example 3: Create custom build configuration
  static Future<void> exampleCustomConfiguration() async {
    print('\n=== Example 3: Custom Configuration ===');
    
    final factory = BuildConfigFactory.instance;
    
    final customConfig = factory.createCustom(
      environmentName: 'custom',
      displayName: 'Custom Environment',
      appName: 'Custom CMS App',
      bundleId: 'com.custom.cms',
      apiBaseUrl: 'https://api.custom.cms.com',
      websocketUrl: 'wss://ws.custom.cms.com',
      versionName: '2.1.0',
      versionCode: 21,
      buildVariant: 'release',
      isDebugMode: false,
    );
    
    print('Custom Configuration:');
    print('  - Environment: ${customConfig.flavor}');
    print('  - App Name: ${customConfig.applicationName}');
    print('  - Bundle ID: ${customConfig.applicationId}');
    print('  - Version: ${customConfig.versionName} (${customConfig.versionCode})');
    print('  - Build Type: ${customConfig.buildType}');
    
    // Validate configuration
    final validation = customConfig.validateConfiguration();
    print('  - Valid: ${validation.isValid}');
    if (validation.hasErrors) {
      print('  - Errors: ${validation.errors}');
    }
    if (validation.hasWarnings) {
      print('  - Warnings: ${validation.warnings}');
    }
  }

  /// Example 4: Generate configuration files
  static Future<void> exampleGenerateConfigFiles() async {
    print('\n=== Example 4: Generate Configuration Files ===');
    
    final factory = BuildConfigFactory.instance;
    final buildConfig = factory.createForTesting(
      environmentName: 'demo',
      appName: 'Demo CMS App',
      bundleId: 'com.demo.cms',
      apiBaseUrl: 'https://api.demo.cms.com',
      buildVariant: 'release',
      isDebugMode: false,
    );
    
    final generator = BuildConfigGenerator(buildConfig);
    
    // Generate different configuration formats
    print('Gradle Properties:');
    print(generator.generateGradleProperties());
    
    print('\nAndroid Build Gradle Snippet:');
    print(generator.generateAndroidBuildGradle());
    
    print('\nEnvironment Variables (Bash):');
    print(generator.generateEnvironmentScript(format: 'bash'));
    
    print('\nFastlane Configuration:');
    print(generator.generateFastlaneConfig());
    
    // Write files to temporary directory
    final tempDir = await Directory.systemTemp.createTemp('build_config_demo_');
    await generator.writeConfigurationFiles(tempDir.path);
    print('\nConfiguration files written to: ${tempDir.path}');
    
    // List generated files
    final files = await tempDir.list().toList();
    print('Generated files:');
    for (final file in files) {
      if (file is File) {
        final name = file.path.split('/').last;
        final size = await file.length();
        print('  - $name ($size bytes)');
      }
    }
    
    // Clean up
    await tempDir.delete(recursive: true);
  }

  /// Example 5: Build variant comparison
  static Future<void> exampleBuildVariantComparison() async {
    print('\n=== Example 5: Build Variant Comparison ===');
    
    final factory = BuildConfigFactory.instance;
    
    // Create same environment with different build variants
    final debugConfig = factory.createForTesting(
      environmentName: 'comparison',
      appName: 'Comparison App',
      bundleId: 'com.comparison.app',
      buildVariant: 'debug',
      isDebugMode: true,
    );
    
    final releaseConfig = factory.createForTesting(
      environmentName: 'comparison',
      appName: 'Comparison App',
      bundleId: 'com.comparison.app',
      buildVariant: 'release',
      isDebugMode: false,
    );
    
    print('Debug vs Release Comparison:');
    print('Property\t\tDebug\t\tRelease');
    print('Build Variant\t\t${debugConfig.buildVariant}\t\t${releaseConfig.buildVariant}');
    print('Is Debug\t\t${debugConfig.isDebugBuild}\t\t${releaseConfig.isDebugBuild}');
    print('Should Obfuscate\t${debugConfig.shouldObfuscate}\t\t${releaseConfig.shouldObfuscate}');
    print('Shrink Resources\t${debugConfig.shouldShrinkResources}\t\t${releaseConfig.shouldShrinkResources}');
  }

  /// Example 6: Environment variables generation
  static Future<void> exampleEnvironmentVariables() async {
    print('\n=== Example 6: Environment Variables ===');
    
    final factory = BuildConfigFactory.instance;
    final buildConfig = factory.createForTesting(
      environmentName: 'env_demo',
      appName: 'Environment Demo App',
      bundleId: 'com.env.demo',
      apiBaseUrl: 'https://api.env.demo.com',
      websocketUrl: 'wss://ws.env.demo.com',
    );
    
    final envVars = buildConfig.generateEnvironmentVariables();
    
    print('Generated Environment Variables:');
    envVars.forEach((key, value) {
      print('  $key=$value');
    });
    
    // Generate Gradle properties
    final gradleProps = buildConfig.generateGradleProperties();
    print('\nGenerated Gradle Properties:');
    gradleProps.forEach((key, value) {
      print('  $key=$value');
    });
  }

  /// Example 7: Configuration validation
  static Future<void> exampleConfigurationValidation() async {
    print('\n=== Example 7: Configuration Validation ===');
    
    final factory = BuildConfigFactory.instance;
    
    // Valid configuration
    final validConfig = factory.createForTesting(
      bundleId: 'com.valid.app',
      apiBaseUrl: 'https://api.valid.com',
    );
    
    final validResult = validConfig.validateConfiguration();
    print('Valid Configuration:');
    print('  - Is Valid: ${validResult.isValid}');
    print('  - Errors: ${validResult.errors.length}');
    print('  - Warnings: ${validResult.warnings.length}');
    
    // Invalid configuration
    final invalidConfig = factory.createForTesting(
      bundleId: 'invalid-bundle-id',
      apiBaseUrl: 'not-a-valid-url',
    );
    
    final invalidResult = invalidConfig.validateConfiguration();
    print('\nInvalid Configuration:');
    print('  - Is Valid: ${invalidResult.isValid}');
    print('  - Errors: ${invalidResult.errors}');
    print('  - Warnings: ${invalidResult.warnings}');
  }

  /// Example 8: Copy and modify configuration
  static Future<void> exampleCopyAndModify() async {
    print('\n=== Example 8: Copy and Modify Configuration ===');
    
    final factory = BuildConfigFactory.instance;
    final originalConfig = factory.createForTesting(
      environmentName: 'original',
      appName: 'Original App',
      buildVariant: 'debug',
      isDebugMode: true,
    );
    
    print('Original Configuration:');
    print('  - Environment: ${originalConfig.flavor}');
    print('  - App Name: ${originalConfig.applicationName}');
    print('  - Build Variant: ${originalConfig.buildVariant}');
    print('  - Is Debug: ${originalConfig.isDebugBuild}');
    
    // Create a modified copy
    final modifiedConfig = originalConfig.copyWith(
      buildVariant: 'release',
      isDebugMode: false,
    );
    
    print('\nModified Configuration:');
    print('  - Environment: ${modifiedConfig.flavor}');
    print('  - App Name: ${modifiedConfig.applicationName}');
    print('  - Build Variant: ${modifiedConfig.buildVariant}');
    print('  - Is Debug: ${modifiedConfig.isDebugBuild}');
    
    print('\nOriginal configuration unchanged:');
    print('  - Build Variant: ${originalConfig.buildVariant}');
    print('  - Is Debug: ${originalConfig.isDebugBuild}');
  }

  /// Run all examples
  static Future<void> runAllExamples() async {
    print('BuildConfigManager Usage Examples');
    print('==================================');
    
    await exampleCurrentEnvironment();
    await exampleSpecificEnvironments();
    await exampleCustomConfiguration();
    await exampleGenerateConfigFiles();
    await exampleBuildVariantComparison();
    await exampleEnvironmentVariables();
    await exampleConfigurationValidation();
    await exampleCopyAndModify();
    
    print('\n==================================');
    print('All examples completed!');
  }
}

/// Main function to run examples (for testing purposes)
void main() async {
  await BuildConfigUsageExample.runAllExamples();
}