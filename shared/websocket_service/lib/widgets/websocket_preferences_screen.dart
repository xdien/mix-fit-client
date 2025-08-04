import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/websocket_preferences_store.dart';
import '../models/websocket_preferences.dart';
import 'websocket_channel_preferences_widget.dart';

class WebSocketPreferencesScreen extends StatelessWidget {
  final WebSocketPreferencesStore store;

  const WebSocketPreferencesScreen({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Preferences'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => store.resetToDefaults(),
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: Observer(
        builder: (context) {
          if (store.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildGeneralSettings(context),
              const SizedBox(height: 24),
              _buildChannelSettings(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'General Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (context) => SwitchListTile(
                title: const Text('Enable Real-time Updates'),
                subtitle: const Text('Receive live data updates via WebSocket'),
                value: store.enableRealTimeUpdates,
                onChanged: (value) => store.setRealTimeUpdatesEnabled(value),
              ),
            ),
            Observer(
              builder: (context) => SwitchListTile(
                title: const Text('Show Connection Status'),
                subtitle: const Text('Display WebSocket connection status in UI'),
                value: store.showConnectionStatus,
                onChanged: (value) => store.setConnectionStatusEnabled(value),
              ),
            ),
            Observer(
              builder: (context) => SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Show notifications for WebSocket events'),
                value: store.enableNotifications,
                onChanged: (value) => store.setNotificationsEnabled(value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Channel Subscriptions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Configure which types of real-time updates you want to receive',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 16),
            Observer(
              builder: (context) {
                return Column(
                  children: store.availableChannels.map((channel) {
                    return WebSocketChannelPreferencesWidget(
                      channel: channel,
                      store: store,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}