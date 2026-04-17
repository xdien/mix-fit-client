import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/managers/version_manager.dart';
import 'package:path/path.dart' as path;

void main() {
  group('VersionInfo', () {
    test('should create version from string', () {
      final version = VersionInfo.fromString('1.2.3');
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 1);
      expect(version.preRelease, null);
    });

    test('should create version with pre-release', () {
      final version = VersionInfo.fromString('1.2.3-beta.1');
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 1);
      expect(version.preRelease, 'beta.1');
    });

    test('should create version from Flutter version string', () {
      final version = VersionInfo.fromFlutterVersion('1.2.3+4');
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 4);
      expect(version.preRelease, null);
    });

    test('should generate correct version strings', () {
      final version = VersionInfo(major: 1, minor: 2, patch: 3, buildNumber: 4);
      expect(version.versionString, '1.2.3');
      expect(version.flutterVersionString, '1.2.3+4');
      expect(version.fullVersionString, '1.2.3+4');
    });

    test('should generate version string with pre-release', () {
      final version = VersionInfo(
        major: 1,
        minor: 2,
        patch: 3,
        buildNumber: 4,
        preRelease: 'beta.1',
      );
      expect(version.versionString, '1.2.3-beta.1');
      expect(version.flutterVersionString, '1.2.3-beta.1+4');
      expect(version.fullVersionString, '1.2.3-beta.1+4');
    });

    test('should detect pre-release versions', () {
      final stableVersion = VersionInfo(major: 1, minor: 2, patch: 3, buildNumber: 4);
      final preReleaseVersion = VersionInfo(
        major: 1,
        minor: 2,
        patch: 3,
        buildNumber: 4,
        preRelease: 'beta.1',
      );

      expect(stableVersion.isPreRelease, false);
      expect(stableVersion.isStable, true);
      expect(preReleaseVersion.isPreRelease, true);
      expect(preReleaseVersion.isStable, false);
    });

    test('should compare versions correctly', () {
      final v1 = VersionInfo(major: 1, minor: 2, patch: 3, buildNumber: 4);
      final v2 = VersionInfo(major: 1, minor: 2, patch: 3, buildNumber: 5);
      final v3 = VersionInfo(major: 1, minor: 2, patch: 4, buildNumber: 4);
      final v4 = VersionInfo(major: 1, minor: 3, patch: 0, buildNumber: 4);
      final v5 = VersionInfo(major: 2, minor: 0, patch: 0, buildNumber: 4);

      expect(v1.compareTo(v2), -1);
      expect(v2.compareTo(v1), 1);
      expect(v1.compareTo(v3), -1);
      expect(v1.compareTo(v4), -1);
      expect(v1.compareTo(v5), -1);
    });

    test('should compare pre-release versions correctly', () {
      final stable = VersionInfo(major: 1, minor: 2, patch: 3, buildNumber: 4);
      final preRelease = VersionInfo(
        major: 1,
        minor: 2,
        patch: 3,
        buildNumber: 4,
        preRelease: 'beta.1',
      );

      expect(preRelease.compareTo(stable), -1);
      expect(stable.compareTo(preRelease), 1);
    });

    test('should throw exception for invalid version format', () {
      expect(() => VersionInfo.fromString('invalid'), throwsA(isA<VersionManagerException>()));
      expect(() => VersionInfo.fromString('1.2'), throwsA(isA<VersionManagerException>()));
      expect(() => VersionInfo.fromString('1.2.3.4'), throwsA(isA<VersionManagerException>()));
    });

    test('should throw exception for invalid Flutter version format', () {
      expect(() => VersionInfo.fromFlutterVersion('1.2.3'), throwsA(isA<VersionManagerException>()));
      expect(() => VersionInfo.fromFlutterVersion('1.2.3+'), throwsA(isA<VersionManagerException>()));
      expect(() => VersionInfo.fromFlutterVersion('1.2.3+abc'), throwsA(isA<VersionManagerException>()));
    });

    test('should validate version format', () {
      final manager = VersionManager(enableGitIntegration: false);
      expect(manager.isValidVersion('1.2.3'), true);
      expect(manager.isValidVersion('1.2.3-beta.1'), true);
      expect(manager.isValidVersion('invalid'), false);
      expect(manager.isValidVersion('1.2'), false);
    });
  });

  group('VersionManager', () {
    late Directory tempDir;
    late File pubspecFile;
    late File androidGradleFile;
    late VersionManager versionManager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('version_manager_test');
      pubspecFile = File(path.join(tempDir.path, 'pubspec.yaml'));
      androidGradleFile = File(path.join(tempDir.path, 'android', 'app', 'build.gradle'));
      
      // Create directory structure
      androidGradleFile.parent.createSync(recursive: true);
      
      versionManager = VersionManager(
        projectRoot: tempDir.path,
        enableGitIntegration: false,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should read current version from pubspec.yaml', () {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final version = versionManager.currentVersion;
      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 4);
    });

    test('should return default version when pubspec.yaml not found', () {
      final version = versionManager.currentVersion;
      expect(version.major, 1);
      expect(version.minor, 0);
      expect(version.patch, 0);
      expect(version.buildNumber, 1);
    });

    test('should increment build number', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = await versionManager.incrementBuildNumber(commitChanges: false);
      expect(newVersion.buildNumber, 5);
      expect(newVersion.major, 1);
      expect(newVersion.minor, 2);
      expect(newVersion.patch, 3);
    });

    test('should update version name', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = await versionManager.updateVersionName(
        version: '2.0.0',
        commitChanges: false,
      );
      expect(newVersion.major, 2);
      expect(newVersion.minor, 0);
      expect(newVersion.patch, 0);
      expect(newVersion.buildNumber, 4); // Preserve build number
    });

    test('should increment patch version', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = await versionManager.incrementPatch(commitChanges: false);
      expect(newVersion.major, 1);
      expect(newVersion.minor, 2);
      expect(newVersion.patch, 4);
      expect(newVersion.buildNumber, 4);
    });

    test('should increment minor version', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = await versionManager.incrementMinor(commitChanges: false);
      expect(newVersion.major, 1);
      expect(newVersion.minor, 3);
      expect(newVersion.patch, 0);
      expect(newVersion.buildNumber, 4);
    });

    test('should increment major version', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = await versionManager.incrementMajor(commitChanges: false);
      expect(newVersion.major, 2);
      expect(newVersion.minor, 0);
      expect(newVersion.patch, 0);
      expect(newVersion.buildNumber, 4);
    });

    test('should update pubspec.yaml version', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      final newVersion = VersionInfo(major: 2, minor: 0, patch: 0, buildNumber: 5);
      await versionManager.updateVersionName(version: '2.0.0', commitChanges: false);

      final updatedContent = pubspecFile.readAsStringSync();
      expect(updatedContent, contains('version: 2.0.0+5'));
    });

    test('should update Android build.gradle version', () async {
      androidGradleFile.writeAsStringSync('''
android {
    defaultConfig {
        versionCode 4
        versionName "1.2.3"
    }
}
      ''');

      final newVersion = VersionInfo(major: 2, minor: 0, patch: 0, buildNumber: 5);
      await versionManager.updateVersionName(version: '2.0.0', commitChanges: false);

      final updatedContent = androidGradleFile.readAsStringSync();
      expect(updatedContent, contains('versionCode 5'));
      expect(updatedContent, contains('versionName "2.0.0"'));
    });

    test('should handle missing Android build.gradle gracefully', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      // Should not throw exception
      await versionManager.updateVersionName(version: '2.0.0', commitChanges: false);
    });

    test('should throw exception when pubspec.yaml not found', () async {
      expect(
        () => versionManager.updateVersionName(version: '2.0.0', commitChanges: false),
        throwsA(isA<VersionManagerException>()),
      );
    });

    test('should throw exception for invalid version format', () async {
      pubspecFile.writeAsStringSync('''
name: test_app
version: 1.2.3+4
description: Test app
      ''');

      expect(
        () => versionManager.updateVersionName(version: 'invalid', commitChanges: false),
        throwsA(isA<VersionManagerException>()),
      );
    });
  });

  group('VersionManager Git Integration', () {
    late Directory tempDir;
    late VersionManager versionManager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('version_manager_git_test');
      versionManager = VersionManager(
        projectRoot: tempDir.path,
        enableGitIntegration: true,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should handle Git operations when not in Git repository', () async {
      // Should not throw exception when not in Git repository
      await versionManager.getGitCommitHash();
      await versionManager.getGitBranch();
    });

    test('should throw exception when Git integration disabled', () async {
      final manager = VersionManager(enableGitIntegration: false);
      
      expect(
        () => manager.createTag(),
        throwsA(isA<VersionManagerException>()),
      );
    });
  });
} 