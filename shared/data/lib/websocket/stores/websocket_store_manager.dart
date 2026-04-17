import 'package:mobx/mobx.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import 'inventory_websocket_store.dart';
import 'customer_websocket_store.dart';
import 'order_websocket_store.dart';

part 'websocket_store_manager.g.dart';

/// Manages all WebSocket-aware stores and coordinates their lifecycle
/// Provides a centralized way to manage real-time data synchronization
class WebSocketStoreManager = _WebSocketStoreManager with _$WebSocketStoreManager;

abstract class _WebSocketStoreManager with Store {
  final IWebSocketService _webSocketService;
  
  late final InventoryWebSocketStore inventoryStore;
  late final CustomerWebSocketStore customerStore;
  late final OrderWebSocketStore orderStore;
  
  final List<ReactionDisposer> _disposers = [];
  bool _isInitialized = false;

  _WebSocketStoreManager(this._webSocketService) {
    _initializeStores();
    _setupConnectionMonitoring();
  }

  @observable
  WebSocketConnectionState connectionState = WebSocketConnectionState.disconnected;

  @observable
  bool isConnected = false;

  @observable
  DateTime? lastConnectionTime;

  @observable
  int reconnectAttempts = 0;

  @observable
  String? lastError;

  @computed
  bool get hasActiveStores => _isInitialized;

  @computed
  String get connectionStatusText {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return 'Connected - Receiving real-time updates';
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting... (Attempt $reconnectAttempts)';
      case WebSocketConnectionState.disconnected:
        return 'Disconnected - Using cached data';
      case WebSocketConnectionState.error:
        return 'Connection error - ${lastError ?? "Unknown error"}';
    }
  }

  @computed
  bool get shouldShowConnectionIndicator => 
      connectionState != WebSocketConnectionState.connected;

  void _initializeStores() {
    inventoryStore = InventoryWebSocketStore(_webSocketService);
    customerStore = CustomerWebSocketStore(_webSocketService);
    orderStore = OrderWebSocketStore(_webSocketService);
    
    _isInitialized = true;
  }

  void _setupConnectionMonitoring() {
    // Monitor connection state changes
    final connectionDisposer = reaction(
      (_) => _webSocketService.connectionState,
      (Stream<WebSocketConnectionState> stateStream) {
        stateStream.listen((state) {
          runInAction(() {
            connectionState = state;
            isConnected = state == WebSocketConnectionState.connected;
            
            if (state == WebSocketConnectionState.connected) {
              lastConnectionTime = DateTime.now();
              reconnectAttempts = 0;
              lastError = null;
            } else if (state == WebSocketConnectionState.reconnecting) {
              reconnectAttempts++;
            }
          });
        });
      },
    );
    _disposers.add(connectionDisposer);
  }

  /// Initialize WebSocket connection and start receiving updates
  @action
  Future<void> connect() async {
    try {
      await _webSocketService.connect();
    } catch (e) {
      lastError = e.toString();
      print('Failed to connect WebSocket: $e');
    }
  }

  /// Disconnect WebSocket and stop receiving updates
  @action
  Future<void> disconnect() async {
    try {
      await _webSocketService.disconnect();
    } catch (e) {
      print('Error disconnecting WebSocket: $e');
    }
  }

  /// Refresh all store data after reconnection
  @action
  Future<void> refreshAllStores() async {
    if (!_isInitialized) return;

    try {
      await Future.wait([
        inventoryStore.refreshDataAfterReconnection(),
        customerStore.refreshDataAfterReconnection(),
        orderStore.refreshDataAfterReconnection(),
      ]);
    } catch (e) {
      print('Error refreshing stores: $e');
    }
  }

  /// Get summary of all real-time data
  @computed
  Map<String, dynamic> get dataSummary {
    if (!_isInitialized) return {};

    return {
      'inventory': {
        'totalItems': inventoryStore.totalItemsInStock,
        'totalValue': inventoryStore.totalInventoryValue,
        'lowStockCount': inventoryStore.lowStockCount,
        'outOfStockCount': inventoryStore.outOfStockCount,
        'lastUpdate': inventoryStore.lastUpdateTime?.toIso8601String(),
      },
      'customers': {
        'totalCustomers': customerStore.totalCustomers,
        'activeCustomers': customerStore.activeCustomers,
        'vipCustomers': customerStore.vipCustomerCount,
        'recentUpdates': customerStore.recentlyUpdatedCustomers.length,
        'lastUpdate': customerStore.lastUpdateTime?.toIso8601String(),
      },
      'orders': {
        'totalOrders': orderStore.totalOrders,
        'pendingOrders': orderStore.pendingOrders,
        'completedOrders': orderStore.completedOrders,
        'urgentOrders': orderStore.urgentOrderCount,
        'delayedOrders': orderStore.delayedOrderCount,
        'totalValue': orderStore.totalOrderValue,
        'criticalAlerts': orderStore.criticalAlerts.length,
        'lastUpdate': orderStore.lastUpdateTime?.toIso8601String(),
      },
      'connection': {
        'state': connectionState.name,
        'isConnected': isConnected,
        'lastConnectionTime': lastConnectionTime?.toIso8601String(),
        'reconnectAttempts': reconnectAttempts,
        'lastError': lastError,
      },
    };
  }

  /// Get critical alerts from all stores
  @computed
  List<String> get allCriticalAlerts {
    final alerts = <String>[];
    
    if (!_isInitialized) return alerts;

    // Add inventory alerts
    if (inventoryStore.outOfStockCount > 0) {
      alerts.add('${inventoryStore.outOfStockCount} items out of stock');
    }
    if (inventoryStore.lowStockCount > 0) {
      alerts.add('${inventoryStore.lowStockCount} items low in stock');
    }

    // Add customer alerts
    if (customerStore.conflictResolutionMessage != null) {
      alerts.add('Customer data conflict: ${customerStore.conflictResolutionMessage}');
    }

    // Add order alerts
    alerts.addAll(orderStore.criticalAlerts);
    
    if (orderStore.urgentOrderCount > 0) {
      alerts.add('${orderStore.urgentOrderCount} urgent orders require attention');
    }
    if (orderStore.delayedOrderCount > 0) {
      alerts.add('${orderStore.delayedOrderCount} orders are delayed');
    }

    return alerts;
  }

  /// Clear all critical alerts
  @action
  void clearAllAlerts() {
    if (!_isInitialized) return;

    customerStore.clearConflictMessage();
    orderStore.clearAllCriticalAlerts();
  }

  /// Handle app lifecycle changes
  @action
  Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    await _webSocketService.handleAppLifecycle(state);
    
    // Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed && isConnected) {
      await refreshAllStores();
    }
  }

  /// Get connection health status
  @computed
  Map<String, dynamic> get connectionHealth {
    final now = DateTime.now();
    final timeSinceLastConnection = lastConnectionTime != null 
        ? now.difference(lastConnectionTime!).inMinutes
        : null;

    return {
      'isHealthy': isConnected && (timeSinceLastConnection == null || timeSinceLastConnection < 5),
      'connectionState': connectionState.name,
      'timeSinceLastConnection': timeSinceLastConnection,
      'reconnectAttempts': reconnectAttempts,
      'hasErrors': lastError != null,
      'lastError': lastError,
    };
  }

  /// Dispose all stores and clean up resources
  void dispose() {
    if (_isInitialized) {
      inventoryStore.dispose();
      customerStore.dispose();
      orderStore.dispose();
    }

    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();

    _webSocketService.dispose();
  }
}