import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'build_config_manager.dart';

/// Generates build configuration files for different platforms and tools
class BuildConfigGenerator {
  final BuildConfigManager _buildConfigManager;

  BuildConfigGenerator(this._buildConfigManager);

  /// Generates Android gradle.properties content
  String generateGradleProperties() {
    final properties = _buildConfigManager.generateGradleProperties();
    final buffer = StringBuffer();
    
    buffer.writeln('# Generated build configuration');
    buffer.writeln('# Environment: ${_buildConfigManager.flavor}');
    buffer.writeln('# Build variant: ${_buildConfigManager.buildVariant}');
    buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    for (final entry in properties.entries) {
      buffer.writeln('${entry.key}=${entry.value}');
    }
    
    return buffer.toString();
  }

  /// Generates Android build.gradle configuration snippet
  String generateAndroidBuildGradle() {
    final settings = _buildConfigManager.getBuildSettings();
    final buffer = StringBuffer();
    
    buffer.writeln('android {');
    buffer.writeln('    defaultConfig {');
    buffer.writeln('        applicationId "${settings['applicationId']}"');
    buffer.writeln('        versionCode ${settings['versionCode']}');
    buffer.writeln('        versionName "${settings['versionName']}"');
    buffer.writeln('    }');
    buffer.writeln();
    
    buffer.writeln('    buildTypes {');
    buffer.writeln('        ${settings['buildType']} {');
    buffer.writeln('            minifyEnabled ${settings['shouldObfuscate']}');
    buffer.writeln('            shrinkResources ${settings['shouldShrinkResources']}');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();
    
    if (settings['flavor'] != settings['buildType']) {
      buffer.writeln('    flavorDimensions "environment"');
      buffer.writeln('    productFlavors {');
      buffer.writeln('        ${settings['flavor']} {');
      buffer.writeln('            dimension "environment"');
      buffer.writeln('            applicationIdSuffix ".${settings['flavor']}"');
      buffer.writeln('            versionNameSuffix "-${settings['flavor']}"');
      buffer.writeln('        }');
      buffer.writeln('    }');
    }
    
    buffer.writeln('}');
    
    return buffer.toString();
  }

  /// Generates iOS Info.plist configuration
  Map<String, dynamic> generateIOSInfoPlist() {
    final settings = _buildConfigManager.getBuildSettings();
    
    return {
      'CFBundleIdentifier': settings['applicationId'],
      'CFBundleName': settings['applicationName'],
      'CFBundleDisplayName': settings['displayName'],
      'CFBundleShortVersionString': settings['versionName'],
      'CFBundleVersion': settings['versionCode'].toString(),
    };
  }

  /// Generates Fastlane configuration
  String generateFastlaneConfig() {
    final config = _buildConfigManager.generateFastlaneConfig();
    final buffer = StringBuffer();
    
    buffer.writeln('# Fastlane configuration');
    buffer.writeln('# Environment: ${config['environment']}');
    buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    // Generate Ruby hash format
    buffer.writeln('FASTLANE_CONFIG = {');
    _writeRubyHash(buffer, config, indent: 2);
    buffer.writeln('}');
    
    return buffer.toString();
  }

  /// Generates environment variables script
  String generateEnvironmentScript({String format = 'bash'}) {
    final envVars = _buildConfigManager.generateEnvironmentVariables();
    final buffer = StringBuffer();
    
    switch (format.toLowerCase()) {
      case 'bash':
      case 'sh':
        buffer.writeln('#!/bin/bash');
        buffer.writeln('# Environment variables for ${_buildConfigManager.flavor}');
        buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
        buffer.writeln();
        
        for (final entry in envVars.entries) {
          buffer.writeln('export ${entry.key}="${entry.value}"');
        }
        break;
        
      case 'powershell':
      case 'ps1':
        buffer.writeln('# Environment variables for ${_buildConfigManager.flavor}');
        buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
        buffer.writeln();
        
        for (final entry in envVars.entries) {
          buffer.writeln('\$env:${entry.key} = "${entry.value}"');
        }
        break;
        
      case 'batch':
      case 'bat':
        buffer.writeln('@echo off');
        buffer.writeln('REM Environment variables for ${_buildConfigManager.flavor}');
        buffer.writeln('REM Generated at: ${DateTime.now().toIso8601String()}');
        buffer.writeln();
        
        for (final entry in envVars.entries) {
          buffer.writeln('set ${entry.key}=${entry.value}');
        }
        break;
        
      default:
        throw ArgumentError('Unsupported script format: $format');
    }
    
    return buffer.toString();
  }

