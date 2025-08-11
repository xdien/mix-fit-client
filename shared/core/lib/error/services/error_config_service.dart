import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/error_system_config.dart';

/// Service for managing error system configuration and user preferences
abstract class IErrorConfigService {
  /// Gets the current error system configuration
  ErrorSystemConfig get config;

  /// Gets the current user preferences
  ErrorUserPreferences get userPreferences;

  /// Updates the error system configuration
  Future<void> updateConfig(ErrorSystemConfig newConfig);

  /// Updates user preferences
  Future<void> updateUserPreferences(ErrorUserPreferences newPreferences);

  /// Resets configuration to defaults
  Future<void> resetToDefaults();

  /// Stream of configuration changes
  Stream<ErrorSystemConfig> get configStream;

  /// Stream of user preference changes
  Stream<ErrorUserPreferences> get userPreferencesStream;
}

/// Implementation of error configuration service
class ErrorConfigService implements IErrorConfigService {
  static const String _configKey = 'error_system_config';
  static const String _userPreferencesKey = 'error_user_preferences';

  ErrorSystemConfig _config;
  ErrorUserPreferences _userPreferences;
  SharedPreferences? _prefs;

  final _configController = StreamController<ErrorSystemConfig>.broadcast();
  final _userPreferencesController = StreamController<ErrorUserPreferences>.broadcast();

  ErrorConfigService({
    ErrorSystemConfig? initialConfig,
    ErrorUserPreferences? initialUserPreferences,
  }) : _config = initialConfig ?? _getDefaultConfig(),
       _userPreferences = initialUserPreferences ?? const ErrorUserPreferences() {
    _initializePreferences();
  }

  @override
  ErrorSystemConfig get config => _config;

  @override
  ErrorUserPreferences get userPreferences => _userPreferences;

  @override
  Stream<ErrorSystemConfig> get configStream => _configController.stream;

  @override
  Stream<ErrorUserPreferences> get userPreferencesStream => _userPreferencesController.stream;

  @override
  Future<void> updateConfig(ErrorSystemConfig newConfig) async {
    _config = newConfig;
    _configController.add(_config);
    await _saveConfig();
  }

  @override
  Future<void> updateUserPreferences(ErrorUserPreferences newPreferences) async {
    _userPreferences = newPreferences;
    _userPreferencesController.add(_userPreferences);
    await _saveUserPreferences();
    
    // Update config with user preferences
    final updatedConfig = _config.copyWith(
      userPreferences: newPreferences,
      showErrorBarByDefault: newPreferences.showErrorBar,
      showNetworkStatus: newPreferences.showNetworkStatus,
      autoDismissTimeouts: newPreferences.customTimeouts ?? _config.autoDismissTimeouts,
    );
    
    if (updatedConfig != _config) {
      await updateConfig(updatedConfig);
    }
  }

  @override
  Future<void> resetToDefaults() async {
    final defaultConfig = _getDefaultConfig();
    const defaultPreferences = ErrorUserPreferences();
    
    await updateConfig(defaultConfig);
    await updateUserPreferences(defaultPreferences);
  }

