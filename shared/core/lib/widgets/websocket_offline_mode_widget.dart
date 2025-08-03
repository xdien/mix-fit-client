import 'package:flutter/material.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';

/// A widget that displays offline mode information and provides
/// options for users when the WebSocket connection is unavailable
class WebSocketOfflineModeWidget extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final WebSocketError? lastError;
  final DateTime? lastConnectedTime;
  final int queuedUpdatesCount;
  final VoidCallback? onRetryConnection;
  final VoidCallback? onViewQueuedUpdates;
  final VoidCallback? onClearQueue;
  final bool showQueuedUpdates;

  const WebSocketOfflineModeWidget({
    Key? key,
    required this.connectionState,
    this.lastError,
    this.lastConnectedTime,
    this.queuedUpdatesCount = 0,
    this.onRetryConnection,
    this.onViewQueuedUpdates,
    this.onClearQueue,
    this.showQueuedUpdates = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show when actually offline or in error state
    if (connectionState == WebSocketConnectionState.connected ||
        connectionState == WebSocketConnectionState.connecting) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: _getBorderColor(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12.0),
          _buildDescription(context),
          if (lastConnectedTime != null) ...[
            const SizedBox(height: 8.0),
            _buildLastConnectedInfo(context),
          ],
          if (showQueuedUpdates && queuedUpdatesCount > 0) ...[
            const SizedBox(height: 12.0),
            _buildQueuedUpdatesSection(context),
          ],
          const SizedBox(height: 16.0),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          _getHeaderIcon(),
          color: _getIconColor(),
          size: 24.0,
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Text(
            _getHeaderText(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _getIconColor(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      _getDescriptionText(),
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
      ),
    );
  }

  Widget _buildLastConnectedInfo(BuildContext context) {
    final timeAgo = _getTimeAgoText(lastConnectedTime!);
    
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: 16.0,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 6.0),
          Text(
            'Last connected $timeAgo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueuedUpdatesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.queue,
                size: 18.0,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Queued Updates',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            '$queuedUpdatesCount updates are queued and will be processed when connection is restored.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue.shade600,
            ),
          ),
          if (onViewQueuedUpdates != null || onClearQueue != null) ...[
            const SizedBox(height: 8.0),
            Row(
              children: [
                if (onViewQueuedUpdates != null)
                  TextButton(
                    onPressed: onViewQueuedUpdates,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('View Queue'),
                  ),
                if (onClearQueue != null) ...[
                  const SizedBox(width: 8.0),
                  TextButton(
                    onPressed: onClearQueue,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      minimumSize: const Size(0, 32),
                      foregroundColor: Colors.red.shade600,
                    ),
                    child: const Text('Clear Queue'),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onRetryConnection != null)
          ElevatedButton.icon(
            onPressed: onRetryConnection,
            icon: const Icon(Icons.refresh, size: 18.0),
            label: const Text('Retry Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getIconColor(),
              foregroundColor: Colors.white,
            ),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }

  IconData _getHeaderIcon() {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return Icons.wifi_off;
      case WebSocketConnectionState.error:
        return Icons.error_outline;
      case WebSocketConnectionState.reconnecting:
        return Icons.sync_problem;
      default:
        return Icons.cloud_off;
    }
  }

  Color _getIconColor() {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return Colors.grey.shade600;
      case WebSocketConnectionState.error:
        return Colors.red.shade600;
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return Colors.grey.withOpacity(0.3);
      case WebSocketConnectionState.error:
        return Colors.red.withOpacity(0.3);
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.withOpacity(0.3);
      default:
        return Theme.of(context).colorScheme.outline.withOpacity(0.3);
    }
  }

  String _getHeaderText() {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return 'Working Offline';
      case WebSocketConnectionState.error:
        return 'Connection Error';
      case WebSocketConnectionState.reconnecting:
        return 'Reconnecting...';
      default:
        return 'Offline Mode';
    }
  }

  String _getDescriptionText() {
    switch (connectionState) {
      case WebSocketConnectionState.disconnected:
        return 'You\'re currently working offline. Real-time updates are not available, but you can continue using the app with cached data.';
      case WebSocketConnectionState.error:
        if (lastError != null) {
          return 'Unable to connect to the server. ${_getErrorHint(lastError!)} You can continue working with cached data.';
        }
        return 'Unable to connect to the server. Please check your internet connection and try again.';
      case WebSocketConnectionState.reconnecting:
        return 'Attempting to reconnect to the server. Your changes will be synchronized once the connection is restored.';
      default:
        return 'Real-time updates are currently unavailable. You can continue working with cached data.';
    }
  }

  String _getErrorHint(WebSocketError error) {
    switch (error.type) {
      case WebSocketErrorType.networkError:
        return 'Please check your internet connection.';
      case WebSocketErrorType.authenticationFailed:
        return 'Please try logging in again.';
      case WebSocketErrorType.serverError:
        return 'The server is temporarily unavailable.';
      case WebSocketErrorType.connectionTimeout:
        return 'The connection timed out.';
      default:
        return '';
    }
  }

  String _getTimeAgoText(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}