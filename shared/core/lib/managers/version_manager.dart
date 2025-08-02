import 'dart:io';
import 'dart:convert';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;

/// Manages application version and build number with automatic incrementation
/// Supports semantic versioning and Git integration
class VersionManager {
  static const String _pubspecPath = 'pubspec.yaml';
  static const String _androidBuildGradlePath = 'android/app/build.gradle';
  static const String _iosInfoPlistPath = 'ios/Runner/Info.plist';
  
  final String _projectRoot;
  final bool _enableGitIntegration;
  final bool _autoCommit;
  
  VersionManager({
    String? projectRoot,
    bool enableGitIntegration = true,
    bool autoCommit = true,
  }) : _projectRoot = projectRoot ?? Directory.current.path,
       _enableGitIntegration = enableGitIntegration,
       _autoCommit = autoCommit;

  /// Current version information
  VersionInfo get currentVersion => _readCurrentVersion();

  /// Increments build number and optionally commits changes
  Future<VersionInfo> incrementBuildNumber({
    bool commitChanges = true,
    String? commitMessage,
  }) async {
    final current = currentVersion;
    final newBuildNumber = current.buildNumber + 1;
    
    final newVersion = VersionInfo(
      major: current.major,
      minor: current.minor,
      patch: current.patch,
      buildNumber: newBuildNumber,
      preRelease: current.preRelease,
    );

    await _updateVersionFiles(newVersion);
    
    if (_enableGitIntegration && commitChanges) {
      await _commitVersionChanges(
        newVersion,
        commitMessage ?? 'chore: increment build number to ${newVersion.buildNumber}',
      );
    }

    return newVersion;
  }

  /// Updates version name according to semantic versioning
  Future<VersionInfo> updateVersionName({
    required String version,
    bool commitChanges = true,
    String? commitMessage,
  }) async {
    final newVersion = VersionInfo.fromString(version);
    final current = currentVersion;
    
    // Preserve build number if not specified in new version
    final finalVersion = VersionInfo(
      major: newVersion.major,
      minor: newVersion.minor,
      patch: newVersion.patch,
      buildNumber: newVersion.buildNumber > 0 ? newVersion.buildNumber : current.buildNumber,
      preRelease: newVersion.preRelease,
    );

    await _updateVersionFiles(finalVersion);
    
    if (_enableGitIntegration && commitChanges) {
      await _commitVersionChanges(
        finalVersion,
        commitMessage ?? 'chore: update version to ${finalVersion.versionString}',
      );
    }

    return finalVersion;
  }

  /// Increments patch version (1.0.0 -> 1.0.1)
  Future<VersionInfo> incrementPatch({
    bool commitChanges = true,
    String? commitMessage,
  }) async {
    final current = currentVersion;
    final newVersion = VersionInfo(
      major: current.major,
      minor: current.minor,
      patch: current.patch + 1,
      buildNumber: current.buildNumber,
      preRelease: current.preRelease,
    );

    return await updateVersionName(
      version: newVersion.versionString,
      commitChanges: commitChanges,
      commitMessage: commitMessage ?? 'chore: bump patch version to ${newVersion.versionString}',
    );
  }

  /// Increments minor version (1.0.0 -> 1.1.0)
  Future<VersionInfo> incrementMinor({
    bool commitChanges = true,
    String? commitMessage,
  }) async {
    final current = currentVersion;
    final newVersion = VersionInfo(
      major: current.major,
      minor: current.minor + 1,
      patch: 0,
      buildNumber: current.buildNumber,
      preRelease: current.preRelease,
    );

    return await updateVersionName(
      version: newVersion.versionString,
      commitChanges: commitChanges,
      commitMessage: commitMessage ?? 'chore: bump minor version to ${newVersion.versionString}',
    );
  }

  /// Increments major version (1.0.0 -> 2.0.0)
  Future<VersionInfo> incrementMajor({
    bool commitChanges = true,
    String? commitMessage,
  }) async {
    final current = currentVersion;
    final newVersion = VersionInfo(
      major: current.major + 1,
      minor: 0,
      patch: 0,
      buildNumber: current.buildNumber,
      preRelease: current.preRelease,
    );

    return await updateVersionName(
      version: newVersion.versionString,
      commitChanges: commitChanges,
      commitMessage: commitMessage ?? 'chore: bump major version to ${newVersion.versionString}',
    );
  }