  /// Initializes shared preferences and loads saved configuration
  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadConfig();
      await _loadUserPreferences();
    } catch (e) {
      debugPrint('Failed to initialize error config service: $e');
    }
  }

  /// Loads configuration from shared preferences
  Future<void> _loadConfig() async {
    if (_prefs == null) return;

    try {
      final configJson = _prefs!.getString(_configKey);
      if (configJson != null) {
        final configData = jsonDecode(configJson) as Map<String, dynamic>;
        _config = _parseConfigFromJson(configData);
        _configController.add(_config);
      }
    } catch (e) {
      debugPrint('Failed to load error config: $e');
    }
  }

  /// Loads user preferences from shared preferences
  Future<void> _loadUserPreferences() async {
    if (_prefs == null) return;

    try {
      final preferencesJson = _prefs!.getString(_userPreferencesKey);
      if (preferencesJson != null) {
        final preferencesData = jsonDecode(preferencesJson) as Map<String, dynamic>;
        _userPreferences = ErrorUserPreferences.fromJson(preferencesData);
        _userPreferencesController.add(_userPreferences);
      }
    } catch (e) {
      debugPrint('Failed to load user preferences: $e');
    }
  }

  /// Saves configuration to shared preferences
  Future<void> _saveConfig() async {
    if (_prefs == null) return;

    try {
      final configJson = jsonEncode(_configToJson(_config));
      await _prefs!.setString(_configKey, configJson);
    } catch (e) {
      debugPrint('Failed to save error config: $e');
    }
  }

  /// Saves user preferences to shared preferences
  Future<void> _saveUserPreferences() async {
    if (_prefs == null) return;

    try {
      final preferencesJson = jsonEncode(_userPreferences.toJson());
      await _prefs!.setString(_userPreferencesKey, preferencesJson);
    } catch (e) {
      debugPrint('Failed to save user preferences: $e');
    }
  }

  /// Gets default configuration based on build mode
  static ErrorSystemConfig _getDefaultConfig() {
    if (kDebugMode) {
      return ErrorSystemConfig.development;
    } else if (kProfileMode) {
      return ErrorSystemConfig.production.copyWith(
        showErrorDetailsInDebug: true,
      );
    } else {
      return ErrorSystemConfig.production;
    }
  }

  /// Converts configuration to JSON for storage
  Map<String, dynamic> _configToJson(ErrorSystemConfig config) {
    return {
      'maxErrorQueueSize': config.maxErrorQueueSize,
      'autoDismissTimeouts': config.autoDismissTimeouts.map(
        (key, value) => MapEntry(key.name, value.inMilliseconds),
      ),
      'showErrorBarByDefault': config.showErrorBarByDefault,
      'showNetworkStatus': config.showNetworkStatus,
      'enableErrorLogging': config.enableErrorLogging,
      'maxErrorHistorySize': config.maxErrorHistorySize,
      'showErrorDetailsInDebug': config.showErrorDetailsInDebug,
      'enableErrorAnalytics': config.enableErrorAnalytics,
      'userPreferences': config.userPreferences.toJson(),
    };
  }

  /// Parses configuration from JSON
  ErrorSystemConfig _parseConfigFromJson(Map<String, dynamic> json) {
    final autoDismissTimeouts = <ErrorSeverity, Duration>{};
    if (json['autoDismissTimeouts'] != null) {
      (json['autoDismissTimeouts'] as Map<String, dynamic>).forEach((key, value) {
        final severity = ErrorSeverity.values.firstWhere((e) => e.name == key);
        autoDismissTimeouts[severity] = Duration(milliseconds: value);
      });
    }

    final userPreferences = json['userPreferences'] != null
        ? ErrorUserPreferences.fromJson(json['userPreferences'])
        : const ErrorUserPreferences();

    return ErrorSystemConfig(
      maxErrorQueueSize: json['maxErrorQueueSize'] ?? 5,
      autoDismissTimeouts: autoDismissTimeouts.isNotEmpty 
          ? autoDismissTimeouts 
          : const {
              ErrorSeverity.info: Duration(seconds: 3),
              ErrorSeverity.warning: Duration(seconds: 5),
              ErrorSeverity.error: Duration(seconds: 10),
              ErrorSeverity.critical: Duration.zero,
            },
      showErrorBarByDefault: json['showErrorBarByDefault'] ?? true,
      showNetworkStatus: json['showNetworkStatus'] ?? true,
      enableErrorLogging: json['enableErrorLogging'] ?? true,
      maxErrorHistorySize: json['maxErrorHistorySize'] ?? 50,
      showErrorDetailsInDebug: json['showErrorDetailsInDebug'] ?? kDebugMode,
      enableErrorAnalytics: json['enableErrorAnalytics'] ?? !kDebugMode,
      userPreferences: userPreferences,
    );
  }

  /// Disposes the service and closes streams
  void dispose() {
    _configController.close();
    _userPreferencesController.close();
  }
}

/// Extension methods for error configuration
extension ErrorConfigExtensions on ErrorSystemConfig {
  /// Gets the auto-dismiss timeout for a specific error severity
  Duration getAutoDismissTimeout(ErrorSeverity severity) {
    return userPreferences.customTimeouts?[severity] ?? 
           autoDismissTimeouts[severity] ?? 
           const Duration(seconds: 5);
  }

  /// Checks if auto-dismiss is enabled for a specific severity
  bool shouldAutoDismiss(ErrorSeverity severity) {
    return userPreferences.enableAutoDismiss && 
           getAutoDismissTimeout(severity) > Duration.zero;
  }

  /// Gets the theme configuration based on current theme mode
  ErrorThemeConfig getThemeConfig(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.dark:
        return ErrorThemeConfig.dark;
      case ThemeMode.light:
        return themeConfig;
      case ThemeMode.system:
        // This would need to be determined by the system theme
        return themeConfig;
    }
  }
}