import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:data/websocket/interfaces/i_websocket_service.dart';
import '../stores/websocket_status_store.dart';
import 'websocket_status_bar_widget.dart';
import 'websocket_offline_mode_widget.dart';
import 'websocket_status_page.dart';

/// Example integration showing how to use WebSocket status UI components
/// This demonstrates the complete integration pattern for the WebSocket status UI
class WebSocketStatusIntegrationExample extends StatefulWidget {
  const WebSocketStatusIntegrationExample({Key? key}) : super(key: key);

  @override
  State<WebSocketStatusIntegrationExample> createState() => _WebSocketStatusIntegrationExampleState();
}

class _WebSocketStatusIntegrationExampleState extends State<WebSocketStatusIntegrationExample> {
  late WebSocketStatusStore _statusStore;

  @override
  void initState() {
    super.initState();
    
    // Initialize the status store with the WebSocket service
    // In a real app, this would be injected via dependency injection
    final webSocketService = GetIt.instance<IWebSocketService>();
    _statusStore = WebSocketStatusStore(webSocketService);
  }

  @override
  void dispose() {
    _statusStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Status Integration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showStatusDialog(context),
            tooltip: 'Connection Details',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar at the top
          Observer(
            builder: (context) => _statusStore.isStatusBarVisible
                ? WebSocketStatusBarWidget(
                    connectionState: _statusStore.connectionState,
                    lastError: _statusStore.lastError,
                    reconnectAttempts: _statusStore.reconnectAttempts,
                    lastResponseTime: _statusStore.lastResponseTime,
                    showDetails: _statusStore.showConnectionDetails,
                    isMinimized: _statusStore.isStatusBarMinimized,
                    onTap: () => _statusStore.toggleStatusBarMinimized(),
                    onRetry: () => _statusStore.retryConnection(),
                    onDismiss: () => _statusStore.hideStatusBar(),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Main content area
          Expanded(
            child: Stack(
              children: [
                // Your main app content goes here
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your App Content',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'WebSocket status components are integrated above',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // Offline mode overlay
                Observer(
                  builder: (context) => _statusStore.shouldShowOfflineMode
                      ? Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: WebSocketOfflineModeWidget(
                                connectionState: _statusStore.connectionState,
                                lastError: _statusStore.lastError,
                                lastConnectedTime: _statusStore.lastConnectedTime,
                                queuedUpdatesCount: _statusStore.queuedUpdatesCount,
                                onRetryConnection: () => _statusStore.retryConnection(),
                                onViewQueuedUpdates: () => _showQueuedUpdates(context),
                                onClearQueue: () => _statusStore.clearQueuedUpdates(),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Floating action button to show status details
      floatingActionButton: Observer(
        builder: (context) => FloatingActionButton(
          onPressed: () => _showStatusDialog(context),
          tooltip: 'Connection Status',
          child: Icon(
            _getStatusIcon(_statusStore.connectionState),
            color: _getStatusColor(_statusStore.connectionState),
          ),
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => WebSocketStatusPage(
        statusStore: _statusStore,
        isDialog: true,
      ),
    );
  }

  void _showQueuedUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Queued Updates'),
        content: Text(
          'There are ${_statusStore.queuedUpdatesCount} updates queued. '
          'These will be processed when the connection is restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(connectionState) {
    switch (connectionState) {
      case 'connected':
        return Icons.wifi;
      case 'connecting':
      case 'reconnecting':
        return Icons.wifi_find;
      case 'disconnected':
        return Icons.wifi_off;
      case 'error':
        return Icons.wifi_off;
      default:
        return Icons.wifi_off;
    }
  }

  Color _getStatusColor(connectionState) {
    switch (connectionState) {
      case 'connected':
        return Colors.green;
      case 'connecting':
      case 'reconnecting':
        return Colors.orange;
      case 'disconnected':
        return Colors.grey;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Example of how to integrate WebSocket status components into an existing app
/// This shows a minimal integration approach
class MinimalWebSocketStatusIntegration extends StatelessWidget {
  final WebSocketStatusStore statusStore;

  const MinimalWebSocketStatusIntegration({
    Key? key,
    required this.statusStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple status bar integration
        Observer(
          builder: (context) => WebSocketStatusBarWidget(
            connectionState: statusStore.connectionState,
            lastError: statusStore.lastError,
            isMinimized: true, // Always minimized for minimal integration
            onRetry: () => statusStore.retryConnection(),
          ),
        ),
        
        // Your existing app content
        const Expanded(
          child: Center(
            child: Text('Your App Content'),
          ),
        ),
      ],
    );
  }
}