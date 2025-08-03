import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import '../websocket.dart';
import '../../sharedpref/shared_preference_helper.dart';

/// Example demonstrating how to use the WebSocket system with authentication
class WebSocketUsageExample {
  late SharedPreferenceHelper _sharedPreferenceHelper;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  /// Initialize the WebSocket system
  Future<void> initializeWebSocket(SharedPreferenceHelper sharedPreferenceHelper) async {
    _sharedPreferenceHelper = sharedPreferenceHelper;

    // Option 1: Initialize using WebSocketManager (Recommended for most use cases)
    await _initializeWithManager();

    // Option 2: Create individual service (For advanced use cases)
    // await _initializeWithService();
  }

  /// Initialize WebSocket using WebSocketManager (Recommended approach)
  Future<void> _initializeWithManager() async {
    developer.log('Initializing WebSocket with manager', name: 'WebSocketExample');

    // Initialize WebSocket manager with authentication
    WebSocketFactory.initializeWebSocketManager(
      sharedPreferenceHelper: _sharedPreferenceHelper,
      config: _createWebSocketConfig(),
    );

    final manager = WebSocketManager.instance;

    // Listen to connection state changes
    _connectionSubscription = manager.connectionState.listen((state) {
      _handleConnectionStateChange(state);
    });

    // Connect to WebSocket
    await manager.connect();

    // Subscribe to channels
    _subscribeToChannels(manager);
  }

  /// Initialize WebSocket using individual service (Advanced approach)
  Future<void> _initializeWithService() async {
    developer.log('Initializing WebSocket with service', name: 'WebSocketExample');

    // Create WebSocket service with authentication
    final service = WebSocketFactory.createWebSocketService(
      sharedPreferenceHelper: _sharedPreferenceHelper,
      config: _createWebSocketConfig(),
    );

    // Listen to connection state changes
    _connectionSubscription = service.connectionState.listen((state) {
      _handleConnectionStateChange(state);
    });

    // Connect to WebSocket
    await service.connect();

    // Subscribe to channels
    service.subscribe('inventory', _handleInventoryUpdate);
    service.subscribe('customers', _handleCustomerUpdate);
    service.subscribe('orders', _handleOrderUpdate);
  }

  /// Create WebSocket configuration based on environment
  WebSocketConfig _createWebSocketConfig() {
    // Use development config for debug builds
    if (kDebugMode) {
      return WebSocketFactory.createDevelopmentConfig();
    }

    // Use production config for release builds
    return WebSocketFactory.createProductionConfig('https://api.example.com');
  }

  /// Subscribe to relevant channels using WebSocketManager
  void _subscribeToChannels(WebSocketManager manager) {
    developer.log('Subscribing to WebSocket channels', name: 'WebSocketExample');

    // Subscribe to inventory updates
    manager.subscribe('inventory', _handleInventoryUpdate);

    // Subscribe to customer updates
    manager.subscribe('customers', _handleCustomerUpdate);

    // Subscribe to order updates
    manager.subscribe('orders', _handleOrderUpdate);

    // Subscribe to user-specific notifications
    manager.subscribe('user.notifications', _handleUserNotification);
  }

  /// Handle connection state changes
  void _handleConnectionStateChange(WebSocketConnectionState state) {
    developer.log('WebSocket connection state changed: $state', name: 'WebSocketExample');

    switch (state) {
      case WebSocketConnectionState.connected:
        _onConnected();
        break;
      case WebSocketConnectionState.disconnected:
        _onDisconnected();
        break;
      case WebSocketConnectionState.connecting:
        _onConnecting();
        break;
      case WebSocketConnectionState.reconnecting:
        _onReconnecting();
        break;
      case WebSocketConnectionState.error:
        _onError();
        break;
    }
  }

  /// Handle successful connection
  void _onConnected() {
    developer.log('WebSocket connected successfully', name: 'WebSocketExample');
    
    // Update UI to show connected state
    // Show success message to user
    // Enable real-time features
  }

