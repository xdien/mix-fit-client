import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/websocket_preferences_store.dart';
import '../models/websocket_channel_config.dart';
import '../models/websocket_preferences.dart';

class WebSocketChannelPreferencesWidget extends StatelessWidget {
  final WebSocketChannelConfig channel;
  final WebSocketPreferencesStore store;

  const WebSocketChannelPreferencesWidget({
    Key? key,
    required this.channel,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!channel.userConfigurable) {
      return _buildNonConfigurableChannel(context);
    }

    return Observer(
      builder: (context) {
        final isEnabled = store.preferences?.channelPreferences[channel.id] ?? channel.defaultEnabled;
        final priority = store.preferences?.notificationPriorities[channel.id] ?? channel.defaultPriority;

        return ExpansionTile(
          leading: Icon(_getChannelIcon(channel.type)),
          title: Text(channel.name),
          subtitle: Text(channel.description),
          trailing: Switch(
            value: isEnabled,
            onChanged: (value) => store.setChannelEnabled(channel.id, value),
          ),
          children: [
            if (isEnabled) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Priority',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _buildPrioritySelector(context, priority),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildNonConfigurableChannel(BuildContext context) {
    return Observer(
      builder: (context) {
        final isEnabled = store.preferences?.channelPreferences[channel.id] ?? channel.defaultEnabled;
        
        return ListTile(
          leading: Icon(_getChannelIcon(channel.type)),
          title: Text(channel.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(channel.description),
              const SizedBox(height: 4),
              Text(
                'System managed - cannot be disabled',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          trailing: Icon(
            isEnabled ? Icons.check_circle : Icons.cancel,
            color: isEnabled ? Colors.green : Colors.grey,
          ),
        );
      },
    );
  }

  Widget _buildPrioritySelector(BuildContext context, NotificationPriority currentPriority) {
    return Wrap(
      spacing: 8.0,
      children: NotificationPriority.values.map((priority) {
        final isSelected = priority == currentPriority;
        return FilterChip(
          label: Text(priority.displayName),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              store.setChannelPriority(channel.id, priority);
            }
          },
                  backgroundColor: _getPriorityColor(priority).withValues(alpha: 0.1),
        selectedColor: _getPriorityColor(priority).withValues(alpha: 0.3),
          checkmarkColor: _getPriorityColor(priority),
        );
      }).toList(),
    );
  }

  IconData _getChannelIcon(WebSocketChannelType type) {
    switch (type) {
      case WebSocketChannelType.customer:
        return Icons.people;
      case WebSocketChannelType.inventory:
        return Icons.inventory;
      case WebSocketChannelType.order:
        return Icons.shopping_cart;
      case WebSocketChannelType.system:
        return Icons.settings;
      case WebSocketChannelType.notification:
        return Icons.notifications;
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.green;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.critical:
        return Colors.red;
    }
  }
}