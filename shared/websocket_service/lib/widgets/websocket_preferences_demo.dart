import 'package:flutter/material.dart';
import '../stores/websocket_preferences_store.dart';
import 'websocket_preferences_screen.dart';
import 'websocket_connection_status_widget.dart';

/// Demo widget showing how to integrate WebSocket preferences
/// This demonstrates the complete integration of the preferences system
class WebSocketPreferencesDemo extends StatefulWidget {
  const WebSocketPreferencesDemo({Key? key}) : super(key: key);

  @override
  State<WebSocketPreferencesDemo> createState() => _WebSocketPreferencesDemoState();
}

class _WebSocketPreferencesDemoState extends State<WebSocketPreferencesDemo> {
  late WebSocketPreferencesStore _preferencesStore;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    // In a real app, this would be injected via GetIt
    // _preferencesStore = GetIt.instance<WebSocketPreferencesStore>();
    
    // For demo purposes, we'll create a mock store
    // In real implementation, this should be properly injected
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Preferences Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openPreferences,
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status bar
          WebSocketConnectionStatusBar(
            preferencesStore: _preferencesStore,
            connectionState: _connectionState,
            onTap: _showConnectionDetails,
          ),
          
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WebSocket Preferences Integration Demo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  
                  _buildConnectionControls(),
                  const SizedBox(height: 24),
                  
                  _buildPreferencesInfo(),
                  const SizedBox(height: 24),
                  
                  _buildUsageInstructions(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPreferences,
        child: const Icon(Icons.tune),
        tooltip: 'Open WebSocket Preferences',
      ),
    );
  }

  Widget _buildConnectionControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Controls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                WebSocketConnectionStatusWidget(
                  preferencesStore: _preferencesStore,
                  connectionState: _connectionState,
                  onTap: _showConnectionDetails,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _toggleConnection,
                  child: Text(_connectionState == WebSocketConnectionState.connected 
                      ? 'Disconnect' : 'Connect'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // This would use Observer in real implementation
            Text('Real-time Updates: ${_preferencesStore.enableRealTimeUpdates ? 'Enabled' : 'Disabled'}'),
            Text('Show Connection Status: ${_preferencesStore.showConnectionStatus ? 'Enabled' : 'Disabled'}'),
            Text('Notifications: ${_preferencesStore.enableNotifications ? 'Enabled' : 'Disabled'}'),
            Text('Subscribed Channels: ${_preferencesStore.subscribedChannels.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usage Instructions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const Text('1. Tap the settings icon to configure WebSocket preferences'),
            const Text('2. Enable/disable real-time updates globally'),
            const Text('3. Configure individual channel subscriptions'),
            const Text('4. Set notification priorities for each channel'),
            const Text('5. Control connection status visibility'),
            const SizedBox(height: 12),
            const Text(
              'The preferences system automatically manages channel subscriptions '
              'and notification filtering based on user settings.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _openPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebSocketPreferencesScreen(
          store: _preferencesStore,
        ),
      ),
    );
  }

  void _toggleConnection() {
    setState(() {
      if (_connectionState == WebSocketConnectionState.connected) {
        _connectionState = WebSocketConnectionState.disconnected;
      } else {
        _connectionState = WebSocketConnectionState.connecting;
        // Simulate connection process
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _connectionState = WebSocketConnectionState.connected;
            });
          }
        });
      }
    });
  }

  void _showConnectionDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${_connectionState.toString().split('.').last}'),
            const SizedBox(height: 8),
            Text('Active Channels: ${_preferencesStore.activeSubscribedChannels.length}'),
            const SizedBox(height: 8),
            Text('Channels: ${_preferencesStore.activeSubscribedChannels.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}