  /// Creates a Git tag for the current version
  Future<void> createTag({
    String? tagMessage,
    bool pushTag = true,
  }) async {
    if (!_enableGitIntegration) {
      throw VersionManagerException('Git integration is disabled');
    }

    final current = currentVersion;
    final tagName = 'v${current.versionString}';
    final message = tagMessage ?? 'Release version ${current.versionString}';

    try {
      // Create tag
      final result = await Process.run('git', ['tag', '-a', tagName, '-m', message]);
      
      if (result.exitCode != 0) {
        throw VersionManagerException('Failed to create tag: ${result.stderr}');
      }

      // Push tag if requested
      if (pushTag) {
        final pushResult = await Process.run('git', ['push', 'origin', tagName]);
        if (pushResult.exitCode != 0) {
          throw VersionManagerException('Failed to push tag: ${pushResult.stderr}');
        }
      }

      print('✅ Created tag: $tagName');
    } catch (e) {
      throw VersionManagerException('Failed to create tag: $e');
    }
  }

  /// Validates version format
  bool isValidVersion(String version) {
    try {
      VersionInfo.fromString(version);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reads current version from all configuration files
  VersionInfo _readCurrentVersion() {
    try {
      // Read from pubspec.yaml first
      final pubspecFile = File(path.join(_projectRoot, _pubspecPath));
      if (pubspecFile.existsSync()) {
        final content = pubspecFile.readAsStringSync();
        final yaml = loadYaml(content);
        final versionString = yaml['version'] as String?;
        
        if (versionString != null) {
          return VersionInfo.fromString(versionString);
        }
      }
    } catch (e) {
      print('Warning: Could not read version from pubspec.yaml: $e');
    }

    // Fallback to default version
    return VersionInfo(major: 1, minor: 0, patch: 0, buildNumber: 1);
  }

  /// Updates version in all configuration files
  Future<void> _updateVersionFiles(VersionInfo version) async {
    await _updatePubspecYaml(version);
    await _updateAndroidBuildGradle(version);
    await _updateIosInfoPlist(version);
  }

  /// Updates version in pubspec.yaml
  Future<void> _updatePubspecYaml(VersionInfo version) async {
    final pubspecFile = File(path.join(_projectRoot, _pubspecPath));
    if (!pubspecFile.existsSync()) {
      throw VersionManagerException('pubspec.yaml not found');
    }

    final content = pubspecFile.readAsStringSync();
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('version:')) {
        lines[i] = 'version: ${version.versionString}+${version.buildNumber}';
        break;
      }
    }

    await pubspecFile.writeAsString(lines.join('\n'));
    print('✅ Updated pubspec.yaml version to ${version.versionString}+${version.buildNumber}');
  }

  /// Updates version in Android build.gradle
  Future<void> _updateAndroidBuildGradle(VersionInfo version) async {
    final gradleFile = File(path.join(_projectRoot, _androidBuildGradlePath));
    if (!gradleFile.existsSync()) {
      print('⚠️  Android build.gradle not found, skipping Android version update');
      return;
    }

    final content = gradleFile.readAsStringSync();
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('versionCode')) {
        lines[i] = '        versionCode ${version.buildNumber}';
      } else if (line.startsWith('versionName')) {
        lines[i] = '        versionName "${version.versionString}"';
      }
    }

    await gradleFile.writeAsString(lines.join('\n'));
    print('✅ Updated Android build.gradle version to ${version.versionString} (${version.buildNumber})');
  }

  /// Updates version in iOS Info.plist
  Future<void> _updateIosInfoPlist(VersionInfo version) async {
    final plistFile = File(path.join(_projectRoot, _iosInfoPlistPath));
    if (!plistFile.existsSync()) {
      print('⚠️  iOS Info.plist not found, skipping iOS version update');
      return;
    }

    final content = plistFile.readAsStringSync();
    final lines = content.split('\n');
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.contains('<key>CFBundleShortVersionString</key>')) {
        if (i + 1 < lines.length) {
          lines[i + 1] = '\t<string>${version.versionString}</string>';
        }
      } else if (line.contains('<key>CFBundleVersion</key>')) {
        if (i + 1 < lines.length) {
          lines[i + 1] = '\t<string>${version.buildNumber}</string>';
        }
      }
    }

    await plistFile.writeAsString(lines.join('\n'));
    print('✅ Updated iOS Info.plist version to ${version.versionString} (${version.buildNumber})');
  }

  /// Commits version changes to Git
  Future<void> _commitVersionChanges(VersionInfo version, String message) async {
    if (!_enableGitIntegration) return;

    try {
      // Check if we're in a Git repository
      final gitCheck = await Process.run('git', ['rev-parse', '--git-dir']);
      if (gitCheck.exitCode != 0) {
        print('⚠️  Not in a Git repository, skipping commit');
        return;
      }

      // Add modified files
      final addResult = await Process.run('git', ['add', _pubspecPath, _androidBuildGradlePath, _iosInfoPlistPath]);
      if (addResult.exitCode != 0) {
        throw VersionManagerException('Failed to add files: ${addResult.stderr}');
      }

      // Commit changes
      final commitResult = await Process.run('git', ['commit', '-m', message]);
      if (commitResult.exitCode != 0) {
        throw VersionManagerException('Failed to commit changes: ${commitResult.stderr}');
      }

      print('✅ Committed version changes: $message');
    } catch (e) {
      throw VersionManagerException('Failed to commit version changes: $e');
    }
  }

  /// Gets Git commit hash for current version
  Future<String?> getGitCommitHash() async {
    if (!_enableGitIntegration) return null;

    try {
      final result = await Process.run('git', ['rev-parse', 'HEAD']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      print('Warning: Could not get Git commit hash: $e');
    }
    return null;
  }

  /// Gets Git branch name
  Future<String?> getGitBranch() async {
    if (!_enableGitIntegration) return null;

    try {
      final result = await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    } catch (e) {
      print('Warning: Could not get Git branch: $e');
    }
    return null;
  }
}

