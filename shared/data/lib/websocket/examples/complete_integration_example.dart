/// Complete WebSocket Integration Example
/// 
/// This example demonstrates a complete integration of WebSocket functionality
/// in a Flutter application, including real-time data synchronization,
/// conflict resolution, and app lifecycle management.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:data/websocket/websocket.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

part 'complete_integration_example.g.dart';

/// Example: Complete Customer Management with Real-time Updates
class CustomerManagementExample extends StatefulWidget {
  @override
  _CustomerManagementExampleState createState() => _CustomerManagementExampleState();
}

class _CustomerManagementExampleState extends State<CustomerManagementExample> 
    with WidgetsBindingObserver {
  
  late CustomerStore _customerStore;
  late WebSocketManager _webSocketManager;
  late AppLifecycleManager _lifecycleManager;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _webSocketManager.dispose();
    super.dispose();
  }

  void _initializeServices() {
    // Initialize WebSocket manager
    _webSocketManager = WebSocketManager();
    
    // Initialize customer store with WebSocket integration
    _customerStore = CustomerStore(_webSocketManager);
    
    // Initialize app lifecycle manager
    _lifecycleManager = AppLifecycleManager(_webSocketManager);
    
    // Start WebSocket connection
    _webSocketManager.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _lifecycleManager.handleAppLifecycleChange(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Customer Management'),
        actions: [
          Observer(
            builder: (_) => _buildConnectionIndicator(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionStatus(),
          Expanded(
            child: Observer(
              builder: (_) => _buildCustomerList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomerDialog,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final state = _webSocketManager.connectionState;
    
    Color color;
    IconData icon;
    
    switch (state) {
      case WebSocketConnectionState.connected:
        color = Colors.green;
        icon = Icons.wifi;
        break;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        color = Colors.orange;
        icon = Icons.wifi_off;
        break;
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        color = Colors.red;
        icon = Icons.wifi_off;
        break;
    }
    
    return Icon(icon, color: color);
  }

  Widget _buildConnectionStatus() {
    return Observer(
      builder: (_) {
        final state = _webSocketManager.connectionState;
        final isOnline = state == WebSocketConnectionState.connected;
        
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(8),
          color: isOnline ? Colors.green.shade100 : Colors.red.shade100,
          child: Text(
            isOnline ? 'Real-time updates active' : 'Offline mode - updates will sync when connected',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isOnline ? Colors.green.shade800 : Colors.red.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerList() {
    if (_customerStore.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_customerStore.customers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No customers found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _customerStore.customers.length,
      itemBuilder: (context, index) {
        final customer = _customerStore.customers[index];
        return _buildCustomerTile(customer);
      },
    );
  }

  Widget _buildCustomerTile(Customer customer) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(customer.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(customer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(customer.phone),
            Text(customer.address, style: TextStyle(fontSize: 12)),
            if (customer.hasRecentUpdate)
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Recently updated',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCustomerAction(value, customer),
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _showCustomerDetails(customer),
      ),
    );
  }

  void _handleCustomerAction(String action, Customer customer) {
    switch (action) {
      case 'edit':
        _showEditCustomerDialog(customer);
        break;
      case 'delete':
        _showDeleteConfirmation(customer);
        break;
    }
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        onSave: (customerData) async {
          await _customerStore.createCustomer(customerData);
        },
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: customer,
        onSave: (customerData) async {
          await _customerStore.updateCustomer(customer.id, customerData);
        },
      ),
    );
  }

  void _showDeleteConfirmation(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _customerStore.deleteCustomer(customer.id);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerDetailsScreen(customer: customer),
      ),
    );
  }
}

/// WebSocket Manager - Handles all WebSocket operations
class WebSocketManager {
  final IWebSocketService _webSocketService;
  final WebSocketDataSynchronizer _synchronizer;
  final List<StreamSubscription> _subscriptions = [];
  
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get connectionState => _connectionState;

  WebSocketManager()
      : _webSocketService = GetIt.instance<IWebSocketService>(),
        _synchronizer = GetIt.instance<WebSocketDataSynchronizer>();

  Future<void> initialize() async {
    // Listen to connection state changes
    _subscriptions.add(
      _webSocketService.connectionState.listen((state) {
        _connectionState = state;
        _handleConnectionStateChange(state);
      }),
    );

    // Listen to synchronization results
    _subscriptions.add(
      _synchronizer.syncResultStream.listen(_handleSyncResult),
    );

    // Listen to data conflicts
    _subscriptions.add(
      _synchronizer.conflictStream.listen(_handleDataConflict),
    );

    // Connect to WebSocket
    await _webSocketService.connect();

    // Subscribe to relevant channels
    _subscribeToChannels();
  }

  void _subscribeToChannels() {
    // Subscribe to customer updates
    _webSocketService.subscribe('customers', (data) async {
      final message = WebSocketMessage.fromJson(data);
      await _synchronizer.processMessage(message);
    });

    // Subscribe to system notifications
    _webSocketService.subscribe('system', (data) {
      _handleSystemNotification(data);
    });

    // Subscribe to user-specific notifications
    final userId = GetIt.instance<SharedPreferenceHelper>().userId;
    if (userId != null) {
      _webSocketService.subscribe('user.$userId', (data) {
        _handleUserNotification(data);
      });
    }
  }

  void _handleConnectionStateChange(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        print('WebSocket connected - real-time updates active');
        _syncPendingChanges();
        break;
      case WebSocketConnectionState.disconnected:
        print('WebSocket disconnected - offline mode');
        break;
      case WebSocketConnectionState.reconnecting:
        print('WebSocket reconnecting...');
        break;
      case WebSocketConnectionState.error:
        print('WebSocket error - check connection');
        break;
      default:
        break;
    }
  }

  void _handleSyncResult(SyncResult result) {
    if (result.success) {
      print('Sync completed: ${result.operationId}');
    } else {
      print('Sync failed: ${result.error}');
      // Could show user notification about sync failure
    }
  }

  void _handleDataConflict(DataConflict conflict) {
    print('Data conflict detected: ${conflict.entityType}:${conflict.entityId}');
    
    // Auto-resolve using latest timestamp strategy
    _synchronizer.resolveConflict(conflict, ConflictResolutionStrategy.useLatest);
  }

  void _handleSystemNotification(dynamic data) {
    // Handle system-wide notifications
    final notification = SystemNotification.fromJson(data);
    
    // Show notification to user
    // This could be integrated with a notification service
    print('System notification: ${notification.title}');
  }

  void _handleUserNotification(dynamic data) {
    // Handle user-specific notifications
    final notification = UserNotification.fromJson(data);
    
    // Show notification to user
    print('User notification: ${notification.title}');
  }

  Future<void> _syncPendingChanges() async {
    // Sync any pending changes that occurred while offline
    // This would depend on your specific sync strategy
    print('Syncing pending changes...');
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _webSocketService.disconnect();
  }
}

/// Customer Store - MobX store with WebSocket integration
class CustomerStore = _CustomerStore with _$CustomerStore;

abstract class _CustomerStore with Store {
  final WebSocketManager _webSocketManager;

  _CustomerStore(this._webSocketManager);

  @observable
  ObservableList<Customer> customers = ObservableList<Customer>();

  @observable
  bool isLoading = false;

  @observable
  String? error;

  @action
  Future<void> loadCustomers() async {
    isLoading = true;
    error = null;

    try {
      // Load customers from local database
      final localCustomers = await _loadCustomersFromLocal();
      customers.clear();
      customers.addAll(localCustomers);

      // If connected, sync with server
      if (_webSocketManager.connectionState == WebSocketConnectionState.connected) {
        await _syncWithServer();
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> createCustomer(Map<String, dynamic> customerData) async {
    try {
      // Create customer locally first
      final customer = Customer.fromJson(customerData);
      customers.add(customer);

      // If connected, sync with server immediately
      if (_webSocketManager.connectionState == WebSocketConnectionState.connected) {
        await _createCustomerOnServer(customer);
      } else {
        // Queue for later sync
        await _queueCustomerCreation(customer);
      }
    } catch (e) {
      error = e.toString();
      // Remove from local list if server sync failed
      customers.removeWhere((c) => c.id == customerData['id']);
    }
  }

  @action
  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    try {
      // Update locally first
      final index = customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final updatedCustomer = customers[index].copyWith(updates);
        customers[index] = updatedCustomer;

        // Mark as recently updated for UI feedback
        _markAsRecentlyUpdated(customerId);

        // Sync with server
        if (_webSocketManager.connectionState == WebSocketConnectionState.connected) {
          await _updateCustomerOnServer(updatedCustomer);
        } else {
          await _queueCustomerUpdate(updatedCustomer);
        }
      }
    } catch (e) {
      error = e.toString();
      // Revert local changes if server sync failed
      await loadCustomers();
    }
  }

  @action
  Future<void> deleteCustomer(String customerId) async {
    try {
      // Remove locally first
      final customer = customers.firstWhere((c) => c.id == customerId);
      customers.removeWhere((c) => c.id == customerId);

      // Sync with server
      if (_webSocketManager.connectionState == WebSocketConnectionState.connected) {
        await _deleteCustomerOnServer(customerId);
      } else {
        await _queueCustomerDeletion(customerId);
      }
    } catch (e) {
      error = e.toString();
      // Restore customer if server sync failed
      await loadCustomers();
    }
  }

  void _markAsRecentlyUpdated(String customerId) {
    final index = customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      customers[index] = customers[index].copyWith({'hasRecentUpdate': true});
      
      // Remove the flag after a delay
      Timer(Duration(seconds: 5), () {
        final currentIndex = customers.indexWhere((c) => c.id == customerId);
        if (currentIndex != -1) {
          customers[currentIndex] = customers[currentIndex].copyWith({'hasRecentUpdate': false});
        }
      });
    }
  }

  Future<List<Customer>> _loadCustomersFromLocal() async {
    // Implementation would load from Drift database
    // This is a placeholder
    return [];
  }

  Future<void> _syncWithServer() async {
    // Implementation would sync with server API
    // This is a placeholder
  }

  Future<void> _createCustomerOnServer(Customer customer) async {
    // Implementation would call API to create customer
    // This is a placeholder
  }

  Future<void> _updateCustomerOnServer(Customer customer) async {
    // Implementation would call API to update customer
    // This is a placeholder
  }

  Future<void> _deleteCustomerOnServer(String customerId) async {
    // Implementation would call API to delete customer
    // This is a placeholder
  }

  Future<void> _queueCustomerCreation(Customer customer) async {
    // Implementation would queue operation for later sync
    // This is a placeholder
  }

  Future<void> _queueCustomerUpdate(Customer customer) async {
    // Implementation would queue operation for later sync
    // This is a placeholder
  }

  Future<void> _queueCustomerDeletion(String customerId) async {
    // Implementation would queue operation for later sync
    // This is a placeholder
  }
}

/// App Lifecycle Manager - Handles app state changes
class AppLifecycleManager {
  final WebSocketManager _webSocketManager;
  DateTime? _backgroundTime;

  AppLifecycleManager(this._webSocketManager);

  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }

  void _handleAppResumed() {
    print('App resumed - reconnecting WebSocket');
    
    // Calculate time spent in background
    if (_backgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      print('App was in background for ${backgroundDuration.inMinutes} minutes');
      
      // If app was in background for more than 5 minutes, force full sync
      if (backgroundDuration.inMinutes > 5) {
        _performFullSync();
      }
    }

    // Reconnect WebSocket
    _webSocketManager.initialize();
  }

  void _handleAppPaused() {
    print('App paused - disconnecting WebSocket to save battery');
    _backgroundTime = DateTime.now();
    
    // Disconnect WebSocket to save battery
    _webSocketManager._webSocketService.disconnect();
  }

  void _handleAppDetached() {
    print('App detached - cleaning up resources');
    _webSocketManager.dispose();
  }

  void _performFullSync() {
    print('Performing full sync after extended background time');
    // Implementation would trigger full data sync
  }
}

/// Customer Form Dialog - Example of form with real-time validation
class CustomerFormDialog extends StatefulWidget {
  final Customer? customer;
  final Function(Map<String, dynamic>) onSave;

  const CustomerFormDialog({
    Key? key,
    this.customer,
    required this.onSave,
  }) : super(key: key);

  @override
  _CustomerFormDialogState createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _addressController.text = widget.customer!.address;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCustomer,
          child: Text('Save'),
        ),
      ],
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customerData = {
        'id': widget.customer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      };

      widget.onSave(customerData);
      Navigator.pop(context);
    }
  }
}

