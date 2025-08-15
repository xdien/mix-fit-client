import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/environment_config_service.dart';
import '../loaders/environment_config_loader.dart';
import '../configured_app.dart';

/// Example demonstrating how to use the EnvironmentConfigService
class EnvironmentConfigUsageExample {
  
  /// Example 1: Basic initialization and usage
  static Future<void> basicUsage() async {
    // Initialize the service
    final service = EnvironmentConfigService();
    await service.initialize('development');
    
    // Access configuration properties
    print('Environment: ${service.environmentName}');
    print('App Name: ${service.appName}');
    print('API URL: ${service.apiBaseUrl}');
    print('WebSocket URL: ${service.websocketUrl}');
    print('Is Debug Mode: ${service.isDebugMode}');
    print('Is Production: ${service.isProduction}');
  }
  
  /// Example 2: Using with dependency injection
  static Future<void> dependencyInjectionUsage() async {
    final getIt = GetIt.instance;
    
    // Register the service as singleton
    getIt.registerSingleton<EnvironmentConfigService>(
      EnvironmentConfigService(),
    );
    
    // Register the loader
    getIt.registerSingleton<EnvironmentConfigLoader>(
      YamlEnvironmentConfigLoader(),
    );
    
    // Initialize the service
    await getIt<EnvironmentConfigService>().initialize('production');
    
    // Access through dependency injection
    final service = getIt<EnvironmentConfigService>();
    print('Environment: ${service.environmentName}');
    print('Bundle ID: ${service.bundleId}');
  }
  
  /// Example 3: Using with ConfiguredApp widget
  static Widget configuredAppUsage() {
    return ConfiguredApp(
      environment: 'staging',
      useNewConfigSystem: true,
      builder: (context) => MaterialApp(
        title: EnvironmentConfigService().appName,
        home: Scaffold(
          appBar: AppBar(
            title: Text(EnvironmentConfigService().appName),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Environment: ${EnvironmentConfigService().environmentName}'),
                Text('API URL: ${EnvironmentConfigService().apiBaseUrl}'),
                Text('Version: ${EnvironmentConfigService().versionName ?? 'N/A'}'),
                if (EnvironmentConfigService().isDebugMode)
                  const Text(
                    'DEBUG MODE',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Example 4: Environment-specific configuration
  static Future<void> environmentSpecificUsage() async {
    final service = EnvironmentConfigService();
    
    // Initialize with different environments
    await service.initialize('development');
    
    if (service.isDebugMode) {
      print('Development mode - enabling debug features');
      // Enable debug logging, show debug info, etc.
    } else if (service.isStaging) {
      print('Staging mode - limited debug features');
      // Enable some debug features for testing
    } else if (service.isProduction) {
      print('Production mode - all debug features disabled');
      // Disable all debug features
    }
    
    // Access build configuration
    final buildConfig = service.buildConfig;
    if (buildConfig != null) {
      print('Build Type: ${buildConfig.buildType}');
      print('Obfuscated: ${buildConfig.obfuscate}');
      print('Shrink Resources: ${buildConfig.shrinkResources}');
    }
  }
  
  /// Example 5: Validation and error handling
  static Future<void> validationExample() async {
    final service = EnvironmentConfigService();
    
    try {
      await service.initialize('production');
      
      // Validate the current configuration
      final isValid = await service.validateCurrentConfig();
      if (isValid) {
        print('Configuration is valid');
      } else {
        print('Configuration validation failed');
        // Handle invalid configuration
      }
      
    } catch (e) {
      print('Failed to initialize configuration: $e');
      // Handle initialization error
      // Service will fall back to default configuration
    }
  }
  
  /// Example 6: Using configuration for HTTP client setup
  static Future<void> httpClientSetup() async {
    final service = EnvironmentConfigService();
    await service.initialize();
    
    // Use configuration for HTTP client
    final baseUrl = service.apiBaseUrl;
    final timeout = Duration(milliseconds: service.timeout);
    
    print('Setting up HTTP client with:');
    print('Base URL: $baseUrl');
    print('Timeout: ${timeout.inSeconds}s');
    
    // Example: Configure Dio client
    // final dio = Dio(BaseOptions(
    //   baseUrl: baseUrl,
    //   connectTimeout: timeout,
    //   receiveTimeout: timeout,
    // ));
  }
  
  /// Example 7: Using configuration for WebSocket connection
  static Future<void> websocketSetup() async {
    final service = EnvironmentConfigService();
    await service.initialize();
    
    final websocketUrl = service.websocketUrl;
    if (websocketUrl != null) {
      print('Connecting to WebSocket: $websocketUrl');
      // Example: Setup WebSocket connection
      // final channel = WebSocketChannel.connect(Uri.parse(websocketUrl));
    } else {
      print('WebSocket URL not configured');
    }
  }
  
  /// Example 8: Configuration debugging
  static Future<void> debugConfiguration() async {
    final service = EnvironmentConfigService();
    await service.initialize();
    
    // Get configuration as JSON for debugging
    final configJson = service.toJson();
    print('Current configuration:');
    print(configJson);
    
    // Print service information
    print('Service info: ${service.toString()}');
    
    // Check initialization status
    print('Is initialized: ${service.isInitialized}');
    print('Current environment: ${service.currentEnvironment}');
  }
  
  /// Example 9: Reloading configuration
  static Future<void> reloadExample() async {
    final service = EnvironmentConfigService();
    await service.initialize('development');
    
    print('Initial environment: ${service.environmentName}');
    
    // Reload configuration
    print('\n--- Reloading Configuration ---');
    await service.reload();
    print('Configuration reloaded');
  }
  
  /// Example 10: Using with custom loader (for testing)
  static Future<void> customLoaderExample() async {
    final service = EnvironmentConfigService();
    final customLoader = YamlEnvironmentConfigLoader();
    
    // Initialize with custom loader
    await service.initializeWithLoader(customLoader, 'development');
    
    print('Initialized with custom loader');
    print('Environment: ${service.environmentName}');
  }
}

/// Example widget that uses environment configuration
class EnvironmentInfoWidget extends StatelessWidget {
  const EnvironmentInfoWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final service = EnvironmentConfigService();
    
    if (!service.isInitialized) {
      return const Center(
        child: Text('Environment not initialized'),
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Environment Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Environment', service.environmentName),
            _buildInfoRow('Display Name', service.environmentDisplayName),
            _buildInfoRow('App Name', service.appName),
            _buildInfoRow('Bundle ID', service.bundleId),
            _buildInfoRow('API URL', service.apiBaseUrl),
            if (service.websocketUrl != null)
              _buildInfoRow('WebSocket URL', service.websocketUrl!),
            _buildInfoRow('Version', service.versionName ?? 'N/A'),
            _buildInfoRow('Build Code', service.versionCode?.toString() ?? 'N/A'),
            _buildInfoRow('Timeout', '${service.timeout}ms'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                if (service.isDebugMode)
                  const Chip(
                    label: Text('DEBUG'),
                    backgroundColor: Colors.orange,
                  ),
                if (service.isStaging)
                  const Chip(
                    label: Text('STAGING'),
                    backgroundColor: Colors.blue,
                  ),
                if (service.isProduction)
                  const Chip(
                    label: Text('PRODUCTION'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}