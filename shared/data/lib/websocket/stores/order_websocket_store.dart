import 'package:mobx/mobx.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_message.dart';
import 'websocket_aware_store.dart';

part 'order_websocket_store.g.dart';

/// WebSocket-aware store for order data
/// Handles real-time order updates from the server
class OrderWebSocketStore = _OrderWebSocketStore with _$OrderWebSocketStore;

abstract class _OrderWebSocketStore extends WebSocketAwareStore with Store {
  _OrderWebSocketStore(super.webSocketService);

  @override
  List<String> get subscribedChannels => ['orders', 'orders.updates', 'orders.critical'];

  @observable
  ObservableMap<String, Order> orders = ObservableMap<String, Order>();

  @observable
  DateTime? lastUpdateTime;

  @observable
  bool isReceivingUpdates = false;

  @observable
  int totalOrders = 0;

  @observable
  int pendingOrders = 0;

  @observable
  int completedOrders = 0;

  @observable
  double totalOrderValue = 0.0;

  @observable
  ObservableList<String> criticalAlerts = ObservableList<String>();

  @computed
  List<Order> get recentOrders {
    final sortedOrders = orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(10).toList();
  }

  @computed
  List<Order> get urgentOrders => 
      orders.values.where((order) => order.priority == OrderPriority.urgent).toList();

  @computed
  List<Order> get delayedOrders {
    final now = DateTime.now();
    return orders.values.where((order) => 
      order.expectedDelivery != null && 
      order.expectedDelivery!.isBefore(now) &&
      order.status != OrderStatus.completed &&
      order.status != OrderStatus.cancelled
    ).toList();
  }

  @computed
  int get urgentOrderCount => urgentOrders.length;

  @computed
  int get delayedOrderCount => delayedOrders.length;

  @override
  void handleWebSocketMessage(String channel, dynamic data) {
    try {
      final message = WebSocketMessage.fromJson(data as Map<String, dynamic>);
      
      switch (message.type) {
        case 'order.created':
          _handleOrderCreated(message.data);
          break;
        case 'order.updated':
          _handleOrderUpdated(message.data);
          break;
        case 'order.status.changed':
          _handleOrderStatusChanged(message.data);
          break;
        case 'order.cancelled':
          _handleOrderCancelled(message.data);
          break;
        case 'order.priority.changed':
          _handleOrderPriorityChanged(message.data);
          break;
        case 'order.critical.alert':
          _handleCriticalAlert(message.data);
          break;
        case 'order.bulk.update':
          _handleBulkOrderUpdate(message.data);
          break;
        default:
          print('Unknown order message type: ${message.type}');
      }
      
      _updateLastUpdateTime();
    } catch (e) {
      print('Error processing order WebSocket message: $e');
    }
  }

  @override
  void onConnectionStateChanged(WebSocketConnectionState state) {
    super.onConnectionStateChanged(state);
    
    runInAction(() {
      isReceivingUpdates = state == WebSocketConnectionState.connected;
      if (state != WebSocketConnectionState.connected) {
        // Clear critical alerts when disconnected
        criticalAlerts.clear();
      }
    });

    if (state == WebSocketConnectionState.connected) {
      refreshDataAfterReconnection();
    }
  }

  @action
  void _handleOrderCreated(Map<String, dynamic> data) {
    final newOrder = Order.fromJson(data);
    orders[newOrder.id] = newOrder;
    _recalculateTotals();
  }

  @action
  void _handleOrderUpdated(Map<String, dynamic> data) {
    final orderId = data['id'] as String;
    final updatedOrder = Order.fromJson(data);
    
    orders[orderId] = updatedOrder;
    _recalculateTotals();
  }

  @action
  void _handleOrderStatusChanged(Map<String, dynamic> data) {
    final orderId = data['id'] as String;
    final newStatus = data['status'] as String;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    
    if (orders.containsKey(orderId)) {
      final order = orders[orderId]!;
      final updatedOrder = order.copyWith(
        status: OrderStatus.values.firstWhere(
          (status) => status.name == newStatus,
          orElse: () => OrderStatus.pending,
        ),
        lastUpdated: timestamp,
      );
      
      orders[orderId] = updatedOrder;
      _recalculateTotals();
      
      // Add status change to history if provided
      if (data.containsKey('statusHistory')) {
        final historyEntry = OrderStatusHistory.fromJson(data['statusHistory'] as Map<String, dynamic>);
        final orderWithHistory = updatedOrder.copyWith(
          statusHistory: [...updatedOrder.statusHistory, historyEntry],
        );
        orders[orderId] = orderWithHistory;
      }
    }
  }

  @action
  void _handleOrderCancelled(Map<String, dynamic> data) {
    final orderId = data['id'] as String;
    final reason = data['reason'] as String?;
    final timestamp = DateTime.parse(data['timestamp'] as String);
    
    if (orders.containsKey(orderId)) {
      final order = orders[orderId]!;
      orders[orderId] = order.copyWith(
        status: OrderStatus.cancelled,
        cancellationReason: reason,
        lastUpdated: timestamp,
      );
      _recalculateTotals();
    }
  }

