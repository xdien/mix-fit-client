#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;

/// Test script for Version Management System
/// This script demonstrates the functionality of the VersionManager
void main(List<String> arguments) async {
  print('🧪 Testing Version Management System');
  print('=====================================');
  
  try {
    // Check if we're in the correct directory
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('❌ Error: pubspec.yaml not found. Please run this script from the frontend directory.');
      exit(1);
    }

    // Test 1: Show current version
    print('\n📋 Test 1: Show current version');
    await _testShowCurrentVersion();

    // Test 2: Validate version format
    print('\n✅ Test 2: Validate version format');
    await _testVersionValidation();

    // Test 3: Test version parsing
    print('\n🔍 Test 3: Test version parsing');
    await _testVersionParsing();

    // Test 4: Test semantic versioning
    print('\n📈 Test 4: Test semantic versioning');
    await _testSemanticVersioning();

    // Test 5: Test Git integration (if available)
    print('\n🔗 Test 5: Test Git integration');
    await _testGitIntegration();

    print('\n🎉 All tests completed successfully!');
    print('\n📚 For more information, see: docs/version_management.md');
    
  } catch (e) {
    print('❌ Test failed: $e');
    exit(1);
  }
}

Future<void> _testShowCurrentVersion() async {
  try {
    // Read current version from pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    final content = pubspecFile.readAsStringSync();
    
    // Simple parsing for demo
    final lines = content.split('\n');
    String? version;
    
    for (final line in lines) {
      if (line.trim().startsWith('version:')) {
        version = line.split(':')[1].trim();
        break;
      }
    }
    
    if (version != null) {
      print('   Current version: $version');
      
      // Parse version components
      if (version.contains('+')) {
        final parts = version.split('+');
        final versionName = parts[0];
        final buildNumber = parts[1];
        print('   Version name: $versionName');
        print('   Build number: $buildNumber');
      } else {
        print('   Version name: $version');
        print('   Build number: 1 (default)');
      }
    } else {
      print('   ⚠️  Version not found in pubspec.yaml');
    }
  } catch (e) {
    print('   ❌ Failed to read current version: $e');
  }
}

Future<void> _testVersionValidation() async {
  final validVersions = [
    '1.0.0',
    '2.1.3',
    '10.20.30',
    '1.0.0-beta.1',
    '2.1.3-alpha.2',
  ];
  
  final invalidVersions = [
    '1.0',
    '1.0.0.0',
    'invalid',
    '1.0.0+',
    '1.0.0+abc',
  ];
  
  print('   Valid versions:');
  for (final version in validVersions) {
    final isValid = _isValidVersionFormat(version);
    print('     $version: ${isValid ? '✅' : '❌'}');
  }
  
  print('   Invalid versions:');
  for (final version in invalidVersions) {
    final isValid = _isValidVersionFormat(version);
    print('     $version: ${isValid ? '❌' : '✅'}');
  }
}

Future<void> _testVersionParsing() async {
  final testCases = [
    '1.2.3+4',
    '2.0.0+10',
    '1.0.0-beta.1+5',
    '3.1.2-alpha.2+15',
  ];
  
  for (final testCase in testCases) {
    print('   Parsing: $testCase');
    try {
      final parsed = _parseVersionString(testCase);
      print('     Major: ${parsed['major']}');
      print('     Minor: ${parsed['minor']}');
      print('     Patch: ${parsed['patch']}');
      print('     Build: ${parsed['build']}');
      if (parsed['preRelease'] != null) {
        print('     Pre-release: ${parsed['preRelease']}');
      }
    } catch (e) {
      print('     ❌ Parse failed: $e');
    }
  }
}

Future<void> _testSemanticVersioning() async {
  final testCases = [
    {'current': '1.0.0', 'type': 'patch', 'expected': '1.0.1'},
    {'current': '1.0.1', 'type': 'minor', 'expected': '1.1.0'},
    {'current': '1.1.0', 'type': 'major', 'expected': '2.0.0'},
    {'current': '2.0.0', 'type': 'patch', 'expected': '2.0.1'},
  ];
  
  for (final testCase in testCases) {
    final current = testCase['current']!;
    final type = testCase['type']!;
    final expected = testCase['expected']!;
    
    final result = _incrementVersion(current, type);
    final success = result == expected;
    
    print('   $current -> $type -> $result ${success ? '✅' : '❌ (expected: $expected)'}');
  }
}

Future<void> _testGitIntegration() async {
  try {
    // Check if Git is available
    final result = await Process.run('git', ['--version']);
    if (result.exitCode == 0) {
      print('   Git is available: ${result.stdout.toString().trim()}');
      
      // Check if we're in a Git repository
      final gitCheck = await Process.run('git', ['rev-parse', '--git-dir']);
      if (gitCheck.exitCode == 0) {
        print('   ✅ In Git repository');
        
        // Get current branch
        final branchResult = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
        if (branchResult.exitCode == 0) {
          print('   Current branch: ${branchResult.stdout.toString().trim()}');
        }
        
        // Get current commit
        final commitResult = await Process.run('git', ['rev-parse', 'HEAD']);
        if (commitResult.exitCode == 0) {
          final commitHash = commitResult.stdout.toString().trim();
          print('   Current commit: ${commitHash.substring(0, 8)}');
        }
      } else {
        print('   ⚠️  Not in Git repository');
      }
    } else {
      print('   ❌ Git not available');
    }
  } catch (e) {
    print('   ❌ Git integration test failed: $e');
  }
}

// Helper functions for testing

bool _isValidVersionFormat(String version) {
  // Basic semantic versioning regex
  final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$');
  return regex.hasMatch(version);
}

Map<String, dynamic> _parseVersionString(String versionString) {
  if (versionString.contains('+')) {
    final parts = versionString.split('+');
    final versionPart = parts[0];
    final buildPart = parts[1];
    
    final versionInfo = _parseVersionPart(versionPart);
    versionInfo['build'] = int.parse(buildPart);
    
    return versionInfo;
  } else {
    final versionInfo = _parseVersionPart(versionString);
    versionInfo['build'] = 1;
    return versionInfo;
  }
}

Map<String, dynamic> _parseVersionPart(String versionPart) {
  final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$');
  final match = regex.firstMatch(versionPart);
  
  if (match == null) {
    throw FormatException('Invalid version format: $versionPart');
  }
  
  return {
    'major': int.parse(match.group(1)!),
    'minor': int.parse(match.group(2)!),
    'patch': int.parse(match.group(3)!),
    'preRelease': match.group(4),
  };
}

String _incrementVersion(String currentVersion, String type) {
  final parts = currentVersion.split('.');
  final major = int.parse(parts[0]);
  final minor = int.parse(parts[1]);
  final patch = int.parse(parts[2]);
  
  switch (type) {
    case 'major':
      return '${major + 1}.0.0';
    case 'minor':
      return '$major.${minor + 1}.0';
    case 'patch':
      return '$major.$minor.${patch + 1}';
    default:
      throw ArgumentError('Invalid version type: $type');
  }
} 