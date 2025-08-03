import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';

/// A widget that displays the current WebSocket connection status
/// with visual indicators for different connection states
class WebSocketConnectionStatusWidget extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final WebSocketError? lastError;
  final bool showText;
  final bool isCompact;
  final VoidCallback? onTap;

  const WebSocketConnectionStatusWidget({
    Key? key,
    required this.connectionState,
    this.lastError,
    this.showText = true,
    this.isCompact = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8.0 : 12.0,
          vertical: isCompact ? 4.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(isCompact ? 12.0 : 16.0),
          border: Border.all(
            color: _getBorderColor(context),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            if (showText && !isCompact) ...[
              const SizedBox(width: 8.0),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: isCompact ? 12.0 : 14.0,
                  fontWeight: FontWeight.w500,
                  color: _getTextColor(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return Icon(
          Icons.wifi,
          color: Colors.green,
          size: isCompact ? 16.0 : 20.0,
        );
      case WebSocketConnectionState.connecting:
        return SizedBox(
          width: isCompact ? 16.0 : 20.0,
          height: isCompact ? 16.0 : 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        );
      case WebSocketConnectionState.reconnecting:
        return SizedBox(
          width: isCompact ? 16.0 : 20.0,
          height: isCompact ? 16.0 : 20.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        );
      case WebSocketConnectionState.disconnected:
        return Icon(
          Icons.wifi_off,
          color: Colors.grey,
          size: isCompact ? 16.0 : 20.0,
        );
      case WebSocketConnectionState.error:
        return Icon(
          Icons.error_outline,
          color: Colors.red,
          size: isCompact ? 16.0 : 20.0,
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
        return lastError?.isRecoverable == true ? 'Connection Error' : 'Error';
    }
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return Colors.green.withOpacity(0.1);
      case WebSocketConnectionState.connecting:
        return Colors.blue.withOpacity(0.1);
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.withOpacity(0.1);
      case WebSocketConnectionState.disconnected:
        return theme.colorScheme.surface;
      case WebSocketConnectionState.error:
        return Colors.red.withOpacity(0.1);
    }
  }

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return Colors.green.withOpacity(0.3);
      case WebSocketConnectionState.connecting:
        return Colors.blue.withOpacity(0.3);
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.withOpacity(0.3);
      case WebSocketConnectionState.disconnected:
        return theme.colorScheme.outline.withOpacity(0.3);
      case WebSocketConnectionState.error:
        return Colors.red.withOpacity(0.3);
    }
  }

  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return Colors.green.shade700;
      case WebSocketConnectionState.connecting:
        return Colors.blue.shade700;
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.shade700;
      case WebSocketConnectionState.disconnected:
        return theme.colorScheme.onSurface.withOpacity(0.7);
      case WebSocketConnectionState.error:
        return Colors.red.shade700;
    }
  }
}