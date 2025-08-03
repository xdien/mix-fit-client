import 'package:mobx/mobx.dart';
import 'package:data/websocket/models/websocket_connection_state.dart';
import 'package:data/websocket/interfaces/i_websocket_service.dart';
import 'dart:async';

part 'websocket_status_store.g.dart';

/// MobX store for managing WebSocket connection status UI state
class WebSocketStatusStore = _WebSocketStatusStore with _$WebSocketStatusStore;

abstract class _WebSocketStatusStore with Store {
  final IWebSocketService _webSocketService;
  StreamSubscription<WebSocketConnectionState>? _connectionSubscription;
  StreamSubscription<WebSocketError>? _errorSubscription;

  _WebSocketStatusStore(this._webSocketService) {
    _initializeSubscriptions();
  }

  @observable
  WebSocketConnectionState connectionState = WebSocketConnectionState.disconnected;

  @observable
  WebSocketError? lastError;

  @observable
  int reconnectAttempts = 0;

  @observable
  Duration? lastResponseTime;

  @observable
  DateTime? lastConnectedTime;

  @observable
  int queuedUpdatesCount = 0;

  @observable
  bool isStatusBarVisible = true;

  @observable
  bool isStatusBarMinimized = false;

  @observable
  bool showConnectionDetailsFlag = false;

  @computed
  bool get isConnected => connectionState == WebSocketConnectionState.connected;

  @computed
  bool get isConnecting => 
      connectionState == WebSocketConnectionState.connecting ||
      connectionState == WebSocketConnectionState.reconnecting;

  @computed
  bool get isOffline => 
      connectionState == WebSocketConnectionState.disconnected ||
      connectionState == WebSocketConnectionState.error;

  @computed
  bool get hasError => lastError != null;

  @computed
  bool get canRetry => 
      connectionState == WebSocketConnectionState.error ||
      connectionState == WebSocketConnectionState.disconnected;

  @computed
  String get statusText {
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
        return 'Connection Error';
    }
  }

  @computed
  bool get shouldShowOfflineMode => 
      isOffline && !isConnecting && isStatusBarVisible;

  @computed
  bool get showConnectionDetails => showConnectionDetailsFlag;

  void _initializeSubscriptions() {
    // Subscribe to connection state changes
    _connectionSubscription = _webSocketService.connectionState.listen((state) {
      _updateConnectionState(state);
    });

    // Subscribe to error events if the service supports it
    // Note: This would need to be implemented when the service supports error streams

    // Initialize with current state
    connectionState = _webSocketService.currentState;
  }

  @action
  void _updateConnectionState(WebSocketConnectionState newState) {
    final previousState = connectionState;
    connectionState = newState;

    // Track connection time
    if (newState == WebSocketConnectionState.connected) {
      lastConnectedTime = DateTime.now();
      reconnectAttempts = 0;
      lastError = null;
    }

    // Update reconnect attempts
    if (newState == WebSocketConnectionState.reconnecting) {
      reconnectAttempts++;
    }

    // Auto-minimize status bar when connected
    if (newState == WebSocketConnectionState.connected && 
        previousState != WebSocketConnectionState.connected) {
      Timer(const Duration(seconds: 3), () {
        if (connectionState == WebSocketConnectionState.connected) {
          minimizeStatusBar();
        }
      });
    }

    // Show status bar when connection issues occur
    if (newState != WebSocketConnectionState.connected) {
      showStatusBar();
    }
  }

  @action
  void _updateError(WebSocketError error) {
    lastError = error;
    
    // Update reconnect attempts from error
    if (error.attemptNumber != null) {
      reconnectAttempts = error.attemptNumber!;
    }
  }

  @action
  void updateLastResponseTime(Duration responseTime) {
    lastResponseTime = responseTime;
  }

  @action
  void updateQueuedUpdatesCount(int count) {
    queuedUpdatesCount = count;
  }

  @action
  void showStatusBar() {
    isStatusBarVisible = true;
    isStatusBarMinimized = false;
  }

  @action
  void hideStatusBar() {
    isStatusBarVisible = false;
  }

  @action
  void minimizeStatusBar() {
    isStatusBarMinimized = true;
  }

  @action
  void expandStatusBar() {
    isStatusBarMinimized = false;
  }

  @action
  void toggleStatusBarMinimized() {
    isStatusBarMinimized = !isStatusBarMinimized;
  }

  @action
  void toggleConnectionDetails() {
    showConnectionDetailsFlag = !showConnectionDetailsFlag;
  }

  @action
  void showConnectionDetailsAction() {
    showConnectionDetailsFlag = true;
  }

  @action
  void hideConnectionDetails() {
    showConnectionDetailsFlag = false;
  }

  @action
  Future<void> retryConnection() async {
    try {
      await _webSocketService.connect();
    } catch (error) {
      // Error will be handled by the error stream subscription
    }
  }

  @action
  void clearError() {
    lastError = null;
  }

  @action
  void clearQueuedUpdates() {
    queuedUpdatesCount = 0;
  }

  @action
  void resetReconnectAttempts() {
    reconnectAttempts = 0;
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
  }
}