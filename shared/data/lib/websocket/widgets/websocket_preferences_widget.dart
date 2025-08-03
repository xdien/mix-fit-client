import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../models/websocket_message_type.dart';
import '../stores/websocket_preferences_store.dart';

/// Widget for managing WebSocket preferences and notification controls
class WebSocketPreferencesWidget extends StatelessWidget {
  final WebSocketPreferencesStore store;

  const WebSocketPreferencesWidget({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (store.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              
              if (store.errorMessage != null)
                _buildErrorMessage(context),
              
              _buildGeneralSettings(context),
              const SizedBox(height: 24),
              
              _buildNotificationSettings(context),
              const SizedBox(height: 24),
              
              _buildMessageTypeSettings(context),
              const SizedBox(height: 24),
              
              _buildChannelSettings(context),
              const SizedBox(height: 24),
              
              _buildAdvancedSettings(context),
              const SizedBox(height: 24),
              
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Real-time Updates',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure how you receive real-time notifications and updates',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              store.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          IconButton(
            onPressed: store.clearError,
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'General Settings',
      children: [
        SwitchListTile(
          title: const Text('Enable Real-time Updates'),
          subtitle: const Text('Receive live updates from the server'),
          value: store.isRealTimeEnabled,
          onChanged: store.setRealTimeEnabled,
        ),
        SwitchListTile(
          title: const Text('Show Connection Status'),
          subtitle: const Text('Display connection indicator in the app'),
          value: store.isConnectionStatusVisible,
          onChanged: store.setConnectionStatusVisible,
        ),
        SwitchListTile(
          title: const Text('Auto-reconnect'),
          subtitle: const Text('Automatically reconnect when connection is lost'),
          value: store.isAutoReconnectEnabled,
          onChanged: store.setAutoReconnectEnabled,
        ),
      ],
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Notification Settings',
      children: [
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Show notifications for real-time updates'),
          value: store.areNotificationsEnabled,
          onChanged: store.setNotificationsEnabled,
        ),
        SwitchListTile(
          title: const Text('Sound Notifications'),
          subtitle: const Text('Play sound for notifications'),
          value: store.areSoundNotificationsEnabled,
          onChanged: store.setSoundNotificationsEnabled,
          secondary: const Icon(Icons.volume_up),
        ),
        SwitchListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Vibrate for notifications'),
          value: store.areVibrationNotificationsEnabled,
          onChanged: store.setVibrationNotificationsEnabled,
          secondary: const Icon(Icons.vibration),
        ),
        SwitchListTile(
          title: const Text('Foreground Notifications'),
          subtitle: const Text('Show notifications when app is open'),
          value: store.areForegroundNotificationsEnabled,
          onChanged: store.setForegroundNotificationsEnabled,
        ),
      ],
    );
  }

