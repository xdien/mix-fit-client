import 'package:flutter/material.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';

/// Enum representing connection quality levels
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
  offline,
}

/// A widget that displays connection quality with signal strength bars
class WebSocketConnectionQualityWidget extends StatelessWidget {
  final WebSocketConnectionState connectionState;
  final ConnectionQuality quality;
  final int? reconnectAttempts;
  final Duration? lastResponseTime;
  final bool showQualityText;

  const WebSocketConnectionQualityWidget({
    Key? key,
    required this.connectionState,
    required this.quality,
    this.reconnectAttempts,
    this.lastResponseTime,
    this.showQualityText = false,
  }) : super(key: key);

  /// Factory constructor to determine quality based on connection state and metrics
  factory WebSocketConnectionQualityWidget.fromMetrics({
    Key? key,
    required WebSocketConnectionState connectionState,
    int reconnectAttempts = 0,
    Duration? lastResponseTime,
    bool showQualityText = false,
  }) {
    ConnectionQuality quality;
    
    switch (connectionState) {
      case WebSocketConnectionState.connected:
        if (lastResponseTime != null) {
          if (lastResponseTime.inMilliseconds < 100) {
            quality = ConnectionQuality.excellent;
          } else if (lastResponseTime.inMilliseconds < 300) {
            quality = ConnectionQuality.good;
          } else if (lastResponseTime.inMilliseconds < 1000) {
            quality = ConnectionQuality.fair;
          } else {
            quality = ConnectionQuality.poor;
          }
        } else if (reconnectAttempts == 0) {
          quality = ConnectionQuality.excellent;
        } else if (reconnectAttempts < 3) {
          quality = ConnectionQuality.good;
        } else {
          quality = ConnectionQuality.fair;
        }
        break;
      case WebSocketConnectionState.connecting:
      case WebSocketConnectionState.reconnecting:
        if (reconnectAttempts < 2) {
          quality = ConnectionQuality.good;
        } else if (reconnectAttempts < 5) {
          quality = ConnectionQuality.fair;
        } else {
          quality = ConnectionQuality.poor;
        }
        break;
      case WebSocketConnectionState.disconnected:
      case WebSocketConnectionState.error:
        quality = ConnectionQuality.offline;
        break;
    }

    return WebSocketConnectionQualityWidget(
      key: key,
      connectionState: connectionState,
      quality: quality,
      reconnectAttempts: reconnectAttempts,
      lastResponseTime: lastResponseTime,
      showQualityText: showQualityText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSignalBars(),
        if (showQualityText) ...[
          const SizedBox(width: 8.0),
          Text(
            _getQualityText(),
            style: TextStyle(
              fontSize: 12.0,
              color: _getQualityColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSignalBars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return Container(
          width: 3.0,
          height: 4.0 + (index * 3.0),
          margin: const EdgeInsets.only(right: 1.0),
          decoration: BoxDecoration(
            color: _getBarColor(index),
            borderRadius: BorderRadius.circular(1.0),
          ),
        );
      }),
    );
  }

  Color _getBarColor(int barIndex) {
    final isActive = _isBarActive(barIndex);
    
    if (!isActive) {
      return Colors.grey.shade300;
    }

    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return barIndex < 3 ? Colors.green : Colors.orange;
      case ConnectionQuality.fair:
        return barIndex < 2 ? Colors.orange : Colors.red;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.offline:
        return Colors.grey;
    }
  }

  bool _isBarActive(int barIndex) {
    switch (quality) {
      case ConnectionQuality.excellent:
        return true;
      case ConnectionQuality.good:
        return barIndex < 3;
      case ConnectionQuality.fair:
        return barIndex < 2;
      case ConnectionQuality.poor:
        return barIndex < 1;
      case ConnectionQuality.offline:
        return false;
    }
  }

  String _getQualityText() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 'Excellent';
      case ConnectionQuality.good:
        return 'Good';
      case ConnectionQuality.fair:
        return 'Fair';
      case ConnectionQuality.poor:
        return 'Poor';
      case ConnectionQuality.offline:
        return 'Offline';
    }
  }

  Color _getQualityColor() {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.green;
      case ConnectionQuality.fair:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
      case ConnectionQuality.offline:
        return Colors.grey;
    }
  }
}