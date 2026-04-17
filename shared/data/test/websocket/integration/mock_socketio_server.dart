import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:data/websocket/websocket.dart';

/// Mock Socket.IO server for testing various scenarios
class MockSocketIOServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final StreamController<MockServerEvent> _eventController = StreamController.broadcast();
  final Map<String, List<String>> _roomSubscriptions = {};
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
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.serverStarted(_port));
    }
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
    _roomSubscriptions.clear();

    await _server?.close();
    _server = null;
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.serverStopped());
    }
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
    final clientId = webSocket.hashCode.toString();
    
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.clientConnected(clientId));
    }

    webSocket.listen(
      (data) => _handleSocketIOMessage(webSocket, data),
      onDone: () => _handleDisconnection(webSocket),
      onError: (error) => _handleError(webSocket, error),
    );

    // Send Socket.IO handshake response
    await _sendSocketIOMessage(webSocket, {
      'type': 0, // CONNECT
      'data': {
        'sid': 'mock-session-$clientId',
        'upgrades': [],
        'pingInterval': 25000,
        'pingTimeout': 60000,
      },
    });

    // Auto-authenticate for testing (simulate successful auth)
    if (!shouldRejectAuth) {
      await Future.delayed(const Duration(milliseconds: 50));
      await _sendSocketIOMessage(webSocket, {
        'type': 3, // EVENT
        'data': ['authenticated', {
          'userId': 'user-$clientId',
          'status': 'success',
        }],
      });
      if (!_eventController.isClosed) {
        _eventController.add(MockServerEvent.authSuccess(clientId));
      }
    }
  }

  /// Handle Socket.IO messages
  void _handleSocketIOMessage(WebSocket webSocket, dynamic data) async {
    try {
      final message = jsonDecode(data as String) as List<dynamic>;
      final clientId = webSocket.hashCode.toString();
      
      if (message.isEmpty) return;
      
      final messageType = message[0] as int;
      final payload = message.length > 1 ? message[1] : null;
      
      if (!_eventController.isClosed) {
        _eventController.add(MockServerEvent.messageReceived(clientId, {
          'type': messageType,
          'payload': payload,
        }));
      }

      if (messageDelay > Duration.zero) {
        await Future.delayed(messageDelay);
      }

      switch (messageType) {
        case 1: // CONNECT
          await _handleSocketIOConnect(webSocket, payload);
          break;
        case 2: // DISCONNECT
          await _handleSocketIODisconnect(webSocket, payload);
          break;
        case 3: // EVENT
          await _handleSocketIOEvent(webSocket, payload);
          break;
        case 4: // ACK
          await _handleSocketIOAck(webSocket, payload);
          break;
        case 5: // CONNECT_ERROR
          await _handleSocketIOConnectError(webSocket, payload);
          break;
        case 6: // BINARY_EVENT
          await _handleSocketIOBinaryEvent(webSocket, payload);
          break;
        case 7: // BINARY_ACK
          await _handleSocketIOBinaryAck(webSocket, payload);
          break;
        case 8: // PING
          await _handleSocketIOPing(webSocket, payload);
          break;
        case 9: // PONG
          await _handleSocketIOPong(webSocket, payload);
          break;
        case 10: // UPGRADE
          await _handleSocketIOUpgrade(webSocket, payload);
          break;
        case 11: // NOOP
          await _handleSocketIONoop(webSocket, payload);
          break;
        default:
          await _sendSocketIOError(webSocket, 'Unknown message type: $messageType');
      }
    } catch (e) {
      await _sendSocketIOError(webSocket, 'Invalid message format: $e');
    }
  }

  /// Handle Socket.IO CONNECT
  Future<void> _handleSocketIOConnect(WebSocket webSocket, dynamic payload) async {
    final clientId = webSocket.hashCode.toString();
    
    // Send connection acknowledgment
    await _sendSocketIOMessage(webSocket, {
      'type': 1, // CONNECT
      'data': {
        'sid': 'mock-session-$clientId',
      },
    });
    
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.authSuccess(clientId));
    }
  }

  /// Handle Socket.IO DISCONNECT
  Future<void> _handleSocketIODisconnect(WebSocket webSocket, dynamic payload) async {
    final clientId = webSocket.hashCode.toString();
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.clientDisconnected(clientId));
    }
  }

  /// Handle Socket.IO EVENT
  Future<void> _handleSocketIOEvent(WebSocket webSocket, dynamic payload) async {
    final clientId = webSocket.hashCode.toString();
    
    if (payload is List && payload.isNotEmpty) {
      final eventName = payload[0] as String;
      final eventData = payload.length > 1 ? payload[1] : null;
      
      switch (eventName) {
        case 'authenticate':
          await _handleSocketIOAuth(webSocket, eventData);
          break;
        case 'join':
          await _handleSocketIOJoin(webSocket, eventData);
          break;
        case 'leave':
          await _handleSocketIOLeave(webSocket, eventData);
          break;
        case 'subscribe':
          await _handleSocketIOSubscribe(webSocket, eventData);
          break;
        case 'unsubscribe':
          await _handleSocketIOUnsubscribe(webSocket, eventData);
          break;
        case 'message':
          await _handleSocketIOMessageEvent(webSocket, eventData);
          break;
        default:
          // Echo the event back
          await _sendSocketIOMessage(webSocket, {
            'type': 3, // EVENT
            'data': [eventName, eventData],
          });
      }
    }
  }

  /// Handle Socket.IO authentication
  Future<void> _handleSocketIOAuth(WebSocket webSocket, dynamic data) async {
    final clientId = webSocket.hashCode.toString();
    final token = data is Map ? data['token'] as String? : null;

    if (shouldRejectAuth || token == null || token.isEmpty || token == 'invalid-token') {
      await _sendSocketIOMessage(webSocket, {
        'type': 3, // EVENT
        'data': ['auth_error', {
          'error': 'Authentication failed',
          'reason': 'Invalid or missing token',
        }],
      });
      if (!_eventController.isClosed) {
        _eventController.add(MockServerEvent.authFailed(clientId, 'Invalid token'));
      }
      return;
    }

    await _sendSocketIOMessage(webSocket, {
      'type': 3, // EVENT
      'data': ['authenticated', {
        'userId': 'user-$clientId',
        'status': 'success',
      }],
    });
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.authSuccess(clientId));
    }
  }

  /// Handle Socket.IO join room
  Future<void> _handleSocketIOJoin(WebSocket webSocket, dynamic data) async {
    final clientId = webSocket.hashCode.toString();
    final room = data is Map ? data['room'] as String? : data as String?;

    if (room == null || room.isEmpty) {
      await _sendSocketIOError(webSocket, 'Room name is required');
      return;
    }

    _roomSubscriptions.putIfAbsent(room, () => []);
    if (!_roomSubscriptions[room]!.contains(clientId)) {
      _roomSubscriptions[room]!.add(clientId);
    }

    await _sendSocketIOMessage(webSocket, {
      'type': 3, // EVENT
      'data': ['joined', {
        'room': room,
        'status': 'success',
      }],
    });
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.channelSubscribed(clientId, room));
    }
  }

  /// Handle Socket.IO leave room
  Future<void> _handleSocketIOLeave(webSocket, dynamic data) async {
    final clientId = webSocket.hashCode.toString();
    final room = data is Map ? data['room'] as String? : data as String?;

    if (room == null || room.isEmpty) {
      await _sendSocketIOError(webSocket, 'Room name is required');
      return;
    }

    _roomSubscriptions[room]?.remove(clientId);
    if (_roomSubscriptions[room]?.isEmpty == true) {
      _roomSubscriptions.remove(room);
    }

    await _sendSocketIOMessage(webSocket, {
      'type': 3, // EVENT
      'data': ['left', {
        'room': room,
        'status': 'success',
      }],
    });
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.channelUnsubscribed(clientId, room));
    }
  }

  /// Handle Socket.IO subscribe event
  Future<void> _handleSocketIOSubscribe(WebSocket webSocket, dynamic data) async {
    final clientId = webSocket.hashCode.toString();
    final channel = data is Map ? data['channel'] as String? : null;
    
    if (channel != null) {
      // Add client to channel subscription
      _roomSubscriptions.putIfAbsent(channel, () => <String>[]);
      if (!_roomSubscriptions[channel]!.contains(clientId)) {
        _roomSubscriptions[channel]!.add(clientId);
      }
      
      // Send subscription confirmation
      await _sendSocketIOMessage(webSocket, {
        'type': 3, // EVENT
        'data': ['subscribed', {
          'channel': channel,
          'status': 'success',
        }],
      });
      
      if (!_eventController.isClosed) {
        _eventController.add(MockServerEvent.channelSubscribed(clientId, channel));
      }
    }
  }

  /// Handle Socket.IO unsubscribe event
  Future<void> _handleSocketIOUnsubscribe(WebSocket webSocket, dynamic data) async {
    final clientId = webSocket.hashCode.toString();
    final channel = data is Map ? data['channel'] as String? : null;
    
    if (channel != null) {
      // Remove client from channel subscription
      _roomSubscriptions[channel]?.remove(clientId);
      
      // Send unsubscription confirmation
      await _sendSocketIOMessage(webSocket, {
        'type': 3, // EVENT
        'data': ['unsubscribed', {
          'channel': channel,
          'status': 'success',
        }],
      });
      
      if (!_eventController.isClosed) {
        _eventController.add(MockServerEvent.channelUnsubscribed(clientId, channel));
      }
    }
  }

  /// Handle Socket.IO message event
  Future<void> _handleSocketIOMessageEvent(WebSocket webSocket, dynamic data) async {
    // Echo the message back
    await _sendSocketIOMessage(webSocket, {
      'type': 3, // EVENT
      'data': ['message', data],
    });
  }

  /// Handle other Socket.IO message types
  Future<void> _handleSocketIOAck(WebSocket webSocket, dynamic payload) async {
    // Handle acknowledgment
  }

  Future<void> _handleSocketIOConnectError(WebSocket webSocket, dynamic payload) async {
    // Handle connection error
  }

  Future<void> _handleSocketIOBinaryEvent(WebSocket webSocket, dynamic payload) async {
    // Handle binary event
  }

  Future<void> _handleSocketIOBinaryAck(WebSocket webSocket, dynamic payload) async {
    // Handle binary acknowledgment
  }

  Future<void> _handleSocketIOPing(WebSocket webSocket, dynamic payload) async {
    await _sendSocketIOMessage(webSocket, {
      'type': 9, // PONG
    });
  }

  Future<void> _handleSocketIOPong(WebSocket webSocket, dynamic payload) async {
    // Handle pong
  }

  Future<void> _handleSocketIOUpgrade(WebSocket webSocket, dynamic payload) async {
    // Handle upgrade
  }

  Future<void> _handleSocketIONoop(WebSocket webSocket, dynamic payload) async {
    // Handle noop
  }

  /// Handle client disconnection
  void _handleDisconnection(WebSocket webSocket) {
    final clientId = webSocket.hashCode.toString();
    _clients.remove(webSocket);
    
    // Remove from all room subscriptions
    for (final room in _roomSubscriptions.keys.toList()) {
      _roomSubscriptions[room]?.remove(clientId);
      if (_roomSubscriptions[room]?.isEmpty == true) {
        _roomSubscriptions.remove(room);
      }
    }

    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.clientDisconnected(clientId));
    }
  }

  /// Handle connection errors
  void _handleError(WebSocket webSocket, dynamic error) {
    final clientId = webSocket.hashCode.toString();
    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.connectionError(clientId, error.toString()));
    }
  }

  /// Send Socket.IO message to specific client
  Future<void> _sendSocketIOMessage(WebSocket webSocket, Map<String, dynamic> message) async {
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
      final socketIOMessage = [messageData['type'], messageData['data']];
      webSocket.add(jsonEncode(socketIOMessage));
    } catch (e) {
      // Client might be disconnected
    }
  }

  /// Send Socket.IO error message to client
  Future<void> _sendSocketIOError(WebSocket webSocket, String error) async {
    await _sendSocketIOMessage(webSocket, {
      'type': 3, // EVENT
      'data': ['error', {
        'error': error,
        'timestamp': DateTime.now().toIso8601String(),
      }],
    });
  }

  /// Broadcast message to all clients in a room
  Future<void> broadcastToRoom(String room, Map<String, dynamic> message) async {
    final subscribers = _roomSubscriptions[room] ?? [];
    final clients = _clients.where((client) => 
        subscribers.contains(client.hashCode.toString())).toList();

    for (final client in clients) {
      await _sendSocketIOMessage(client, {
        'type': 3, // EVENT
        'data': [room, {
          ...message,
          'room': room,
          'timestamp': DateTime.now().toIso8601String(),
        }],
      });
    }

    if (!_eventController.isClosed) {
      _eventController.add(MockServerEvent.messageBroadcast(room, message, subscribers.length));
    }
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
      'roomCount': _roomSubscriptions.length,
      'rooms': _roomSubscriptions.keys.toList(),
      'subscriptions': Map.fromEntries(
        _roomSubscriptions.entries.map((e) => MapEntry(e.key, e.value.length))
      ),
    };
  }

  void dispose() {
    if (!_eventController.isClosed) {
      _eventController.close();
    }
  }
}

/// Events emitted by the mock server (reusing the same event class)
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

  factory MockServerEvent.messageBroadcast(String room, Map<String, dynamic> message, int recipientCount) =>
      MockServerEvent._('message_broadcast', {
        'room': room,
        'message': message,
        'recipientCount': recipientCount,
      });

  factory MockServerEvent.authSuccess(String clientId) =>
      MockServerEvent._('auth_success', {'clientId': clientId});

  factory MockServerEvent.authFailed(String clientId, String reason) =>
      MockServerEvent._('auth_failed', {'clientId': clientId, 'reason': reason});

  factory MockServerEvent.channelSubscribed(String clientId, String room) =>
      MockServerEvent._('channel_subscribed', {'clientId': clientId, 'room': room});

  factory MockServerEvent.channelUnsubscribed(String clientId, String room) =>
      MockServerEvent._('channel_unsubscribed', {'clientId': clientId, 'room': room});

  factory MockServerEvent.connectionError(String clientId, String error) =>
      MockServerEvent._('connection_error', {'clientId': clientId, 'error': error});

  @override
  String toString() => 'MockServerEvent(type: $type, data: $data, timestamp: $timestamp)';
} 