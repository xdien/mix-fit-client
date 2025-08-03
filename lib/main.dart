import 'dart:async';

import 'package:mix_fit/di/service_locator.dart';
import 'package:mix_fit/presentation/my_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_config/app_config.dart';

import 'utils/routes/module_manager.dart';
import 'utils/environment_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setPreferredOrientations();
  
  // Initialize environment configuration before other services
  await _initializeEnvironmentConfig();
  
  await ServiceLocator.configureDependencies();
  await ModuleManager.instance.initialize();
  await ModuleManager.instance.registerDependencies(getIt);
  runApp(MyApp());
}

/// Initialize environment configuration
Future<void> _initializeEnvironmentConfig() async {
  try {
    // Auto-detect environment
    final environment = EnvironmentDetector.getCurrentEnvironment();
    final envInfo = EnvironmentDetector.getEnvironmentInfo();
    
    debugPrint('🔍 Environment Detection:');
    debugPrint('  Environment: ${envInfo['environment']}');
    debugPrint('  Display Name: ${envInfo['displayName']}');
    debugPrint('  Is Debug: ${envInfo['isDebug']}');
    debugPrint('  Dart Define: ${envInfo['dartDefine']}');
    debugPrint('  Flavor: ${envInfo['flavor']}');
    
    final integrationHelper = ConfigIntegrationHelper();
    await integrationHelper.initialize();
    
    debugPrint('Configuration system initialized successfully');
    debugPrint('Configuration summary: ${integrationHelper.getConfigurationSummary()}');
    
    // Validate configuration
    final isValid = await integrationHelper.validateConfiguration();
    if (!isValid) {
      debugPrint('Warning: Configuration validation failed');
    }
    
    // Auto-initialize config service with detected environment
    final configService = EnvironmentConfigService();
    await configService.initialize(environment);
    
    if (configService.isInitialized) {
      debugPrint('✅ Environment config loaded successfully!');
      debugPrint('API Base URL: ${configService.apiBaseUrl}');
      debugPrint('App Name: ${configService.appName}');
      debugPrint('Environment: ${configService.environmentName}');
    } else {
      debugPrint('❌ Environment config not initialized');
    }
  } catch (e) {
    debugPrint('Failed to initialize configuration system: $e');
    debugPrint('Application will continue with fallback configuration');
  }
}

Future<void> setPreferredOrientations() {
  return SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}
