import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppConfig {
  static final AppConfig instance = AppConfig._internal();
  factory AppConfig() => instance;
  AppConfig._internal();

  late Map<String, dynamic> _config;

  late final String endpoint;
  late final String apiKey;
  late final bool debugMode;

  Future<void> load(String env) async {
    final configFile = 'assets/config/${env}_config.json';

    final configString = await rootBundle.loadString(configFile);

    // Parse JSON
    _config = json.decode(configString) as Map<String, dynamic>;

    endpoint = _config['endpoint'] as String;
    apiKey = _config['apiKey'] as String;
    debugMode = _config['debugMode'] as bool;

    debugPrint('Loaded config for $env environment');
    debugPrint('API Endpoint: $endpoint');
  }
}