  @action
  void _handleOrderPriorityChanged(Map<String, dynamic> data) {
    final orderId = data['id'] as String;
    final newPriority = data['priority'] as String;
    
    if (orders.containsKey(orderId)) {
      final order = orders[orderId]!;
      orders[orderId] = order.copyWith(
        priority: OrderPriority.values.firstWhere(
          (priority) => priority.name == newPriority,
          orElse: () => OrderPriority.normal,
        ),
        lastUpdated: DateTime.now(),
      );
    }
  }

  @action
  void _handleCriticalAlert(Map<String, dynamic> data) {
    final orderId = data['orderId'] as String;
    final alertType = data['alertType'] as String;
    final message = data['message'] as String;
    
    final alertMessage = 'Order $orderId: $alertType - $message';
    criticalAlerts.insert(0, alertMessage);
    
    // Keep only the last 20 alerts
    if (criticalAlerts.length > 20) {
      criticalAlerts.removeRange(20, criticalAlerts.length);
    }
    
    // Update order priority if it's a critical alert
    if (orders.containsKey(orderId) && alertType == 'URGENT') {
      final order = orders[orderId]!;
      orders[orderId] = order.copyWith(
        priority: OrderPriority.urgent,
        lastUpdated: DateTime.now(),
      );
    }
  }

  @action
  void _handleBulkOrderUpdate(Map<String, dynamic> data) {
    final orderUpdates = data['orders'] as List<dynamic>;
    
    for (final orderData in orderUpdates) {
      final order = Order.fromJson(orderData as Map<String, dynamic>);
      orders[order.id] = order;
    }
    
    _recalculateTotals();
  }

  @action
  void _updateLastUpdateTime() {
    lastUpdateTime = DateTime.now();
  }

  @action
  void _recalculateTotals() {
    totalOrders = orders.length;
    pendingOrders = orders.values
        .where((order) => order.status == OrderStatus.pending)
        .length;
    completedOrders = orders.values
        .where((order) => order.status == OrderStatus.completed)
        .length;
    totalOrderValue = orders.values.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  @override
  Future<void> refreshDataAfterReconnection() async {
    // This would typically call a repository method to fetch latest order data
    _updateLastUpdateTime();
  }

  /// Manually add order (for initial data loading)
  @action
  void addOrder(Order order) {
    // Force update by removing and re-adding to ensure ObservableMap detects the change
    orders.remove(order.id);
    orders[order.id] = order;
    _recalculateTotals();
  }

  /// Manually update orders (for initial data loading)
  @action
  void updateOrders(List<Order> orderList) {
    orders.clear();
    for (final order in orderList) {
      orders[order.id] = order;
    }
    _recalculateTotals();
  }

  /// Get order by ID
  Order? getOrder(String id) {
    return orders[id];
  }

  /// Search orders by customer name or order number
  List<Order> searchOrders(String query) {
    if (query.isEmpty) return orders.values.toList();
    
    final lowerQuery = query.toLowerCase();
    return orders.values.where((order) =>
      order.orderNumber.toLowerCase().contains(lowerQuery) ||
      order.customerName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get orders by status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return orders.values.where((order) => order.status == status).toList();
  }

  /// Clear a specific critical alert
  @action
  void clearCriticalAlert(int index) {
    if (index >= 0 && index < criticalAlerts.length) {
      criticalAlerts.removeAt(index);
    }
  }

  /// Clear all critical alerts
  @action
  void clearAllCriticalAlerts() {
    criticalAlerts.clear();
  }
}

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  completed,
  cancelled
}

/// Order priority enum
enum OrderPriority {
  low,
  normal,
  high,
  urgent
}

/// Order status history entry
class OrderStatusHistory {
  final OrderStatus status;
  final DateTime timestamp;
  final String? notes;
  final String? updatedBy;

  const OrderStatusHistory({
    required this.status,
    required this.timestamp,
    this.notes,
    this.updatedBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      notes: json['notes'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
      'updatedBy': updatedBy,
    };
  }
}

/// Order model
class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final OrderStatus status;
  final OrderPriority priority;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? expectedDelivery;
  final String? cancellationReason;
  final List<OrderStatusHistory> statusHistory;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.priority,
    required this.totalAmount,
    required this.createdAt,
    required this.lastUpdated,
    this.expectedDelivery,
    this.cancellationReason,
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      status: OrderStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      priority: OrderPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => OrderPriority.normal,
      ),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      expectedDelivery: json['expectedDelivery'] != null 
          ? DateTime.parse(json['expectedDelivery'] as String)
          : null,
      cancellationReason: json['cancellationReason'] as String?,
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((item) => OrderStatusHistory.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.name,
      'priority': priority.name,
      'totalAmount': totalAmount,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'expectedDelivery': expectedDelivery?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'statusHistory': statusHistory.map((item) => item.toJson()).toList(),
    };
  }

  Order copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    OrderStatus? status,
    OrderPriority? priority,
    double? totalAmount,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? expectedDelivery,
    String? cancellationReason,
    List<OrderStatusHistory>? statusHistory,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      totalAmount: totalAmount ?? this.totalAmount,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, priority: $priority)';
  }
}