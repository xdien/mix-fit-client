import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppConfig {
  // Singleton pattern
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  late Map<String, dynamic> _config;

  String get endpoint => _config['endpoint'] as String;
  String get apiKey => _config['apiKey'] as String;
  bool get debugMode => _config['debugMode'] as bool;

  Future<void> load(String env) async {
    final configFile = 'assets/config/${env}_config.json';
    
    final configString = await rootBundle.loadString(configFile);
    

    _config = json.decode(configString) as Map<String, dynamic>;
    
    debugPrint('Loaded config for $env environment');
    debugPrint('API Endpoint: $endpoint');
  }
}