import 'package:flutter/material.dart';
import '../app_config.dart';

/// Example of how to use the new environment configuration system
class EnvironmentConfigExample extends StatefulWidget {
  @override
  _EnvironmentConfigExampleState createState() => _EnvironmentConfigExampleState();
}

class _EnvironmentConfigExampleState extends State<EnvironmentConfigExample> {
  final _configService = EnvironmentConfigService();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    try {
      await _configService.initialize('development');
      setState(() {
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Environment Config Example')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Environment Config Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text('Error: $_error'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializeConfig();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Environment Config Example'),
        backgroundColor: _configService.isProduction ? Colors.red : Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigItem('Environment', _configService.environmentDisplayName),
            _buildConfigItem('App Name', _configService.appName),
            _buildConfigItem('Bundle ID', _configService.bundleId),
            _buildConfigItem('API Base URL', _configService.apiBaseUrl),
            _buildConfigItem('WebSocket URL', _configService.websocketUrl ?? 'Not configured'),
            _buildConfigItem('Timeout', '${_configService.timeout}ms'),
            _buildConfigItem('Debug Mode', _configService.isDebugMode.toString()),
            _buildConfigItem('Production Mode', _configService.isProduction.toString()),
            
            SizedBox(height: 24),
            Text(
              'Configuration JSON:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatJson(_configService.toJson()),
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _switchEnvironment('development'),
                  child: Text('Development'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _switchEnvironment('staging'),
                  child: Text('Staging'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _switchEnvironment('production'),
                  child: Text('Production'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _switchEnvironment(String environment) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _configService.reload(environment);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatJson(Map<String, dynamic> json) {
    // Simple JSON formatting for display
    final buffer = StringBuffer();
    _formatJsonRecursive(json, buffer, 0);
    return buffer.toString();
  }

  void _formatJsonRecursive(dynamic obj, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;
    
    if (obj is Map) {
      buffer.writeln('{');
      final entries = obj.entries.toList();
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        buffer.write('$indentStr  "${entry.key}": ');
        _formatJsonRecursive(entry.value, buffer, indent + 1);
        if (i < entries.length - 1) buffer.write(',');
        buffer.writeln();
      }
      buffer.write('$indentStr}');
    } else if (obj is List) {
      buffer.write('[');
      for (int i = 0; i < obj.length; i++) {
        _formatJsonRecursive(obj[i], buffer, indent);
        if (i < obj.length - 1) buffer.write(', ');
      }
      buffer.write(']');
    } else if (obj is String) {
      buffer.write('"$obj"');
    } else {
      buffer.write(obj.toString());
    }
  }
}