/// Customer Details Screen - Example of real-time detail view
class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailsScreen({Key? key, required this.customer}) : super(key: key);

  @override
  _CustomerDetailsScreenState createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _customer;
  late StreamSubscription _webSocketSubscription;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _setupWebSocketListener();
  }

  @override
  void dispose() {
    _webSocketSubscription.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    final webSocketService = GetIt.instance<IWebSocketService>();
    
    // Listen for updates to this specific customer
    _webSocketSubscription = webSocketService.messageStream
        .where((message) => 
            message.type == 'customer.updated' && 
            message.data['customerId'] == _customer.id)
        .listen((message) {
      setState(() {
        _customer = Customer.fromJson(message.data['customerData']);
      });
      
      // Show notification about the update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Customer information updated'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_customer.name),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _editCustomer,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard('Name', _customer.name, Icons.person),
            SizedBox(height: 16),
            _buildDetailCard('Phone', _customer.phone, Icons.phone),
            SizedBox(height: 16),
            _buildDetailCard('Address', _customer.address, Icons.location_on),
            SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.update, color: Colors.green),
              title: Text('Customer information updated'),
              subtitle: Text('2 minutes ago'),
              dense: true,
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.blue),
              title: Text('New order placed'),
              subtitle: Text('1 hour ago'),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  void _editCustomer() {
    showDialog(
      context: context,
      builder: (context) => CustomerFormDialog(
        customer: _customer,
        onSave: (customerData) async {
          // Update customer through store
          final customerStore = GetIt.instance<CustomerStore>();
          await customerStore.updateCustomer(_customer.id, customerData);
        },
      ),
    );
  }
}

