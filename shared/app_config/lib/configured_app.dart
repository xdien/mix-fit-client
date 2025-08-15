import 'package:flutter/material.dart';

import 'app_config.dart';

class ConfiguredApp extends StatefulWidget {
  final String environment;
  final Widget Function(BuildContext context) builder;
  final bool useNewConfigSystem;

  const ConfiguredApp({
    Key? key,
    required this.environment,
    required this.builder,
    this.useNewConfigSystem = false,
  }) : super(key: key);

  @override
  _ConfiguredAppState createState() => _ConfiguredAppState();
}

class _ConfiguredAppState extends State<ConfiguredApp> {
  bool _isLoaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      if (widget.useNewConfigSystem) {
        // Use new environment configuration system
        await EnvironmentConfigService().initialize(widget.environment);
      } else {
        // Use AppConfig for backward compatibility
        await AppConfig().load(widget.environment);
      }
      
      setState(() {
        _isLoaded = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoaded = true; // Still show the app with error state
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading configuration...'),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoaded = false;
                      _error = null;
                    });
                    _loadConfig();
                  },
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return widget.builder(context);
  }
}
