import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import '../stores/websocket_status_store.dart';
import 'websocket_connection_status_widget.dart';
import 'websocket_connection_quality_widget.dart';

/// A comprehensive page/dialog showing detailed WebSocket connection status
class WebSocketStatusPage extends StatelessWidget {
  final WebSocketStatusStore statusStore;
  final bool isDialog;

  const WebSocketStatusPage({
    Key? key,
    required this.statusStore,
    this.isDialog = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDialog) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: _buildContent(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Status'),
        elevation: 0,
      ),
      body: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Observer(
      builder: (context) => Container(
        constraints: isDialog 
            ? const BoxConstraints(maxWidth: 400, maxHeight: 600)
            : null,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: isDialog ? MainAxisSize.min : MainAxisSize.max,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24.0),
            _buildConnectionOverview(context),
            const SizedBox(height: 24.0),
            _buildConnectionDetails(context),
            if (statusStore.hasError) ...[
              const SizedBox(height: 24.0),
              _buildErrorDetails(context),
            ],
            if (statusStore.queuedUpdatesCount > 0) ...[
              const SizedBox(height: 24.0),
              _buildQueuedUpdatesSection(context),
            ],
            const SizedBox(height: 24.0),
            _buildActionButtons(context),
            if (isDialog) ...[
              const SizedBox(height: 16.0),
              _buildDialogActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Observer(
          builder: (context) => WebSocketConnectionStatusWidget(
            connectionState: statusStore.connectionState,
            lastError: statusStore.lastError,
            showText: true,
            isCompact: false,
          ),
        ),
        const Spacer(),
        Observer(
          builder: (context) => WebSocketConnectionQualityWidget.fromMetrics(
            connectionState: statusStore.connectionState,
            reconnectAttempts: statusStore.reconnectAttempts,
            lastResponseTime: statusStore.lastResponseTime,
            showQualityText: true,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionOverview(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),
            Observer(
              builder: (context) => Column(
                children: [
                  _buildInfoRow(
                    'Status',
                    statusStore.statusText,
                    _getStatusColor(statusStore.connectionState),
                  ),
                  if (statusStore.lastConnectedTime != null)
                    _buildInfoRow(
                      'Last Connected',
                      _formatDateTime(statusStore.lastConnectedTime!),
                    ),
                  if (statusStore.reconnectAttempts > 0)
                    _buildInfoRow(
                      'Reconnect Attempts',
                      '${statusStore.reconnectAttempts}',
                      Colors.orange,
                    ),
                  if (statusStore.lastResponseTime != null)
                    _buildInfoRow(
                      'Response Time',
                      '${statusStore.lastResponseTime!.inMilliseconds}ms',
                      _getResponseTimeColor(statusStore.lastResponseTime!),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionDetails(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),
            Observer(
              builder: (context) => Column(
                children: [
                  _buildInfoRow(
                    'Real-time Updates',
                    statusStore.isConnected ? 'Active' : 'Inactive',
                    statusStore.isConnected ? Colors.green : Colors.grey,
                  ),
                  _buildInfoRow(
                    'Auto Reconnect',
                    'Enabled',
                    Colors.blue,
                  ),
                  _buildInfoRow(
                    'Connection Type',
                    'WebSocket',
                  ),
                  if (statusStore.queuedUpdatesCount > 0)
                    _buildInfoRow(
                      'Queued Updates',
                      '${statusStore.queuedUpdatesCount}',
                      Colors.blue,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDetails(BuildContext context) {
    return Observer(
      builder: (context) {
        final error = statusStore.lastError;
        if (error == null) return const SizedBox.shrink();

        return Card(
          color: Colors.red.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20.0,
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      'Error Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                _buildInfoRow(
                  'Error Type',
                  _getErrorTypeText(error.type),
                  Colors.red,
                ),
                _buildInfoRow(
                  'Message',
                  error.message,
                  Colors.red,
                ),
                _buildInfoRow(
                  'Time',
                  _formatDateTime(error.timestamp),
                ),
                _buildInfoRow(
                  'Recoverable',
                  error.isRecoverable ? 'Yes' : 'No',
                  error.isRecoverable ? Colors.orange : Colors.red,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueuedUpdatesSection(BuildContext context) {
    return Observer(
      builder: (context) => Card(
        color: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.queue,
                    color: Colors.blue.shade600,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    'Queued Updates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                '${statusStore.queuedUpdatesCount} updates are queued and will be processed when the connection is restored.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // TODO: Implement view queued updates
                    },
                    icon: const Icon(Icons.list, size: 18.0),
                    label: const Text('View Queue'),
                  ),
                  const SizedBox(width: 8.0),
                  TextButton.icon(
                    onPressed: () {
                      statusStore.clearQueuedUpdates();
                    },
                    icon: const Icon(Icons.clear, size: 18.0),
                    label: const Text('Clear Queue'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Observer(
      builder: (context) => Row(
        children: [
          if (statusStore.canRetry)
            ElevatedButton.icon(
              onPressed: () async {
                await statusStore.retryConnection();
              },
              icon: const Icon(Icons.refresh, size: 18.0),
              label: const Text('Retry Connection'),
            ),
          const SizedBox(width: 12.0),
          OutlinedButton.icon(
            onPressed: () {
              statusStore.clearError();
            },
            icon: const Icon(Icons.clear, size: 18.0),
            label: const Text('Clear Error'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              statusStore.toggleConnectionDetails();
            },
            child: Text(
              statusStore.showConnectionDetails 
                  ? 'Hide Details' 
                  : 'Show Details',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.0,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.0,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(WebSocketConnectionState state) {
    switch (state) {
      case WebSocketConnectionState.connected:
        return Colors.green;
      case WebSocketConnectionState.connecting:
        return Colors.blue;
      case WebSocketConnectionState.reconnecting:
        return Colors.orange;
      case WebSocketConnectionState.disconnected:
        return Colors.grey;
      case WebSocketConnectionState.error:
        return Colors.red;
    }
  }

  Color _getResponseTimeColor(Duration responseTime) {
    if (responseTime.inMilliseconds < 100) {
      return Colors.green;
    } else if (responseTime.inMilliseconds < 300) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getErrorTypeText(WebSocketErrorType type) {
    switch (type) {
      case WebSocketErrorType.authenticationFailed:
        return 'Authentication Failed';
      case WebSocketErrorType.connectionTimeout:
        return 'Connection Timeout';
      case WebSocketErrorType.networkError:
        return 'Network Error';
      case WebSocketErrorType.serverError:
        return 'Server Error';
      case WebSocketErrorType.invalidMessage:
        return 'Invalid Message';
      case WebSocketErrorType.subscriptionFailed:
        return 'Subscription Failed';
      case WebSocketErrorType.tokenExpired:
        return 'Token Expired';
      case WebSocketErrorType.tokenRefreshFailed:
        return 'Token Refresh Failed';
      case WebSocketErrorType.maxReconnectAttemptsExceeded:
        return 'Max Reconnect Attempts Exceeded';
      case WebSocketErrorType.heartbeatTimeout:
        return 'Heartbeat Timeout';
      case WebSocketErrorType.unexpectedDisconnection:
        return 'Unexpected Disconnection';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}