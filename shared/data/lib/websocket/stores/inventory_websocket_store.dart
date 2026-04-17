import 'package:mobx/mobx.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_message.dart';
import 'websocket_aware_store.dart';

part 'inventory_websocket_store.g.dart';

/// WebSocket-aware store for inventory data
/// Handles real-time inventory updates from the server
class InventoryWebSocketStore = _InventoryWebSocketStore with _$InventoryWebSocketStore;

abstract class _InventoryWebSocketStore extends WebSocketAwareStore with Store {
  _InventoryWebSocketStore(super.webSocketService);

  @override
  List<String> get subscribedChannels => ['inventory', 'inventory.updates'];

  @observable
  ObservableMap<String, InventoryItem> inventoryItems = ObservableMap<String, InventoryItem>();

  @observable
  DateTime? lastUpdateTime;

  @observable
  bool isReceivingUpdates = false;

  @observable
  int totalItemsInStock = 0;

  @observable
  double totalInventoryValue = 0.0;

  @computed
  List<InventoryItem> get lowStockItems => 
      inventoryItems.values.where((item) => item.quantity <= item.lowStockThreshold).toList();

  @computed
  List<InventoryItem> get outOfStockItems => 
      inventoryItems.values.where((item) => item.quantity == 0).toList();

  @computed
  int get lowStockCount => lowStockItems.length;

  @computed
  int get outOfStockCount => outOfStockItems.length;

  @override
  void handleWebSocketMessage(String channel, dynamic data) {
    try {
      final message = WebSocketMessage.fromJson(data as Map<String, dynamic>);
      
      switch (message.type) {
        case 'inventory.item.updated':
          _handleInventoryItemUpdate(message.data);
          break;
        case 'inventory.item.added':
          _handleInventoryItemAdded(message.data);
          break;
        case 'inventory.item.removed':
          _handleInventoryItemRemoved(message.data);
          break;
        case 'inventory.bulk.update':
          _handleBulkInventoryUpdate(message.data);
          break;
        case 'inventory.low.stock.alert':
          _handleLowStockAlert(message.data);
          break;
        default:
          print('Unknown inventory message type: ${message.type}');
      }
      
      _updateLastUpdateTime();
    } catch (e) {
      print('Error processing inventory WebSocket message: $e');
    }
  }

  @override
  void onConnectionStateChanged(WebSocketConnectionState state) {
    super.onConnectionStateChanged(state);
    
    runInAction(() {
      isReceivingUpdates = state == WebSocketConnectionState.connected;
    });

    if (state == WebSocketConnectionState.connected) {
      // Request full inventory sync after reconnection
      refreshDataAfterReconnection();
    }
  }

  @action
  void _handleInventoryItemUpdate(Map<String, dynamic> data) {
    final itemId = data['id'] as String;
    final updatedItem = InventoryItem.fromJson(data);
    
    inventoryItems[itemId] = updatedItem;
    _recalculateTotals();
  }

  @action
  void _handleInventoryItemAdded(Map<String, dynamic> data) {
    final newItem = InventoryItem.fromJson(data);
    inventoryItems[newItem.id] = newItem;
    _recalculateTotals();
  }

  @action
  void _handleInventoryItemRemoved(Map<String, dynamic> data) {
    final itemId = data['id'] as String;
    inventoryItems.remove(itemId);
    _recalculateTotals();
  }

  @action
  void _handleBulkInventoryUpdate(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>;
    
    for (final itemData in items) {
      final item = InventoryItem.fromJson(itemData as Map<String, dynamic>);
      inventoryItems[item.id] = item;
    }
    
    _recalculateTotals();
  }

  @action
  void _handleLowStockAlert(Map<String, dynamic> data) {
    final itemId = data['itemId'] as String;
    final currentQuantity = data['currentQuantity'] as int;
    final threshold = data['threshold'] as int;
    
    // Update the specific item if it exists
    if (inventoryItems.containsKey(itemId)) {
      final item = inventoryItems[itemId]!;
      inventoryItems[itemId] = item.copyWith(
        quantity: currentQuantity,
        lowStockThreshold: threshold,
      );
    }
    
    _recalculateTotals();
  }

  @action
  void _updateLastUpdateTime() {
    lastUpdateTime = DateTime.now();
  }

  @action
  void _recalculateTotals() {
    totalItemsInStock = inventoryItems.values.fold(0, (sum, item) => sum + item.quantity);
    totalInventoryValue = inventoryItems.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  @override
  Future<void> refreshDataAfterReconnection() async {
    // This would typically call a repository method to fetch latest inventory data
    // For now, we'll just update the timestamp
    _updateLastUpdateTime();
  }

  /// Manually add inventory item (for initial data loading)
  @action
  void addInventoryItem(InventoryItem item) {
    // Force update by removing and re-adding to ensure ObservableMap detects the change
    inventoryItems.remove(item.id);
    inventoryItems[item.id] = item;
    _recalculateTotals();
  }

  /// Manually update inventory items (for initial data loading)
  @action
  void updateInventoryItems(List<InventoryItem> items) {
    inventoryItems.clear();
    for (final item in items) {
      inventoryItems[item.id] = item;
    }
    _recalculateTotals();
  }

  /// Get inventory item by ID
  InventoryItem? getInventoryItem(String id) {
    return inventoryItems[id];
  }

  /// Search inventory items by name or SKU
  List<InventoryItem> searchItems(String query) {
    if (query.isEmpty) return inventoryItems.values.toList();
    
    final lowerQuery = query.toLowerCase();
    return inventoryItems.values.where((item) =>
      item.name.toLowerCase().contains(lowerQuery) ||
      item.sku.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}

/// Inventory item model
class InventoryItem {
  final String id;
  final String name;
  final String sku;
  final int quantity;
  final double price;
  final int lowStockThreshold;
  final String category;
  final DateTime lastUpdated;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.price,
    required this.lowStockThreshold,
    required this.category,
    required this.lastUpdated,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 10,
      category: json['category'] as String? ?? 'General',
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'quantity': quantity,
      'price': price,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? sku,
    int? quantity,
    double? price,
    int? lowStockThreshold,
    String? category,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      category: category ?? this.category,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InventoryItem(id: $id, name: $name, sku: $sku, quantity: $quantity)';
  }
}