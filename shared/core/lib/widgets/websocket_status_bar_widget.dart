import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'websocket_connection_status_widget.dart';
import 'websocket_connection_quality_widget.dart';

/// A comprehensive status bar widget that shows WebSocket connection status,
/// quality indicators, and provides user interaction capabilities
class WebSocketStatusBarWidget extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final WebSocketError? lastError;
  final int reconnectAttempts;
  final Duration? lastResponseTime;
  final bool showDetails;
  final bool isMinimized;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const WebSocketStatusBarWidget({
    Key? key,
    required this.connectionState,
    this.lastError,
    this.reconnectAttempts = 0,
    this.lastResponseTime,
    this.showDetails = true,
    this.isMinimized = false,
    this.onTap,
    this.onRetry,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show the status bar if connected and no details requested
    if (connectionState == WebSocketConnectionState.connected && 
        !showDetails && 
        isMinimized) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Material(
        color: _getBackgroundColor(context),
        elevation: _shouldShowElevation() ? 2.0 : 0.0,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: isMinimized ? 8.0 : 12.0,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _getBorderColor(context),
                width: 0.5,
              ),
            ),
          ),
          child: isMinimized ? _buildMinimizedContent() : _buildFullContent(context),
        ),
      ),
    );
  }

  Widget _buildMinimizedContent() {
    return Row(
      children: [
        WebSocketConnectionStatusWidget(
          connectionState: connectionState,
          lastError: lastError,
          showText: false,
          isCompact: true,
        ),
        const SizedBox(width: 8.0),
        WebSocketConnectionQualityWidget.fromMetrics(
          connectionState: connectionState,
          reconnectAttempts: reconnectAttempts,
          lastResponseTime: lastResponseTime,
        ),
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Icon(
              Icons.expand_more,
              size: 20.0,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            WebSocketConnectionStatusWidget(
              connectionState: connectionState,
              lastError: lastError,
              showText: true,
              isCompact: false,
              onTap: onTap,
            ),
            const SizedBox(width: 12.0),
            WebSocketConnectionQualityWidget.fromMetrics(
              connectionState: connectionState,
              reconnectAttempts: reconnectAttempts,
              lastResponseTime: lastResponseTime,
              showQualityText: true,
            ),
            const Spacer(),
            _buildActionButtons(),
          ],
        ),
        if (_shouldShowDetails()) ...[
          const SizedBox(height: 8.0),
          _buildDetailsSection(context),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_shouldShowRetryButton() && onRetry != null)
          IconButton(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            iconSize: 20.0,
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(
              minWidth: 32.0,
              minHeight: 32.0,
            ),
            tooltip: 'Retry Connection',
          ),
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            iconSize: 20.0,
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(
              minWidth: 32.0,
              minHeight: 32.0,
            ),
            tooltip: 'Dismiss',
          ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = <String>[];
    
    if (reconnectAttempts > 0) {
      details.add('Reconnect attempts: $reconnectAttempts');
    }
    
    if (lastResponseTime != null) {
      details.add('Response time: ${lastResponseTime!.inMilliseconds}ms');
    }
    
    if (lastError != null) {
      details.add('Last error: ${_getErrorDescription(lastError!)}');
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: details.map((detail) => Padding(
          padding: const EdgeInsets.only(bottom: 2.0),
          child: Text(
            detail,
            style: TextStyle(
              fontSize: 12.0,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        )).toList(),
      ),
    );
  }

  bool _shouldShowDetails() {
    return showDetails && (
      reconnectAttempts > 0 ||
      lastResponseTime != null ||
      lastError != null
    );
  }

  bool _shouldShowRetryButton() {
    return connectionState == WebSocketConnectionState.error ||
           connectionState == WebSocketConnectionState.disconnected;
  }

  bool _shouldShowElevation() {
    return connectionState != WebSocketConnectionState.connected;
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return theme.colorScheme.surface;
      case WebSocketConnectionState.connecting:
        return Colors.blue.withOpacity(0.05);
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.withOpacity(0.05);
      case WebSocketConnectionState.disconnected:
        return Colors.grey.withOpacity(0.05);
      case WebSocketConnectionState.error:
        return Colors.red.withOpacity(0.05);
    }
  }

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        return theme.colorScheme.outline.withOpacity(0.2);
      case WebSocketConnectionState.connecting:
        return Colors.blue.withOpacity(0.3);
      case WebSocketConnectionState.reconnecting:
        return Colors.orange.withOpacity(0.3);
      case WebSocketConnectionState.disconnected:
        return Colors.grey.withOpacity(0.3);
      case WebSocketConnectionState.error:
        return Colors.red.withOpacity(0.3);
    }
  }

  String _getErrorDescription(WebSocketError error) {
    switch (error.type) {
      case WebSocketErrorType.authenticationFailed:
        return 'Authentication failed';
      case WebSocketErrorType.connectionTimeout:
        return 'Connection timeout';
      case WebSocketErrorType.networkError:
        return 'Network error';
      case WebSocketErrorType.serverError:
        return 'Server error';
      case WebSocketErrorType.tokenExpired:
        return 'Token expired';
      case WebSocketErrorType.maxReconnectAttemptsExceeded:
        return 'Max reconnect attempts exceeded';
      case WebSocketErrorType.heartbeatTimeout:
        return 'Heartbeat timeout';
      case WebSocketErrorType.unexpectedDisconnection:
        return 'Unexpected disconnection';
      default:
        return error.message;
    }
  }
}