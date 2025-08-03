import 'package:flutter/material.dart';
import '../stores/websocket_preferences_store.dart';
import 'websocket_preferences_widget.dart';

/// Settings page for WebSocket preferences
class WebSocketSettingsPage extends StatelessWidget {
  final WebSocketPreferencesStore store;

  const WebSocketSettingsPage({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Settings'),
        elevation: 0,
      ),
      body: WebSocketPreferencesWidget(store: store),
    );
  }
}

/// Dialog version of WebSocket settings for use in other screens
class WebSocketSettingsDialog extends StatelessWidget {
  final WebSocketPreferencesStore store;

  const WebSocketSettingsDialog({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Real-time Settings'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: WebSocketPreferencesWidget(store: store),
            ),
          ],
        ),
      ),
    );
  }

  /// Show the settings dialog
  static Future<void> show(BuildContext context, WebSocketPreferencesStore store) {
    return showDialog<void>(
      context: context,
      builder: (context) => WebSocketSettingsDialog(store: store),
    );
  }
}

/// Bottom sheet version of WebSocket settings
class WebSocketSettingsBottomSheet extends StatelessWidget {
  final WebSocketPreferencesStore store;

  const WebSocketSettingsBottomSheet({
    Key? key,
    required this.store,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Real-time Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: WebSocketPreferencesWidget(store: store),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show the settings bottom sheet
  static Future<void> show(BuildContext context, WebSocketPreferencesStore store) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WebSocketSettingsBottomSheet(store: store),
    );
  }
}