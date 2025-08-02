import 'package:flutter/material.dart';
import '../app_config.dart';

/// Example demonstrating how to use the integrated configuration system
class ConfigurationIntegrationExample extends StatefulWidget {
  const ConfigurationIntegrationExample({Key? key}) : super(key: key);

  @override
  State<ConfigurationIntegrationExample> createState() => _ConfigurationIntegrationExampleState();
}

class _ConfigurationIntegrationExampleState extends State<ConfigurationIntegrationExample> {
  final ConfigIntegrationHelper _integrationHelper = ConfigIntegrationHelper();
  final LegacyConfigAdapter _legacyAdapter = LegacyConfigAdapter();
  final AppConfig _legacyConfig = AppConfig();
  
  Map<String, dynamic>? _configSummary;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeConfiguration();
  }

  Future<void> _initializeConfiguration() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Initialize the integration helper
      await _integrationHelper.initialize('development');
      
      // Also initialize legacy config for comparison
      await _legacyConfig.load('development');

      // Get configuration summary
      final summary = _integrationHelper.getConfigurationSummary();
      
      setState(() {
        _configSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Integration Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _initializeConfiguration,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConfigurationCard(),
                      const SizedBox(height: 16),
                      _buildLegacyConfigCard(),
                      const SizedBox(height: 16),
                      _buildAdapterCard(),
                      const SizedBox(height: 16),
                      _buildActionsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_configSummary != null) ...[
              _buildConfigItem('Environment Available', _configSummary!['environmentConfigAvailable']),
              _buildConfigItem('API Base URL', _configSummary!['apiBaseUrl']),
              _buildConfigItem('WebSocket URL', _configSummary!['websocketUrl']),
              _buildConfigItem('App Name', _configSummary!['appName']),
              _buildConfigItem('Bundle ID', _configSummary!['bundleId']),
              _buildConfigItem('Environment', _configSummary!['environmentName']),
              _buildConfigItem('Timeout', '${_configSummary!['timeout']}ms'),
              _buildConfigItem('Debug Mode', _configSummary!['debugMode']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyConfigCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legacy Configuration (Backward Compatibility)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildConfigItem('Endpoint', _legacyConfig.endpoint),
            _buildConfigItem('API Key', _legacyConfig.apiKey.isNotEmpty ? '***' : 'Not set'),
            _buildConfigItem('Debug Mode', _legacyConfig.debugMode),
            _buildConfigItem('Is Loaded', _legacyConfig.isLoaded),
          ],
        ),
      ),
    );
  }

  Widget _buildAdapterCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legacy Adapter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildConfigItem('Endpoint', _legacyAdapter.endpoint),
            _buildConfigItem('WebSocket URL', _legacyAdapter.websocketUrl),
            _buildConfigItem('App Name', _legacyAdapter.appName),
            _buildConfigItem('Bundle ID', _legacyAdapter.bundleId),
            _buildConfigItem('Environment', _legacyAdapter.environmentName),
            _buildConfigItem('Timeout', '${_legacyAdapter.timeout}ms'),
            _buildConfigItem('Debug Mode', _legacyAdapter.debugMode),
            _buildConfigItem('Is Configured', _legacyAdapter.isConfigured),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _initializeConfiguration,
                  child: const Text('Reload Config'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _validateConfiguration,
                  child: const Text('Validate'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showDebugInfo,
                  child: const Text('Debug Info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            child: Text(
              value.toString(),
              style: TextStyle(
                color: value is bool
                    ? (value ? Colors.green : Colors.red)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateConfiguration() async {
    try {
      final isValid = await _integrationHelper.validateConfiguration();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid ? 'Configuration is valid' : 'Configuration validation failed',
            ),
            backgroundColor: isValid ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Integration Helper:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_integrationHelper.toString()),
              const SizedBox(height: 16),
              const Text('Legacy Adapter:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_legacyAdapter.toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Usage example for API client integration
class ApiClientIntegrationExample {
  static void demonstrateApiClientIntegration() {
    // Example of how to use the integrated configuration in API client
    final integrationHelper = ConfigIntegrationHelper();
    
    // Get API base URL (with fallback chain)
    final apiBaseUrl = integrationHelper.getApiBaseUrl();
    print('API Base URL: $apiBaseUrl');
    
    // Get WebSocket URL (with fallback chain)
    final websocketUrl = integrationHelper.getWebSocketUrl();
    print('WebSocket URL: $websocketUrl');
    
    // Get timeout configuration
    final timeout = integrationHelper.getTimeout();
    print('Network Timeout: ${timeout}ms');
    
    // Check if debug mode is enabled
    final isDebug = integrationHelper.isDebugMode();
    print('Debug Mode: $isDebug');
    
    // Example of using with Dio configuration
    /*
    final dioConfig = DioConfigs(
      baseUrl: apiBaseUrl,
      connectionTimeout: timeout,
      receiveTimeout: timeout,
    );
    */
    
    // Example of using with WebSocket service
    /*
    final socketService = SocketService(
      url: websocketUrl ?? apiBaseUrl,
      tokenProvider: () async => await getToken(),
    );
    */
  }
}

/// Usage example for legacy compatibility
class LegacyCompatibilityExample {
  static Future<void> demonstrateLegacyCompatibility() async {
    // Legacy AppConfig usage (still works)
    final legacyConfig = AppConfig();
    await legacyConfig.load('development');
    
    print('Legacy Endpoint: ${legacyConfig.endpoint}');
    print('Legacy Debug Mode: ${legacyConfig.debugMode}');
    
    // New environment configuration usage
    final configService = EnvironmentConfigService();
    await configService.initialize('development');
    
    print('New API Base URL: ${configService.apiBaseUrl}');
    print('New App Name: ${configService.appName}');
    
    // Both should provide the same values (with fallback)
    assert(legacyConfig.endpoint == configService.apiBaseUrl);
  }
}