/// Represents version information with semantic versioning support
class VersionInfo {
  final int major;
  final int minor;
  final int patch;
  final int buildNumber;
  final String? preRelease;

  const VersionInfo({
    required this.major,
    required this.minor,
    required this.patch,
    required this.buildNumber,
    this.preRelease,
  });

  /// Creates VersionInfo from version string (e.g., "1.2.3", "1.2.3-beta.1")
  factory VersionInfo.fromString(String version) {
    final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:-(.+))?$');
    final match = regex.firstMatch(version);
    
    if (match == null) {
      throw VersionManagerException('Invalid version format: $version');
    }

    return VersionInfo(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      buildNumber: 1, // Default build number
      preRelease: match.group(4),
    );
  }

  /// Creates VersionInfo from Flutter version string (e.g., "1.2.3+4")
  factory VersionInfo.fromFlutterVersion(String version) {
    final parts = version.split('+');
    if (parts.length != 2) {
      throw VersionManagerException('Invalid Flutter version format: $version');
    }

    final versionInfo = VersionInfo.fromString(parts[0]);
    final buildNumber = int.parse(parts[1]);

    return VersionInfo(
      major: versionInfo.major,
      minor: versionInfo.minor,
      patch: versionInfo.patch,
      buildNumber: buildNumber,
      preRelease: versionInfo.preRelease,
    );
  }

  /// Version string without build number (e.g., "1.2.3")
  String get versionString {
    final base = '$major.$minor.$patch';
    return preRelease != null ? '$base-$preRelease' : base;
  }

  /// Flutter version string (e.g., "1.2.3+4")
  String get flutterVersionString => '$versionString+$buildNumber';

  /// Full version string with all components
  String get fullVersionString => '$versionString+$buildNumber';

  /// Checks if this is a pre-release version
  bool get isPreRelease => preRelease != null;

  /// Checks if this is a stable release
  bool get isStable => !isPreRelease;

  /// Compares this version with another
  int compareTo(VersionInfo other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    
    // Pre-release versions are considered less than stable versions
    if (isPreRelease && !other.isPreRelease) return -1;
    if (!isPreRelease && other.isPreRelease) return 1;
    
    return buildNumber.compareTo(other.buildNumber);
  }

  @override
  String toString() => fullVersionString;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VersionInfo &&
          major == other.major &&
          minor == other.minor &&
          patch == other.patch &&
          buildNumber == other.buildNumber &&
          preRelease == other.preRelease;

  @override
  int get hashCode =>
      major.hashCode ^
      minor.hashCode ^
      patch.hashCode ^
      buildNumber.hashCode ^
      preRelease.hashCode;
}

/// Exception thrown by VersionManager
class VersionManagerException implements Exception {
  final String message;

  const VersionManagerException(this.message);

  @override
  String toString() => 'VersionManagerException: $message';
} 