/// Data Models
class Customer {
  final String id;
  final String name;
  final String phone;
  final String address;
  final bool hasRecentUpdate;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    this.hasRecentUpdate = false,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      hasRecentUpdate: json['hasRecentUpdate'] ?? false,
    );
  }

  Customer copyWith(Map<String, dynamic> updates) {
    return Customer(
      id: updates['id'] ?? id,
      name: updates['name'] ?? name,
      phone: updates['phone'] ?? phone,
      address: updates['address'] ?? address,
      hasRecentUpdate: updates['hasRecentUpdate'] ?? hasRecentUpdate,
    );
  }
}

class SystemNotification {
  final String title;
  final String message;
  final String type;

  SystemNotification({
    required this.title,
    required this.message,
    required this.type,
  });

  factory SystemNotification.fromJson(Map<String, dynamic> json) {
    return SystemNotification(
      title: json['title'],
      message: json['message'],
      type: json['type'],
    );
  }
}

class UserNotification {
  final String title;
  final String message;
  final String type;
  final String? relatedEntityId;

  UserNotification({
    required this.title,
    required this.message,
    required this.type,
    this.relatedEntityId,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      title: json['title'],
      message: json['message'],
      type: json['type'],
      relatedEntityId: json['relatedEntityId'],
    );
  }
}