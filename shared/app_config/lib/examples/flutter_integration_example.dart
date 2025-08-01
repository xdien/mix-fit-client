import 'package:flutter/material.dart';
import '../config/build_config_factory.dart';
import '../config/build_config_manager.dart';
import '../services/environment_config_service.dart';

/// Example of integrating BuildConfigManager with Flutter app
class FlutterIntegrationExample extends StatefulWidget {
  const FlutterIntegrationExample({super.key});

  @override
  State<FlutterIntegrationExample> createState() => _FlutterIntegrationExampleState();
}

class _FlutterIntegrationExampleState extends State<FlutterIntegrationExample> {
  BuildConfigManager? _buildConfigManager;
  String _status = 'Initializing...';
  Map<String, dynamic>? _buildSettings;

  @override
  void initState() {
    super.initState();
    _initializeBuildConfig();
  }

  Future<void> _initializeBuildConfig() async {
    try {
      setState(() {
        _status = 'Loading configuration...';
      });

      // Initialize environment config service first
      final configService = EnvironmentConfigService();
      await configService.initialize();

      // Create build config manager
      final factory = BuildConfigFactory.instance;
      _buildConfigManager = factory.createFromEnvironmentConfig(
        configService.config,
      );

      // Get build settings
      _buildSettings = _buildConfigManager!.getBuildSettings();

      setState(() {
        _status = 'Configuration loaded successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to load configuration: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build Configuration Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_buildConfigManager != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Build Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow('Application ID', _buildConfigManager!.applicationId),
                      _buildInfoRow('Application Name', _buildConfigManager!.applicationName),
                      _buildInfoRow('Display Name', _buildConfigManager!.displayName),
                      _buildInfoRow('Environment', _buildConfigManager!.flavor),
                      _buildInfoRow('Build Variant', _buildConfigManager!.buildVariant),
                      _buildInfoRow('Build Type', _buildConfigManager!.buildType),
                      _buildInfoRow('Version', '${_buildConfigManager!.versionName} (${_buildConfigManager!.versionCode})'),
                      _buildInfoRow('Debug Build', _buildConfigManager!.isDebugBuild.toString()),
                      _buildInfoRow('Should Obfuscate', _buildConfigManager!.shouldObfuscate.toString()),
                      _buildInfoRow('Shrink Resources', _buildConfigManager!.shouldShrinkResources.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: _validateConfiguration,
                            child: const Text('Validate Config'),
                          ),
                          ElevatedButton(
                            onPressed: _showEnvironmentVariables,
                            child: const Text('Show Env Vars'),
                          ),
                          ElevatedButton(
                            onPressed: _showGradleProperties,
                            child: const Text('Show Gradle Props'),
                          ),
                          ElevatedButton(
                            onPressed: _switchBuildVariant,
                            child: const Text('Switch Variant'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _validateConfiguration() {
    if (_buildConfigManager == null) return;

    final result = _buildConfigManager!.validateConfiguration();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration Validation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valid: ${result.isValid}'),
            if (result.hasErrors) ...[
              const SizedBox(height: 8),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error')),
            ],
            if (result.hasWarnings) ...[
              const SizedBox(height: 8),
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.warnings.map((warning) => Text('• $warning')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEnvironmentVariables() {
    if (_buildConfigManager == null) return;

    final envVars = _buildConfigManager!.generateEnvironmentVariables();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Environment Variables'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: envVars.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text('${entry.key}=${entry.value}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGradleProperties() {
    if (_buildConfigManager == null) return;

    final gradleProps = _buildConfigManager!.generateGradleProperties();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gradle Properties'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: gradleProps.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text('${entry.key}=${entry.value}'),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _switchBuildVariant() {
    if (_buildConfigManager == null) return;

    final currentVariant = _buildConfigManager!.buildVariant;
    final newVariant = currentVariant == 'debug' ? 'release' : 'debug';
    final newDebugMode = newVariant == 'debug';

    setState(() {
      _buildConfigManager = _buildConfigManager!.copyWith(
        buildVariant: newVariant,
        isDebugMode: newDebugMode,
      );
      _buildSettings = _buildConfigManager!.getBuildSettings();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to $newVariant variant'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Example app that demonstrates BuildConfigManager integration
class BuildConfigExampleApp extends StatelessWidget {
  const BuildConfigExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Build Config Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FlutterIntegrationExample(),
    );
  }
}

/// Service class that demonstrates how to use BuildConfigManager in a service
class AppConfigurationService {
  static final AppConfigurationService _instance = AppConfigurationService._internal();
  factory AppConfigurationService() => _instance;
  AppConfigurationService._internal();

  BuildConfigManager? _buildConfigManager;
  bool _isInitialized = false;

  /// Initialize the service with build configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize environment config service
      final configService = EnvironmentConfigService();
      await configService.initialize();

      // Create build config manager
      final factory = BuildConfigFactory.instance;
      _buildConfigManager = factory.createFromEnvironmentConfig(
        configService.config,
      );

      _isInitialized = true;
      debugPrint('AppConfigurationService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AppConfigurationService: $e');
      rethrow;
    }
  }

  /// Get the build configuration manager
  BuildConfigManager get buildConfig {
    if (!_isInitialized || _buildConfigManager == null) {
      throw StateError('AppConfigurationService not initialized. Call initialize() first.');
    }
    return _buildConfigManager!;
  }

  /// Check if the service is initialized
  bool get isInitialized => _isInitialized;

  /// Get application information
  Map<String, String> getApplicationInfo() {
    return {
      'name': buildConfig.applicationName,
      'id': buildConfig.applicationId,
      'version': buildConfig.versionName,
      'build': buildConfig.versionCode.toString(),
      'environment': buildConfig.flavor,
      'variant': buildConfig.buildVariant,
    };
  }

  /// Check if this is a debug build
  bool get isDebugBuild => buildConfig.isDebugBuild;

  /// Check if this is a production environment
  bool get isProduction => buildConfig.flavor == 'production';

  /// Get API configuration
  Map<String, String> getApiConfiguration() {
    final envVars = buildConfig.generateEnvironmentVariables();
    return {
      'baseUrl': envVars['FLUTTER_API_BASE_URL'] ?? '',
      'websocketUrl': envVars['FLUTTER_WEBSOCKET_URL'] ?? '',
      'timeout': envVars['FLUTTER_NETWORK_TIMEOUT'] ?? '30000',
    };
  }

  /// Reset the service (for testing)
  void reset() {
    _buildConfigManager = null;
    _isInitialized = false;
  }
}