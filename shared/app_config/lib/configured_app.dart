import 'package:flutter/material.dart';

import 'app_config.dart';

class ConfiguredApp extends StatefulWidget {
  final String environment;
  final Widget Function(BuildContext context) builder;

  const ConfiguredApp({
    Key? key,
    required this.environment,
    required this.builder,
  }) : super(key: key);

  @override
  _ConfiguredAppState createState() => _ConfiguredAppState();
}

class _ConfiguredAppState extends State<ConfiguredApp> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await AppConfig().load(widget.environment);
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return widget.builder(context);
  }
}
