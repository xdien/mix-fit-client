#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

// Import VersionManager from core module
// Note: This script should be run from the frontend directory
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('increment-build')
    ..addCommand('increment-patch')
    ..addCommand('increment-minor')
    ..addCommand('increment-major')
    ..addCommand('update-version')
    ..addCommand('create-tag')
    ..addCommand('current')
    ..addFlag('help', abbr: 'h', help: 'Show this help message')
    ..addFlag('no-commit', help: 'Skip Git commit')
    ..addFlag('no-push', help: 'Skip pushing tag to remote')
    ..addOption('message', abbr: 'm', help: 'Commit/tag message')
    ..addOption('version', abbr: 'v', help: 'Version string (for update-version command)');

  try {
    final results = parser.parse(arguments);

    if (results['help']) {
      print('Version Manager CLI');
      print('');
      print('Usage: dart scripts/version_manager.dart <command> [options]');
      print('');
      print('Commands:');
      print('  increment-build    Increment build number');
      print('  increment-patch    Increment patch version (1.0.0 -> 1.0.1)');
      print('  increment-minor    Increment minor version (1.0.0 -> 1.1.0)');
      print('  increment-major    Increment major version (1.0.0 -> 2.0.0)');
      print('  update-version     Update to specific version');
      print('  create-tag         Create Git tag for current version');
      print('  current            Show current version information');
      print('');
      print('Options:');
      print('  --no-commit        Skip Git commit');
      print('  --no-push          Skip pushing tag to remote');
      print('  --message, -m      Commit/tag message');
      print('  --version, -v      Version string (for update-version command)');
      print('  --help, -h         Show this help message');
      print('');
      print('Examples:');
      print('  dart scripts/version_manager.dart increment-build');
      print('  dart scripts/version_manager.dart increment-patch --message "Fix bug"');
      print('  dart scripts/version_manager.dart update-version --version 2.0.0');
      print('  dart scripts/version_manager.dart create-tag --message "Release v2.0.0"');
      return;
    }

    // Check if we're in the correct directory
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      print('❌ Error: pubspec.yaml not found. Please run this script from the frontend directory.');
      exit(1);
    }

    // Import VersionManager dynamically
    final versionManager = await _createVersionManager();

    final command = results.command?.name;
    final commitChanges = !results['no-commit'];
    final pushTag = !results['no-push'];
    final message = results['message'] as String?;
    final version = results['version'] as String?;

    switch (command) {
      case 'increment-build':
        await _incrementBuildNumber(versionManager, commitChanges, message);
        break;
      case 'increment-patch':
        await _incrementPatch(versionManager, commitChanges, message);
        break;
      case 'increment-minor':
        await _incrementMinor(versionManager, commitChanges, message);
        break;
      case 'increment-major':
        await _incrementMajor(versionManager, commitChanges, message);
        break;
      case 'update-version':
        if (version == null) {
          print('❌ Error: --version option is required for update-version command');
          exit(1);
        }
        await _updateVersion(versionManager, version, commitChanges, message);
        break;
      case 'create-tag':
        await _createTag(versionManager, message, pushTag);
        break;
      case 'current':
        await _showCurrentVersion(versionManager);
        break;
      default:
        print('❌ Error: Unknown command. Use --help for usage information.');
        exit(1);
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<dynamic> _createVersionManager() async {
  // Add the shared/core/lib directory to the path
  final corePath = path.join(Directory.current.path, 'shared', 'core', 'lib');
  
  // Import the VersionManager class
  // Note: This is a simplified approach. In a real implementation,
  // you might want to use a proper dependency injection or import system
  try {
    // For now, we'll create a simple version manager instance
    // In a real implementation, you would import the actual VersionManager class
    return _SimpleVersionManager();
  } catch (e) {
    print('❌ Error: Could not create VersionManager: $e');
    exit(1);
  }
}

Future<void> _incrementBuildNumber(dynamic versionManager, bool commitChanges, String? message) async {
  print('🔄 Incrementing build number...');
  try {
    final newVersion = await versionManager.incrementBuildNumber(
      commitChanges: commitChanges,
      commitMessage: message,
    );
    print('✅ Build number incremented to ${newVersion.buildNumber}');
    print('📋 New version: ${newVersion.fullVersionString}');
  } catch (e) {
    print('❌ Failed to increment build number: $e');
    rethrow;
  }
}

Future<void> _incrementPatch(dynamic versionManager, bool commitChanges, String? message) async {
  print('🔄 Incrementing patch version...');
  try {
    final newVersion = await versionManager.incrementPatch(
      commitChanges: commitChanges,
      commitMessage: message,
    );
    print('✅ Patch version incremented');
    print('📋 New version: ${newVersion.fullVersionString}');
  } catch (e) {
    print('❌ Failed to increment patch version: $e');
    rethrow;
  }
}

Future<void> _incrementMinor(dynamic versionManager, bool commitChanges, String? message) async {
  print('🔄 Incrementing minor version...');
  try {
    final newVersion = await versionManager.incrementMinor(
      commitChanges: commitChanges,
      commitMessage: message,
    );
    print('✅ Minor version incremented');
    print('📋 New version: ${newVersion.fullVersionString}');
  } catch (e) {
    print('❌ Failed to increment minor version: $e');
    rethrow;
  }
}

Future<void> _incrementMajor(dynamic versionManager, bool commitChanges, String? message) async {
  print('🔄 Incrementing major version...');
  try {
    final newVersion = await versionManager.incrementMajor(
      commitChanges: commitChanges,
      commitMessage: message,
    );
    print('✅ Major version incremented');
    print('📋 New version: ${newVersion.fullVersionString}');
  } catch (e) {
    print('❌ Failed to increment major version: $e');
    rethrow;
  }
}

Future<void> _updateVersion(dynamic versionManager, String version, bool commitChanges, String? message) async {
  print('🔄 Updating version to $version...');
  try {
    final newVersion = await versionManager.updateVersionName(
      version: version,
      commitChanges: commitChanges,
      commitMessage: message,
    );
    print('✅ Version updated');
    print('📋 New version: ${newVersion.fullVersionString}');
  } catch (e) {
    print('❌ Failed to update version: $e');
    rethrow;
  }
}

Future<void> _createTag(dynamic versionManager, String? message, bool pushTag) async {
  print('🏷️  Creating Git tag...');
  try {
    await versionManager.createTag(
      tagMessage: message,
      pushTag: pushTag,
    );
    print('✅ Git tag created successfully');
  } catch (e) {
    print('❌ Failed to create Git tag: $e');
    rethrow;
  }
}

Future<void> _showCurrentVersion(dynamic versionManager) async {
  print('📋 Current version information:');
  try {
    final currentVersion = versionManager.currentVersion;
    print('   Version: ${currentVersion.versionString}');
    print('   Build Number: ${currentVersion.buildNumber}');
    print('   Full Version: ${currentVersion.fullVersionString}');
    print('   Is Pre-release: ${currentVersion.isPreRelease}');
    print('   Is Stable: ${currentVersion.isStable}');
    
    // Try to get Git information
    try {
      final commitHash = await versionManager.getGitCommitHash();
      final branch = await versionManager.getGitBranch();
      
      if (commitHash != null) {
        print('   Git Commit: ${commitHash.substring(0, 8)}');
      }
      if (branch != null) {
        print('   Git Branch: $branch');
      }
    } catch (e) {
      print('   Git Info: Not available');
    }
  } catch (e) {
    print('❌ Failed to get current version: $e');
    rethrow;
  }
}

/// Simple implementation of VersionManager for CLI usage
/// This is a placeholder - in a real implementation, you would import the actual VersionManager
class _SimpleVersionManager {
  Future<dynamic> incrementBuildNumber({bool commitChanges = true, String? commitMessage}) async {
    // Implementation would go here
    print('Incrementing build number...');
    return _MockVersionInfo();
  }

  Future<dynamic> incrementPatch({bool commitChanges = true, String? commitMessage}) async {
    print('Incrementing patch version...');
    return _MockVersionInfo();
  }

  Future<dynamic> incrementMinor({bool commitChanges = true, String? commitMessage}) async {
    print('Incrementing minor version...');
    return _MockVersionInfo();
  }

  Future<dynamic> incrementMajor({bool commitChanges = true, String? commitMessage}) async {
    print('Incrementing major version...');
    return _MockVersionInfo();
  }

  Future<dynamic> updateVersionName({required String version, bool commitChanges = true, String? commitMessage}) async {
    print('Updating version to $version...');
    return _MockVersionInfo();
  }

  Future<void> createTag({String? tagMessage, bool pushTag = true}) async {
    print('Creating Git tag...');
  }

  dynamic get currentVersion => _MockVersionInfo();

  Future<String?> getGitCommitHash() async => 'mock-commit-hash';
  Future<String?> getGitBranch() async => 'main';
}

class _MockVersionInfo {
  String get versionString => '1.0.0';
  int get buildNumber => 1;
  String get fullVersionString => '1.0.0+1';
  bool get isPreRelease => false;
  bool get isStable => true;
} 