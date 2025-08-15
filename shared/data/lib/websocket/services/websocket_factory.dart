import 'dart:developer' as developer;
import 'package:app_config/app_config.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_config.dart';
import '../../../sharedpref/shared_preference_helper.dart';
import 'websocket_service.dart';
import 'websocket_manager.dart';
import 'websocket_auth_integration.dart';

/// Factory class for creating WebSocket services with proper configuration
class WebSocketFactory {
  static WebSocketFactory? _instance;
  static WebSocketFactory get instance => _instance ??= WebSocketFactory._internal();
  
  WebSocketFactory._internal();

  /// Create a WebSocket service with authentication integration
  static IWebSocketService createWebSocketService({
    required SharedPreferenceHelper sharedPreferenceHelper,
    WebSocketConfig? config,
  }) {
    developer.log('Creating WebSocket service', name: 'WebSocketFactory');
    
    // Create auth integration
    final authIntegration = WebSocketAuthIntegration(sharedPreferenceHelper);
    
    // Use provided config or create default
    final webSocketConfig = config ?? _createDefaultConfig();
    
    // Create WebSocket service with auth integration
    return WebSocketService(
      webSocketConfig,
      authIntegration.createTokenGetter(),
      refreshToken: authIntegration.createTokenRefresher(),
    );
  }

  /// Initialize WebSocket manager with authentication integration
  static void initializeWebSocketManager({
    required SharedPreferenceHelper sharedPreferenceHelper,
    WebSocketConfig? config,
  }) {
    developer.log('Initializing WebSocket manager', name: 'WebSocketFactory');
    
    // Create auth integration
    final authIntegration = WebSocketAuthIntegration(sharedPreferenceHelper);
    
    // Use provided config or create default
    final webSocketConfig = config ?? _createDefaultConfig();
    
    // Initialize WebSocket manager
    WebSocketManager.instance.initialize(
      config: webSocketConfig,
      getAuthToken: authIntegration.createTokenGetter(),
      refreshToken: authIntegration.createTokenRefresher(),
    );
  }

  /// Create default WebSocket configuration
  static WebSocketConfig _createDefaultConfig() {
    // Get WebSocket URL from app config
    String webSocketUrl;
    try {
      final appConfig = AppConfig.instance;
      final baseUrl = appConfig.endpoint;
      
      // Socket.IO client expects HTTP/HTTPS URLs, not WebSocket URLs
      // The library handles the WebSocket upgrade automatically
      if (baseUrl.startsWith('https://') || baseUrl.startsWith('http://')) {
        webSocketUrl = baseUrl;
      } else {
        webSocketUrl = 'http://$baseUrl';
      }
      
      // Add Socket.IO path if not present
      if (!webSocketUrl.endsWith('/socket.io')) {
        webSocketUrl = '$webSocketUrl/socket.io';
      }
      
      developer.log('WebSocket URL: $webSocketUrl', name: 'WebSocketFactory');
    } catch (error) {
      developer.log('Error getting WebSocket URL from config: $error', name: 'WebSocketFactory');
      // Fallback to localhost for development
      webSocketUrl = 'http://localhost:3000/socket.io';
    }

    return WebSocketConfig(
      url: webSocketUrl,
      reconnectInterval: const Duration(seconds: 5),
      maxReconnectAttempts: 10,
      heartbeatInterval: const Duration(seconds: 30),
      autoReconnect: true,
    );
  }

  /// Create development WebSocket configuration
  static WebSocketConfig createDevelopmentConfig() {
    return const WebSocketConfig(
      url: 'http://localhost:3000/socket.io',
      reconnectInterval: Duration(seconds: 2),
      maxReconnectAttempts: 5,
      heartbeatInterval: Duration(seconds: 15),
      autoReconnect: true,
    );
  }

  /// Create production WebSocket configuration
  static WebSocketConfig createProductionConfig(String baseUrl) {
    String webSocketUrl;
    // Socket.IO client expects HTTP/HTTPS URLs, not WebSocket URLs
    if (baseUrl.startsWith('https://') || baseUrl.startsWith('http://')) {
      webSocketUrl = baseUrl;
    } else {
      webSocketUrl = 'https://$baseUrl';
    }
    
    if (!webSocketUrl.endsWith('/socket.io')) {
      webSocketUrl = '$webSocketUrl/socket.io';
    }

    return WebSocketConfig(
      url: webSocketUrl,
      reconnectInterval: const Duration(seconds: 10),
      maxReconnectAttempts: 15,
      heartbeatInterval: const Duration(minutes: 1),
      autoReconnect: true,
    );
  }
}