  /// Handle disconnection
  void _onDisconnected() {
    developer.log('WebSocket disconnected', name: 'WebSocketExample');
    
    // Update UI to show disconnected state
    // Disable real-time features
    // Show offline indicator
  }

  /// Handle connecting state
  void _onConnecting() {
    developer.log('WebSocket connecting...', name: 'WebSocketExample');
    
    // Show connecting indicator
    // Disable real-time features temporarily
  }

  /// Handle reconnecting state
  void _onReconnecting() {
    developer.log('WebSocket reconnecting...', name: 'WebSocketExample');
    
    // Show reconnecting indicator
    // Keep UI responsive
  }

  /// Handle error state
  void _onError() {
    developer.log('WebSocket connection error', name: 'WebSocketExample');
    
    // Show error message
    // Provide retry option
    // Check authentication status
  }

  /// Handle inventory updates
  void _handleInventoryUpdate(dynamic data) {
    developer.log('Received inventory update: $data', name: 'WebSocketExample');
    
    try {
      // Parse the inventory update data
      final inventoryData = data as Map<String, dynamic>;
      final itemId = inventoryData['itemId'] as String;
      final newQuantity = inventoryData['quantity'] as int;
      
      // Update local inventory data
      _updateLocalInventory(itemId, newQuantity);
      
      // Notify UI components
      _notifyInventoryChange(itemId, newQuantity);
      
    } catch (error) {
      developer.log('Error processing inventory update: $error', name: 'WebSocketExample');
    }
  }

  /// Handle customer updates
  void _handleCustomerUpdate(dynamic data) {
    developer.log('Received customer update: $data', name: 'WebSocketExample');
    
    try {
      // Parse the customer update data
      final customerData = data as Map<String, dynamic>;
      final customerId = customerData['customerId'] as String;
      final updateType = customerData['type'] as String;
      
      // Update local customer data
      _updateLocalCustomer(customerId, customerData);
      
      // Notify UI components
      _notifyCustomerChange(customerId, updateType);
      
    } catch (error) {
      developer.log('Error processing customer update: $error', name: 'WebSocketExample');
    }
  }

  /// Handle order updates
  void _handleOrderUpdate(dynamic data) {
    developer.log('Received order update: $data', name: 'WebSocketExample');
    
    try {
      // Parse the order update data
      final orderData = data as Map<String, dynamic>;
      final orderId = orderData['orderId'] as String;
      final status = orderData['status'] as String;
      
      // Update local order data
      _updateLocalOrder(orderId, orderData);
      
      // Notify UI components
      _notifyOrderChange(orderId, status);
      
    } catch (error) {
      developer.log('Error processing order update: $error', name: 'WebSocketExample');
    }
  }

  /// Handle user notifications
  void _handleUserNotification(dynamic data) {
    developer.log('Received user notification: $data', name: 'WebSocketExample');
    
    try {
      // Parse the notification data
      final notificationData = data as Map<String, dynamic>;
      final message = notificationData['message'] as String;
      final priority = notificationData['priority'] as String;
      
      // Show notification to user
      _showNotification(message, priority);
      
    } catch (error) {
      developer.log('Error processing user notification: $error', name: 'WebSocketExample');
    }
  }

  /// Handle app lifecycle changes
  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    developer.log('App lifecycle changed: $state', name: 'WebSocketExample');
    
