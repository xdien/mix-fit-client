import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:data/websocket/websocket.dart';

/// Mock WebSocket server for testing various scenarios
class MockWebSocketServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final StreamController<MockServerEvent> _eventController = StreamController.broadcast();
  final Map<String, List<String>> _channelSubscriptions = {};
  bool _isRunning = false;
  int _port = 0;
  
  // Configuration
  Duration connectionDelay = Duration.zero;
  bool shouldRejectAuth = false;
  bool shouldDropConnections = false;
  int maxConnections = 100;
  Duration messageDelay = Duration.zero;
  bool shouldCorruptMessages = false;
  double messageDropRate = 0.0;
  
  Stream<MockServerEvent> get events => _eventController.stream;
  bool get isRunning => _isRunning;
  int get port => _port;
  int get clientCount => _clients.length;
  List<String> get connectedClients => _clients.map((c) => c.hashCode.toString()).toList();

  /// Start the mock server on the specified port
  Future<void> start([int port = 0]) async {
    if (_isRunning) {
      throw StateError('Server is already running');
    }

    _server = await HttpServer.bind('localhost', port);
    _port = _server!.port;
    _isRunning = true;

    _server!.transform(WebSocketTransformer()).listen(_handleConnection);
    _eventController.add(MockServerEvent.serverStarted(_port));
  }

  /// Stop the mock server
  Future<void> stop() async {
    if (!_isRunning) return;

    _isRunning = false;
    
    // Close all client connections
    for (final client in List.from(_clients)) {
      await client.close();
    }
    _clients.clear();
    _channelSubscriptions.clear();

    await _server?.close();
    _server = null;
    _eventController.add(MockServerEvent.serverStopped());
  }

  /// Handle new WebSocket connections
  void _handleConnection(WebSocket webSocket) async {
    if (connectionDelay > Duration.zero) {
      await Future.delayed(connectionDelay);
    }

    if (_clients.length >= maxConnections) {
      await webSocket.close(WebSocketStatus.goingAway, 'Server full');
      return;
    }

    _clients.add(webSocket);
    _eventController.add(MockServerEvent.clientConnected(webSocket.hashCode.toString()));

    webSocket.listen(
      (data) => _handleMessage(webSocket, data),
      onDone: () => _handleDisconnection(webSocket),
      onError: (error) => _handleError(webSocket, error),
    );

    // Send connection acknowledgment
    await _sendToClient(webSocket, {
      'type': 'connection',
      'status': 'connected',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle incoming messages from clients
  void _handleMessage(WebSocket webSocket, dynamic data) async {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final clientId = webSocket.hashCode.toString();
      
      _eventController.add(MockServerEvent.messageReceived(clientId, message));

      if (messageDelay > Duration.zero) {
        await Future.delayed(messageDelay);
      }

      switch (message['type']) {
        case 'auth':
          await _handleAuth(webSocket, message);
          break;
        case 'subscribe':
          await _handleSubscribe(webSocket, message);
          break;
        case 'unsubscribe':
          await _handleUnsubscribe(webSocket, message);
          break;
        case 'ping':
          await _handlePing(webSocket, message);
          break;
        default:
          await _sendError(webSocket, 'Unknown message type: ${message['type']}');
      }
    } catch (e) {
      await _sendError(webSocket, 'Invalid message format: $e');
    }
  }

  /// Handle authentication
  Future<void> _handleAuth(WebSocket webSocket, Map<String, dynamic> message) async {
    final token = message['token'] as String?;
    final clientId = webSocket.hashCode.toString();

    if (shouldRejectAuth || token == null || token.isEmpty) {
      await _sendToClient(webSocket, {
        'type': 'auth',
        'status': 'failed',
        'error': 'Invalid or missing token',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _eventController.add(MockServerEvent.authFailed(clientId, 'Invalid token'));
      return;
    }

    // Simulate token validation
    if (token == 'invalid-token') {
      await _sendToClient(webSocket, {
        'type': 'auth',
        'status': 'failed',
        'error': 'Token validation failed',
        'timestamp': DateTime.now().toIso8601String(),
      });
      _eventController.add(MockServerEvent.authFailed(clientId, 'Token validation failed'));
      return;
    }

    await _sendToClient(webSocket, {
      'type': 'auth',
      'status': 'success',
      'userId': 'user-${clientId}',
      'timestamp': DateTime.now().toIso8601String(),
    });
    _eventController.add(MockServerEvent.authSuccess(clientId));
  }

  /// Handle channel subscription
  Future<void> _handleSubscribe(WebSocket webSocket, Map<String, dynamic> message) async {
    final channel = message['channel'] as String?;
    final clientId = webSocket.hashCode.toString();

    if (channel == null || channel.isEmpty) {
      await _sendError(webSocket, 'Channel name is required');
      return;
    }

    _channelSubscriptions.putIfAbsent(channel, () => []);
    if (!_channelSubscriptions[channel]!.contains(clientId)) {
      _channelSubscriptions[channel]!.add(clientId);
    }

    await _sendToClient(webSocket, {
      'type': 'subscribe',
      'status': 'success',
      'channel': channel,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _eventController.add(MockServerEvent.channelSubscribed(clientId, channel));
  }

  /// Handle channel unsubscription
  Future<void> _handleUnsubscribe(WebSocket webSocket, Map<String, dynamic> message) async {
    final channel = message['channel'] as String?;
    final clientId = webSocket.hashCode.toString();

    if (channel == null || channel.isEmpty) {
      await _sendError(webSocket, 'Channel name is required');
      return;
    }

    _channelSubscriptions[channel]?.remove(clientId);
    if (_channelSubscriptions[channel]?.isEmpty == true) {
      _channelSubscriptions.remove(channel);
    }

    await _sendToClient(webSocket, {
      'type': 'unsubscribe',
      'status': 'success',
      'channel': channel,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _eventController.add(MockServerEvent.channelUnsubscribed(clientId, channel));
  }

  /// Handle ping messages
  Future<void> _handlePing(WebSocket webSocket, Map<String, dynamic> message) async {
    await _sendToClient(webSocket, {
      'type': 'pong',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle client disconnection
  void _handleDisconnection(WebSocket webSocket) {
    final clientId = webSocket.hashCode.toString();
    _clients.remove(webSocket);
    
    // Remove from all channel subscriptions
    for (final channel in _channelSubscriptions.keys.toList()) {
      _channelSubscriptions[channel]?.remove(clientId);
      if (_channelSubscriptions[channel]?.isEmpty == true) {
        _channelSubscriptions.remove(channel);
      }
    }

    _eventController.add(MockServerEvent.clientDisconnected(clientId));
  }

  /// Handle connection errors
  void _handleError(WebSocket webSocket, dynamic error) {
    final clientId = webSocket.hashCode.toString();
    _eventController.add(MockServerEvent.connectionError(clientId, error.toString()));
  }

  /// Send message to specific client
  Future<void> _sendToClient(WebSocket webSocket, Map<String, dynamic> message) async {
    if (shouldDropConnections) {
      await webSocket.close();
      return;
    }

    if (messageDropRate > 0 && (DateTime.now().millisecondsSinceEpoch % 100) < (messageDropRate * 100)) {
      return; // Drop message
    }

    var messageData = message;
    if (shouldCorruptMessages) {
      messageData = {...message, 'corrupted': true};
    }

    try {
      webSocket.add(jsonEncode(messageData));
    } catch (e) {
      // Client might be disconnected
    }
  }

  /// Send error message to client
  Future<void> _sendError(WebSocket webSocket, String error) async {
    await _sendToClient(webSocket, {
      'type': 'error',
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Broadcast message to all clients in a channel
  Future<void> broadcastToChannel(String channel, Map<String, dynamic> message) async {
    final subscribers = _channelSubscriptions[channel] ?? [];
    final clients = _clients.where((client) => 
        subscribers.contains(client.hashCode.toString())).toList();

    for (final client in clients) {
      await _sendToClient(client, {
        ...message,
        'channel': channel,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    _eventController.add(MockServerEvent.messageBroadcast(channel, message, subscribers.length));
  }

  /// Simulate various server scenarios
  void simulateServerOverload() {
    maxConnections = 1;
    connectionDelay = const Duration(seconds: 5);
    messageDelay = const Duration(seconds: 2);
  }

  void simulateNetworkIssues() {
    messageDropRate = 0.3;
    shouldCorruptMessages = true;
    connectionDelay = const Duration(seconds: 1);
  }

  void simulateAuthFailure() {
    shouldRejectAuth = true;
  }

  void simulateConnectionDrops() {
    shouldDropConnections = true;
  }

  void resetToNormal() {
    maxConnections = 100;
    connectionDelay = Duration.zero;
    messageDelay = Duration.zero;
    messageDropRate = 0.0;
    shouldCorruptMessages = false;
    shouldRejectAuth = false;
    shouldDropConnections = false;
  }

  /// Get server statistics
  Map<String, dynamic> getStats() {
    return {
      'isRunning': _isRunning,
      'port': _port,
      'clientCount': _clients.length,
      'channelCount': _channelSubscriptions.length,
      'channels': _channelSubscriptions.keys.toList(),
      'subscriptions': Map.fromEntries(
        _channelSubscriptions.entries.map((e) => MapEntry(e.key, e.value.length))
      ),
    };
  }

  void dispose() {
    _eventController.close();
  }
}

/// Events emitted by the mock server
class MockServerEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  MockServerEvent._(this.type, this.data) : timestamp = DateTime.now();

  factory MockServerEvent.serverStarted(int port) =>
      MockServerEvent._('server_started', {'port': port});

  factory MockServerEvent.serverStopped() =>
      MockServerEvent._('server_stopped', {});

  factory MockServerEvent.clientConnected(String clientId) =>
      MockServerEvent._('client_connected', {'clientId': clientId});

  factory MockServerEvent.clientDisconnected(String clientId) =>
      MockServerEvent._('client_disconnected', {'clientId': clientId});

  factory MockServerEvent.messageReceived(String clientId, Map<String, dynamic> message) =>
      MockServerEvent._('message_received', {'clientId': clientId, 'message': message});

  factory MockServerEvent.messageBroadcast(String channel, Map<String, dynamic> message, int recipientCount) =>
      MockServerEvent._('message_broadcast', {
        'channel': channel,
        'message': message,
        'recipientCount': recipientCount,
      });

  factory MockServerEvent.authSuccess(String clientId) =>
      MockServerEvent._('auth_success', {'clientId': clientId});

  factory MockServerEvent.authFailed(String clientId, String reason) =>
      MockServerEvent._('auth_failed', {'clientId': clientId, 'reason': reason});

  factory MockServerEvent.channelSubscribed(String clientId, String channel) =>
      MockServerEvent._('channel_subscribed', {'clientId': clientId, 'channel': channel});

  factory MockServerEvent.channelUnsubscribed(String clientId, String channel) =>
      MockServerEvent._('channel_unsubscribed', {'clientId': clientId, 'channel': channel});

  factory MockServerEvent.connectionError(String clientId, String error) =>
      MockServerEvent._('connection_error', {'clientId': clientId, 'error': error});

  @override
  String toString() => 'MockServerEvent(type: $type, data: $data, timestamp: $timestamp)';
}