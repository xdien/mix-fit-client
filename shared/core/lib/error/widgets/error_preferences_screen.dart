import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../config/error_system_config.dart';
import '../services/error_config_service.dart';
import '../stores/error_store.dart';

/// Screen for managing error system user preferences
class ErrorPreferencesScreen extends StatefulWidget {
  final IErrorConfigService configService;
  final ErrorStore errorStore;

  const ErrorPreferencesScreen({
    Key? key,
    required this.configService,
    required this.errorStore,
  }) : super(key: key);

  @override
  State<ErrorPreferencesScreen> createState() => _ErrorPreferencesScreenState();
}

class _ErrorPreferencesScreenState extends State<ErrorPreferencesScreen> {
  late ErrorUserPreferences _preferences;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _preferences = widget.configService.userPreferences;
  }

  void _updatePreferences(ErrorUserPreferences newPreferences) {
    setState(() {
      _preferences = newPreferences;
      _hasChanges = true;
    });
  }

  Future<void> _savePreferences() async {
    await widget.configService.updateUserPreferences(_preferences);
    setState(() {
      _hasChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error preferences saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('Are you sure you want to reset all error preferences to their default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.configService.resetToDefaults();
      setState(() {
        _preferences = widget.configService.userPreferences;
        _hasChanges = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Preferences'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _savePreferences,
              child: const Text('Save'),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _resetToDefaults();
                  break;
                case 'test':
                  _showTestError();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset to Defaults'),
              ),
              const PopupMenuItem(
                value: 'test',
                child: Text('Test Error Display'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDisplaySection(),
          const SizedBox(height: 24),
          _buildNotificationSection(),
          const SizedBox(height: 24),
          _buildBehaviorSection(),
          const SizedBox(height: 24),
          _buildAdvancedSection(),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Error Bar'),
              subtitle: const Text('Display errors in the top toolbar'),
              value: _preferences.showErrorBar,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(showErrorBar: value));
              },
            ),
            SwitchListTile(
              title: const Text('Show Network Status'),
              subtitle: const Text('Display network connectivity status'),
              value: _preferences.showNetworkStatus,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(showNetworkStatus: value));
              },
            ),
            ListTile(
              title: const Text('Display Position'),
              subtitle: Text(_preferences.displayPosition.name.toUpperCase()),
              trailing: DropdownButton<ErrorDisplayPosition>(
                value: _preferences.displayPosition,
                onChanged: (value) {
                  if (value != null) {
                    _updatePreferences(_preferences.copyWith(displayPosition: value));
                  }
                },
                items: ErrorDisplayPosition.values.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position.name.toUpperCase()),
                  );
                }).toList(),
              ),
            ),
            SwitchListTile(
              title: const Text('Show Detailed Errors'),
              subtitle: const Text('Include technical details in error messages'),
              value: _preferences.showDetailedErrors,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(showDetailedErrors: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Sound Notifications'),
              subtitle: const Text('Play sound when errors occur'),
              value: _preferences.enableSoundNotifications,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(enableSoundNotifications: value));
              },
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate for critical errors'),
              value: _preferences.enableVibration,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(enableVibration: value));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBehaviorSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Behavior',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-dismiss Errors'),
              subtitle: const Text('Automatically hide non-critical errors after a timeout'),
              value: _preferences.enableAutoDismiss,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(enableAutoDismiss: value));
              },
            ),
            if (_preferences.enableAutoDismiss) ...[
              const SizedBox(height: 8),
              _buildTimeoutSettings(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeoutSettings() {
    return Column(
      children: ErrorSeverity.values.where((s) => s != ErrorSeverity.critical).map((severity) {
        final currentTimeout = _preferences.customTimeouts?[severity] ?? 
                              _getDefaultTimeout(severity);
        
        return ListTile(
          title: Text('${severity.name.toUpperCase()} Timeout'),
          subtitle: Text('${currentTimeout.inSeconds} seconds'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: currentTimeout.inSeconds.toDouble(),
              min: 1,
              max: 30,
              divisions: 29,
              onChanged: (value) {
                final newTimeout = Duration(seconds: value.toInt());
                final customTimeouts = Map<ErrorSeverity, Duration>.from(
                  _preferences.customTimeouts ?? {},
                );
                customTimeouts[severity] = newTimeout;
                _updatePreferences(_preferences.copyWith(customTimeouts: customTimeouts));
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Error History'),
              subtitle: const Text('Keep a history of recent errors for debugging'),
              value: _preferences.enableErrorHistory,
              onChanged: (value) {
                _updatePreferences(_preferences.copyWith(enableErrorHistory: value));
              },
            ),
            ListTile(
              title: const Text('Current Error Count'),
              subtitle: Observer(
                builder: (_) => Text('${widget.errorStore.activeErrors.length} active errors'),
              ),
              trailing: TextButton(
                onPressed: widget.errorStore.activeErrors.isNotEmpty
                    ? () => widget.errorStore.clearAllErrors()
                    : null,
                child: const Text('Clear All'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _getDefaultTimeout(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return const Duration(seconds: 3);
      case ErrorSeverity.warning:
        return const Duration(seconds: 5);
      case ErrorSeverity.error:
        return const Duration(seconds: 10);
      case ErrorSeverity.critical:
        return Duration.zero;
    }
  }

  void _showTestError() {
    // Show a test error to demonstrate current settings
    widget.errorStore.showTestError();
  }
}