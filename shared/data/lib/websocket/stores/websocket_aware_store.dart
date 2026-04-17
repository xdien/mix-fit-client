import 'package:mobx/mobx.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_message.dart';

/// Base class for MobX stores that need WebSocket integration
/// Provides common functionality for real-time data updates
abstract class WebSocketAwareStore {
  final IWebSocketService _webSocketService;
  final List<ReactionDisposer> _disposers = [];
  final Map<String, Function(dynamic)> _subscriptions = {};

  WebSocketAwareStore(this._webSocketService) {
    _setupWebSocketListeners();
  }

  /// Override this method to define which channels this store should subscribe to
  List<String> get subscribedChannels;

  /// Override this method to handle incoming WebSocket messages
  void handleWebSocketMessage(String channel, dynamic data);

  /// Override this method to handle connection state changes
  void onConnectionStateChanged(WebSocketConnectionState state) {
    // Default implementation - can be overridden by subclasses
  }

  void _setupWebSocketListeners() {
    // Listen to connection state changes
    final connectionDisposer = reaction(
      (_) => _webSocketService.connectionState,
      (Stream<WebSocketConnectionState> stateStream) {
        stateStream.listen((state) {
          onConnectionStateChanged(state);
          if (state == WebSocketConnectionState.connected) {
            _subscribeToChannels();
          }
        });
      },
    );
    _disposers.add(connectionDisposer);
  }

  void _subscribeToChannels() {
    for (final channel in subscribedChannels) {
      if (!_subscriptions.containsKey(channel)) {
        final callback = (dynamic data) => handleWebSocketMessage(channel, data);
        _subscriptions[channel] = callback;
        _webSocketService.subscribe(channel, callback);
      }
    }
  }

  /// Call this method when the store is no longer needed
  void dispose() {
    // Unsubscribe from all channels
    for (final channel in _subscriptions.keys) {
      _webSocketService.unsubscribe(channel);
    }
    _subscriptions.clear();

    // Dispose all reactions
    for (final disposer in _disposers) {
      disposer();
    }
    _disposers.clear();
  }

  /// Get current WebSocket connection state
  WebSocketConnectionState get connectionState => _webSocketService.currentState;

  /// Check if WebSocket is connected
  bool get isConnected => connectionState == WebSocketConnectionState.connected;

  /// Manually refresh data when connection is restored
  Future<void> refreshDataAfterReconnection() async {
    // Override in subclasses to implement specific refresh logic
  }
}