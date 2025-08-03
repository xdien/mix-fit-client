import 'package:mobx/mobx.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_message.dart';
import 'websocket_aware_store.dart';

part 'customer_websocket_store.g.dart';

/// WebSocket-aware store for customer data
/// Handles real-time customer updates from the server
class CustomerWebSocketStore = _CustomerWebSocketStore with _$CustomerWebSocketStore;

abstract class _CustomerWebSocketStore extends WebSocketAwareStore with Store {
  _CustomerWebSocketStore(super.webSocketService);

  @override
  List<String> get subscribedChannels => ['customers', 'customers.updates'];

  @observable
  ObservableMap<String, Customer> customers = ObservableMap<String, Customer>();

  @observable
  DateTime? lastUpdateTime;

  @observable
  bool isReceivingUpdates = false;

  @observable
  int totalCustomers = 0;

  @observable
  int activeCustomers = 0;

  @observable
  String? conflictResolutionMessage;

  @computed
  List<Customer> get recentlyUpdatedCustomers {
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    
    return customers.values
        .where((customer) => customer.lastUpdated.isAfter(oneDayAgo))
        .toList()
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  @computed
  List<Customer> get vipCustomers => 
      customers.values.where((customer) => customer.isVip).toList();

  @computed
  int get vipCustomerCount => vipCustomers.length;

  @override
  void handleWebSocketMessage(String channel, dynamic data) {
    try {
      final message = WebSocketMessage.fromJson(data as Map<String, dynamic>);
      
      switch (message.type) {
        case 'customer.updated':
          _handleCustomerUpdate(message.data);
          break;
        case 'customer.created':
          _handleCustomerCreated(message.data);
          break;
        case 'customer.deleted':
          _handleCustomerDeleted(message.data);
          break;
        case 'customer.status.changed':
          _handleCustomerStatusChanged(message.data);
          break;
        case 'customer.conflict':
          _handleCustomerConflict(message.data);
          break;
        default:
          print('Unknown customer message type: ${message.type}');
      }
      
      _updateLastUpdateTime();
    } catch (e) {
      print('Error processing customer WebSocket message: $e');
    }
  }

  @override
  void onConnectionStateChanged(WebSocketConnectionState state) {
    super.onConnectionStateChanged(state);
    
    runInAction(() {
      isReceivingUpdates = state == WebSocketConnectionState.connected;
      if (state != WebSocketConnectionState.connected) {
        conflictResolutionMessage = null;
      }
    });

    if (state == WebSocketConnectionState.connected) {
      refreshDataAfterReconnection();
    }
  }

  @action
  void _handleCustomerUpdate(Map<String, dynamic> data) {
    final customerId = data['id'] as String;
    final updatedCustomer = Customer.fromJson(data);
    
    // Check for conflicts with local changes
    if (customers.containsKey(customerId)) {
      final existingCustomer = customers[customerId]!;
      if (_hasConflict(existingCustomer, updatedCustomer)) {
        _handlePotentialConflict(existingCustomer, updatedCustomer);
        return;
      }
    }
    
    customers[customerId] = updatedCustomer;
    _recalculateTotals();
  }

  @action
  void _handleCustomerCreated(Map<String, dynamic> data) {
    final newCustomer = Customer.fromJson(data);
    customers[newCustomer.id] = newCustomer;
    _recalculateTotals();
  }

  @action
  void _handleCustomerDeleted(Map<String, dynamic> data) {
    final customerId = data['id'] as String;
    customers.remove(customerId);
    _recalculateTotals();
  }

  @action
  void _handleCustomerStatusChanged(Map<String, dynamic> data) {
    final customerId = data['id'] as String;
    final newStatus = data['status'] as String;
    
    if (customers.containsKey(customerId)) {
      final customer = customers[customerId]!;
      customers[customerId] = customer.copyWith(
        status: CustomerStatus.values.firstWhere(
          (status) => status.name == newStatus,
          orElse: () => CustomerStatus.active,
        ),
        lastUpdated: DateTime.now(),
      );
    }
    
    _recalculateTotals();
  }

  @action
  void _handleCustomerConflict(Map<String, dynamic> data) {
    final customerId = data['customerId'] as String;
    final conflictType = data['conflictType'] as String;
    final serverVersion = Customer.fromJson(data['serverVersion'] as Map<String, dynamic>);
    
    conflictResolutionMessage = 'Conflict detected for customer $customerId: $conflictType';
    
    // For now, we'll use server version as default resolution
    // In a real app, you might want to show a dialog to the user
    customers[customerId] = serverVersion;
    _recalculateTotals();
  }

  bool _hasConflict(Customer local, Customer server) {
    // Simple conflict detection based on last updated time
    // In a real app, you might want more sophisticated conflict detection
    return local.lastUpdated.isAfter(server.lastUpdated) && 
           local.version != server.version;
  }

  void _handlePotentialConflict(Customer local, Customer server) {
    // Emit a conflict event for handling
    _handleCustomerConflict({
      'customerId': local.id,
      'conflictType': 'version_mismatch',
      'serverVersion': server.toJson(),
      'localVersion': local.toJson(),
    });
  }

  @action
  void _updateLastUpdateTime() {
    lastUpdateTime = DateTime.now();
  }

  @action
  void _recalculateTotals() {
    totalCustomers = customers.length;
    activeCustomers = customers.values
        .where((customer) => customer.status == CustomerStatus.active)
        .length;
  }

  @override
  Future<void> refreshDataAfterReconnection() async {
    // This would typically call a repository method to fetch latest customer data
    _updateLastUpdateTime();
  }

  /// Manually add customer (for initial data loading)
  @action
  void addCustomer(Customer customer) {
    // Force update by removing and re-adding to ensure ObservableMap detects the change
    customers.remove(customer.id);
    customers[customer.id] = customer;
    _recalculateTotals();
  }

  /// Manually update customers (for initial data loading)
  @action
  void updateCustomers(List<Customer> customerList) {
    customers.clear();
    for (final customer in customerList) {
      customers[customer.id] = customer;
    }
    _recalculateTotals();
  }

  /// Get customer by ID
  Customer? getCustomer(String id) {
    return customers[id];
  }

  /// Search customers by name, email, or phone
  List<Customer> searchCustomers(String query) {
    if (query.isEmpty) return customers.values.toList();
    
    final lowerQuery = query.toLowerCase();
    return customers.values.where((customer) =>
      customer.name.toLowerCase().contains(lowerQuery) ||
      customer.email.toLowerCase().contains(lowerQuery) ||
      customer.phone.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Clear conflict resolution message
  @action
  void clearConflictMessage() {
    conflictResolutionMessage = null;
  }

  /// Resolve conflict by accepting server version
  @action
  void acceptServerVersion(String customerId) {
    // The server version should already be applied
    clearConflictMessage();
  }

  /// Resolve conflict by keeping local version
  @action
  void keepLocalVersion(String customerId) {
    // This would typically send the local version back to the server
    clearConflictMessage();
  }
}

/// Customer status enum
enum CustomerStatus {
  active,
  inactive,
  suspended,
  vip
}

/// Customer model
class Customer {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final CustomerStatus status;
  final bool isVip;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int version;

  const Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
    required this.isVip,
    required this.createdAt,
    required this.lastUpdated,
    required this.version,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      status: CustomerStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => CustomerStatus.active,
      ),
      isVip: json['isVip'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'status': status.name,
      'isVip': isVip,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'version': version,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    CustomerStatus? status,
    bool? isVip,
    DateTime? createdAt,
    DateTime? lastUpdated,
    int? version,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      status: status ?? this.status,
      isVip: isVip ?? this.isVip,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      version: version ?? this.version,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, status: $status)';
  }
}