    final manager = WebSocketManager.instance;
    await manager.handleAppLifecycle(state);
  }

  /// Check connection status
  bool get isConnected {
    final manager = WebSocketManager.instance;
    return manager.isConnected;
  }

  /// Get current connection state
  WebSocketConnectionState get connectionState {
    final manager = WebSocketManager.instance;
    return manager.currentState;
  }

  /// Manually reconnect
  Future<void> reconnect() async {
    developer.log('Manual reconnect requested', name: 'WebSocketExample');
    
    final manager = WebSocketManager.instance;
    await manager.disconnect();
    await manager.connect();
  }

  /// Dispose resources
  Future<void> dispose() async {
    developer.log('Disposing WebSocket resources', name: 'WebSocketExample');
    
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
    
    final manager = WebSocketManager.instance;
    await manager.disconnect();
  }

  // Mock methods for demonstration (implement according to your app's architecture)
  void _updateLocalInventory(String itemId, int quantity) {
    // Update local database or state management
  }

  void _notifyInventoryChange(String itemId, int quantity) {
    // Notify MobX stores or other state management
  }

  void _updateLocalCustomer(String customerId, Map<String, dynamic> data) {
    // Update local database or state management
  }

  void _notifyCustomerChange(String customerId, String updateType) {
    // Notify MobX stores or other state management
  }

  void _updateLocalOrder(String orderId, Map<String, dynamic> data) {
    // Update local database or state management
  }

  void _notifyOrderChange(String orderId, String status) {
    // Notify MobX stores or other state management
  }

  void _showNotification(String message, String priority) {
    // Show notification using your app's notification system
  }
}

/// Example of integrating WebSocket with a Flutter widget
class WebSocketAwareWidget extends StatefulWidget {
  const WebSocketAwareWidget({Key? key}) : super(key: key);

  @override
  State<WebSocketAwareWidget> createState() => _WebSocketAwareWidgetState();
}

class _WebSocketAwareWidgetState extends State<WebSocketAwareWidget> {
  late WebSocketUsageExample _webSocketExample;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    _webSocketExample = WebSocketUsageExample();
    
    // Initialize with your SharedPreferenceHelper instance
    // await _webSocketExample.initializeWebSocket(sharedPreferenceHelper);
    
    // Listen to connection state changes
    final manager = WebSocketManager.instance;
    _connectionSubscription = manager.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _webSocketExample.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Example'),
        actions: [
          _buildConnectionIndicator(),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          _buildControlButtons(),
          const Expanded(
            child: Center(
              child: Text('Your app content here'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    Color color;
    IconData icon;
    
    switch (_connectionState) {
      case WebSocketConnectionState.connected:
        color = Colors.green;
        icon = Icons.wifi;
        break;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        color = Colors.orange;
        icon = Icons.wifi_protected_setup;
        break;
      case WebSocketConnectionState.error:
        color = Colors.red;
        icon = Icons.wifi_off;
        break;
      case WebSocketConnectionState.disconnected:
      default:
        color = Colors.grey;
        icon = Icons.wifi_off;
        break;
    }
    
    return Icon(icon, color: color);
  }

  Widget _buildConnectionStatus() {
    String statusText;
    Color statusColor;
    
    switch (_connectionState) {
      case WebSocketConnectionState.connected:
        statusText = 'Connected - Real-time updates active';
        statusColor = Colors.green;
        break;
      case WebSocketConnectionState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        break;
      case WebSocketConnectionState.reconnecting:
        statusText = 'Reconnecting...';
        statusColor = Colors.orange;
        break;
      case WebSocketConnectionState.error:
        statusText = 'Connection error - Tap to retry';
        statusColor = Colors.red;
        break;
      case WebSocketConnectionState.disconnected:
      default:
        statusText = 'Disconnected - No real-time updates';
        statusColor = Colors.grey;
        break;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8.0),
      color: statusColor.withOpacity(0.1),
      child: Text(
        statusText,
        textAlign: TextAlign.center,
        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: _connectionState == WebSocketConnectionState.disconnected
                ? () => _webSocketExample.reconnect()
                : null,
            child: const Text('Connect'),
          ),
          ElevatedButton(
            onPressed: _connectionState == WebSocketConnectionState.connected
                ? () => WebSocketManager.instance.disconnect()
                : null,
            child: const Text('Disconnect'),
          ),
          ElevatedButton(
            onPressed: () => _webSocketExample.reconnect(),
            child: const Text('Reconnect'),
          ),
        ],
      ),
    );
  }
}

// Add this import at the top of the file
const bool kDebugMode = true; // This should be imported from 'package:flutter/foundation.dart' in real usage