  Widget _buildMessageTypeSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Message Types',
      subtitle: 'Choose which types of updates you want to receive',
      children: [
        ...WebSocketMessageType.values
            .where((type) => type != WebSocketMessageType.unknown)
            .map((messageType) => _buildMessageTypeItem(context, messageType))
            .toList(),
      ],
    );
  }

  Widget _buildMessageTypeItem(BuildContext context, WebSocketMessageType messageType) {
    final isEnabled = store.isMessageTypeEnabled(messageType);
    final priority = store.getMessageTypePriority(messageType);
    
    return ExpansionTile(
      leading: Checkbox(
        value: isEnabled,
        onChanged: (value) => store.setMessageTypeEnabled(messageType, value ?? false),
      ),
      title: Text(_getMessageTypeDisplayName(messageType)),
      subtitle: Text('Priority: ${_getPriorityDisplayName(priority)}'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              ListTile(
                title: const Text('Priority Level'),
                subtitle: Slider(
                  value: priority.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _getPriorityDisplayName(priority),
                  onChanged: (value) => store.setMessageTypePriority(
                    messageType,
                    value.round(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _getMessageTypeDescription(messageType),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelSettings(BuildContext context) {
    final availableChannels = ['inventory', 'customers', 'orders', 'system'];
    
    return _buildSettingsSection(
      context,
      title: 'Channels',
      subtitle: 'Select which data channels to subscribe to',
      children: availableChannels.map((channel) {
        final isEnabled = store.isChannelEnabled(channel);
        return SwitchListTile(
          title: Text(_getChannelDisplayName(channel)),
          subtitle: Text(_getChannelDescription(channel)),
          value: isEnabled,
          onChanged: (value) => store.setChannelEnabled(channel, value),
          secondary: Icon(_getChannelIcon(channel)),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSettings(BuildContext context) {
    return _buildSettingsSection(
      context,
      title: 'Advanced Settings',
      children: [
        SwitchListTile(
          title: const Text('Offline Message Queue'),
          subtitle: const Text('Queue messages when offline'),
          value: store.isOfflineQueueEnabled,
          onChanged: store.setOfflineQueueEnabled,
        ),
        ListTile(
          title: const Text('Max Queued Messages'),
          subtitle: Text('Current: ${store.maxQueuedMessages} messages'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: store.maxQueuedMessages.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (value) => store.setMaxQueuedMessages(value.round()),
            ),
          ),
        ),
        ListTile(
          title: const Text('Heartbeat Interval'),
          subtitle: Text('Current: ${store.heartbeatInterval} seconds'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: store.heartbeatInterval.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              onChanged: (value) => store.setHeartbeatInterval(value.round()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: store.resetToDefaults,
          icon: const Icon(Icons.restore),
          label: const Text('Reset to Defaults'),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  String _getMessageTypeDisplayName(WebSocketMessageType messageType) {
    switch (messageType) {
      case WebSocketMessageType.customerUpdate:
        return 'Customer Updates';
      case WebSocketMessageType.inventoryUpdate:
        return 'Inventory Updates';
      case WebSocketMessageType.orderStatusUpdate:
        return 'Order Status Updates';
      case WebSocketMessageType.systemNotification:
        return 'System Notifications';
      case WebSocketMessageType.userSpecific:
        return 'User-specific Messages';
      case WebSocketMessageType.unknown:
        return 'Unknown Messages';
    }
  }

  String _getMessageTypeDescription(WebSocketMessageType messageType) {
    switch (messageType) {
      case WebSocketMessageType.customerUpdate:
        return 'Notifications when customer information is modified';
      case WebSocketMessageType.inventoryUpdate:
        return 'Notifications when inventory levels change';
      case WebSocketMessageType.orderStatusUpdate:
        return 'Notifications when order status changes';
      case WebSocketMessageType.systemNotification:
        return 'Important system-wide notifications';
      case WebSocketMessageType.userSpecific:
        return 'Messages targeted specifically to you';
      case WebSocketMessageType.unknown:
        return 'Unrecognized message types';
    }
  }

  String _getPriorityDisplayName(int priority) {
    switch (priority) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Medium';
      case 4:
        return 'High';
      case 5:
        return 'Critical';
      default:
        return 'Medium';
    }
  }

  String _getChannelDisplayName(String channel) {
    switch (channel) {
      case 'inventory':
        return 'Inventory';
      case 'customers':
        return 'Customers';
      case 'orders':
        return 'Orders';
      case 'system':
        return 'System';
      default:
        return channel.toUpperCase();
    }
  }

  String _getChannelDescription(String channel) {
    switch (channel) {
      case 'inventory':
        return 'Stock levels and inventory changes';
      case 'customers':
        return 'Customer information updates';
      case 'orders':
        return 'Order status and processing updates';
      case 'system':
        return 'System-wide notifications and alerts';
      default:
        return 'Updates from $channel';
    }
  }

  IconData _getChannelIcon(String channel) {
    switch (channel) {
      case 'inventory':
        return Icons.inventory;
      case 'customers':
        return Icons.people;
      case 'orders':
        return Icons.shopping_cart;
      case 'system':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }
}