  /// Generates JSON configuration file
  String generateJsonConfig() {
    final settings = _buildConfigManager.getBuildSettings();
    final envVars = _buildConfigManager.generateEnvironmentVariables();
    
    final config = {
      'build_info': settings,
      'environment_variables': envVars,
      'generated_at': DateTime.now().toIso8601String(),
    };
    
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(config);
  }

  /// Generates YAML configuration file
  String generateYamlConfig() {
    final settings = _buildConfigManager.getBuildSettings();
    final buffer = StringBuffer();
    
    buffer.writeln('# Build configuration for ${_buildConfigManager.flavor}');
    buffer.writeln('# Generated at: ${DateTime.now().toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('build_info:');
    _writeYamlMap(buffer, settings, indent: 2);
    
    buffer.writeln();
    buffer.writeln('environment_variables:');
    final envVars = _buildConfigManager.generateEnvironmentVariables();
    _writeYamlMap(buffer, envVars, indent: 2);
    
    return buffer.toString();
  }

  /// Writes configuration files to the specified directory
  Future<void> writeConfigurationFiles(String outputDir) async {
    final dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    final environment = _buildConfigManager.flavor;
    final buildVariant = _buildConfigManager.buildVariant;
    
    // Write Gradle properties
    final gradlePropsFile = File(path.join(outputDir, 'gradle.properties'));
    await gradlePropsFile.writeAsString(generateGradleProperties());
    
    // Write Android build.gradle snippet
    final buildGradleFile = File(path.join(outputDir, 'build.gradle.snippet'));
    await buildGradleFile.writeAsString(generateAndroidBuildGradle());
    
    // Write iOS Info.plist
    final infoPlistFile = File(path.join(outputDir, 'Info.plist.json'));
    const encoder = JsonEncoder.withIndent('  ');
    await infoPlistFile.writeAsString(encoder.convert(generateIOSInfoPlist()));
    
    // Write Fastlane configuration
    final fastlaneFile = File(path.join(outputDir, 'fastlane_config.rb'));
    await fastlaneFile.writeAsString(generateFastlaneConfig());
    
    // Write environment scripts
    final bashFile = File(path.join(outputDir, 'env_vars.sh'));
    await bashFile.writeAsString(generateEnvironmentScript(format: 'bash'));
    
    final psFile = File(path.join(outputDir, 'env_vars.ps1'));
    await psFile.writeAsString(generateEnvironmentScript(format: 'powershell'));
    
    final batFile = File(path.join(outputDir, 'env_vars.bat'));
    await batFile.writeAsString(generateEnvironmentScript(format: 'batch'));
    
    // Write JSON and YAML configs
    final jsonFile = File(path.join(outputDir, 'build_config.json'));
    await jsonFile.writeAsString(generateJsonConfig());
    
    final yamlFile = File(path.join(outputDir, 'build_config.yaml'));
    await yamlFile.writeAsString(generateYamlConfig());
    
    print('Configuration files written to: $outputDir');
    print('Environment: $environment');
    print('Build variant: $buildVariant');
  }

  /// Helper method to write Ruby hash format
  void _writeRubyHash(StringBuffer buffer, Map<String, dynamic> map, {int indent = 0}) {
    final spaces = ' ' * indent;
    
    for (final entry in map.entries) {
      if (entry.value is Map) {
        buffer.writeln('$spaces${entry.key}: {');
        _writeRubyHash(buffer, entry.value as Map<String, dynamic>, indent: indent + 2);
        buffer.writeln('$spaces},');
      } else if (entry.value is List) {
        buffer.writeln('$spaces${entry.key}: [');
        for (final item in entry.value as List) {
          buffer.writeln('$spaces  "$item",');
        }
        buffer.writeln('$spaces],');
      } else {
        buffer.writeln('$spaces${entry.key}: "${entry.value}",');
      }
    }
  }

  /// Helper method to write YAML format
  void _writeYamlMap(StringBuffer buffer, Map<String, dynamic> map, {int indent = 0}) {
    final spaces = ' ' * indent;
    
    for (final entry in map.entries) {
      if (entry.value is Map) {
        buffer.writeln('$spaces${entry.key}:');
        _writeYamlMap(buffer, entry.value as Map<String, dynamic>, indent: indent + 2);
      } else if (entry.value is List) {
        buffer.writeln('$spaces${entry.key}:');
        for (final item in entry.value as List) {
          buffer.writeln('$spaces  - $item');
        }
      } else {
        buffer.writeln('$spaces${entry.key}: ${entry.value}');
      }
    }
  }
}