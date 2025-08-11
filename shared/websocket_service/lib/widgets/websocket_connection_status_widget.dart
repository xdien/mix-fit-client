import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/websocket_preferences_store.dart';

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class WebSocketConnectionStatusWidget extends StatelessWidget {
  final WebSocketPreferencesStore preferencesStore;
  final WebSocketConnectionState connectionState;
  final String? errorMessage;
  final VoidCallback? onTap;

  const WebSocketConnectionStatusWidget({
    Key? key,
    required this.preferencesStore,
    required this.connectionState,
    this.errorMessage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (!preferencesStore.showConnectionStatus) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(connectionState).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(connectionState).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(),
                  style: TextStyle(
                    color: _getStatusColor(connectionState),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return Icon(
          Icons.wifi,
          size: 16,
          color: _getStatusColor(connectionState),
        );
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getStatusColor(connectionState),
            ),
          ),
        );
      case WebSocketConnectionState.disconnected:
        return Icon(
          Icons.wifi_off,
          size: 16,
          color: _getStatusColor(connectionState),
        );
      case WebSocketConnectionState.error:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: _getStatusColor(connectionState),
        );
    }
  }

  String _getStatusText() {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return 'Connected';
      case WebSocketConnectionState.connecting:
        return 'Connecting...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting...';
      case WebSocketConnectionState.disconnected:
        return 'Offline';
      case WebSocketConnectionState.error:
        return 'Error';
    }
  }

  Color _getStatusColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
      case WebSocketConnectionState.error:
        return Colors.red;
    }
  }
}

class WebSocketConnectionStatusBar extends StatelessWidget {
  final WebSocketPreferencesStore preferencesStore;
  final WebSocketConnectionState connectionState;
  final String? errorMessage;
  final VoidCallback? onTap;

  const WebSocketConnectionStatusBar({
    Key? key,
    required this.preferencesStore,
    required this.connectionState,
    this.errorMessage,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (!preferencesStore.showConnectionStatus || 
            connectionState == WebSocketConnectionState.connected) {
          return const SizedBox.shrink();
        }

        return Material(
          color: _getStatusColor(connectionState),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildStatusIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getStatusText(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            errorMessage!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return const Icon(Icons.wifi, color: Colors.white, size: 20);
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case WebSocketConnectionState.disconnected:
        return const Icon(Icons.wifi_off, color: Colors.white, size: 20);
      case WebSocketConnectionState.error:
        return const Icon(Icons.error_outline, color: Colors.white, size: 20);
    }
  }

  String _getStatusText() {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return 'Connected to real-time updates';
      case WebSocketConnectionState.connecting:
        return 'Connecting to real-time updates...';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting to real-time updates...';
      case WebSocketConnectionState.disconnected:
        return 'Real-time updates unavailable';
      case WebSocketConnectionState.error:
        return 'Connection error';
    }
  }

  Color _getStatusColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
      case WebSocketConnectionState.error:
        return Colors.red;
    }
  }
}