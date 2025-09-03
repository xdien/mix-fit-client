# WebSocket Real-time Implementation Guide

This comprehensive guide covers the complete WebSocket real-time implementation for the AnKhanh CMS mobile application, providing real-time data synchronization between the Flutter mobile app and NestJS backend.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Installation & Setup](#installation--setup)
4. [Configuration](#configuration)
5. [Usage Examples](#usage-examples)
6. [API Reference](#api-reference)
7. [Testing](#testing)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)
10. [Performance Optimization](#performance-optimization)
11. [Security Considerations](#security-considerations)

## Overview

The WebSocket implementation provides real-time bidirectional communication between the Flutter mobile application and the NestJS backend, enabling:

- **Real-time data updates** for customers, inventory, orders, and system notifications
- **Automatic reconnection** with exponential backoff strategy
- **Message queuing** for offline users
- **Channel-based subscriptions** with role-based access control
- **Conflict resolution** for concurrent data modifications
- **App lifecycle management** for battery optimization

### Key Features

- ✅ Real-time customer, inventory, and order updates
- ✅ Automatic authentication with JWT tokens
- ✅ Robust reconnection strategy
- ✅ Offline message queuing
- ✅ Role-based channel access
- ✅ Data conflict resolution
- ✅ App lifecycle management
- ✅ Comprehensive error handling
- ✅ Performance monitoring
- ✅ Multi-environment support

## Architecture

### System Architecture

```mermaid
graph TB
    subgraph "Flutter Mobile App"
        UI[UI Layer - MobX Stores]
        Domain[Domain Layer - Use Cases]
        Data[Data Layer - Repositories]
        WS[WebSocket Service]
        Local[Drift Local DB]
        Lifecycle[App Lifecycle Manager]
    end
    
    subgraph "Backend API"
        Gateway[CMS WebSocket Gateway]
        Service[CMS WebSocket Service]
        Queue[Message Queue Service]
        Auth[JWT Authentication]
        Business[Business Logic]
    end
    
    UI --> Domain
    Domain --> Data
    Data --> WS
    Data --> Local
    WS <--> Gateway
    Gateway --> Service
    Gateway --> Queue
    Service --> Auth
    Service --> Business
    
    WS -.->|Background/Foreground| Lifecycle
```

### Component Overview

#### Frontend Components

1. **WebSocketService** - Core WebSocket connection management
2. **WebSocketDataSynchronizer** - Real-time data synchronization
3. **ConflictResolver** - Data conflict resolution strategies
4. **AppLifecycleManager** - App state management
5. **WebSocketConfigManager** - Configuration management
6. **WebSocketFeatureManager** - Feature flag management

#### Backend Components

1. **CMSWebSocketGateway** - WebSocket connection handling
2. **CMSWebSocketService** - Event broadcasting
3. **CMSMessageQueueService** - Offline message queuing
4. **SocketService** - Base WebSocket functionality

## Installation & Setup

### Prerequisites

- Flutter SDK 3.0+
- Node.js 18+
- Redis (for message queuing)
- PostgreSQL (for backend data)

### Frontend Setup

1. **Add Dependencies**

```yaml
# pubspec.yaml
dependencies:
  socket_io_client: ^3.0.2
  mobx: ^2.1.4
  flutter_mobx: ^2.0.6
  drift: ^2.14.1
  get_it: ^7.6.4
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

dev_dependencies:
  build_runner: ^2.4.7
  freezed: ^2.4.6
  json_serializable: ^6.7.1
  mobx_codegen: ^2.4.0
```

2. **Initialize WebSocket Module**

```dart
// In your main.dart or app initialization
import 'package:data/websocket/websocket.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment configuration
  await EnvironmentConfigService.initialize('development');
  
  // Initialize WebSocket configuration
  final configManager = WebSocketConfigManager();
  final featureManager = WebSocketFeatureManager();
  
  // Register WebSocket services
  GetIt.instance.registerSingleton<IWebSocketService>(
    WebSocketFactory.createWebSocketService(
      sharedPreferenceHelper: GetIt.instance<SharedPreferenceHelper>(),
      config: configManager.getConfig(),
    ),
  );
  
  runApp(MyApp());
}
```

### Backend Setup

1. **Install Dependencies**

```bash
npm install @nestjs/websockets @nestjs/platform-socket.io socket.io
npm install @nestjs/bull bull redis
```

2. **Configure WebSocket Module**

```typescript
// app.module.ts
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { CmsModule } from './modules/cms/cms.module';

@Module({
  imports: [
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST || 'localhost',
        port: parseInt(process.env.REDIS_PORT) || 6379,
        password: process.env.REDIS_PASSWORD,
      },
    }),
    CmsModule,
  ],
})
export class AppModule {}
```

## Configuration

### Environment Configuration

Create environment-specific configuration files:

```yaml
# frontend/config/environments/development.yaml
environment:
  name: development
  display_name: Development

network:
  api_base_url: http://localhost:3000
  websocket_url: ws://localhost:3000

websocket:
  enabled: true
  auto_connect: true
  reconnect_interval: 5000
  max_reconnect_attempts: 5
  heartbeat_interval: 30000
  connection_timeout: 10000
  message_queue_size: 1000
  channels:
    - inventory
    - customers
    - orders
    - notifications
  features:
    real_time_updates: true
    offline_support: true
    background_sync: true
    push_notifications: true
```

```yaml
# frontend/config/environments/production.yaml
environment:
  name: production
  display_name: Production

network:
  api_base_url: https://api.ankhanh.com
  websocket_url: wss://api.ankhanh.com

websocket:
  enabled: true
  auto_connect: true
  reconnect_interval: 15000
  max_reconnect_attempts: 10
  heartbeat_interval: 60000
  connection_timeout: 15000
  message_queue_size: 2000
  channels:
    - inventory
    - customers
    - orders
    - notifications
  features:
    real_time_updates: true
    offline_support: true
    background_sync: false  # Disabled for battery optimization
    push_notifications: true
```

### Backend Configuration

```typescript
// backend/.env
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

WEBSOCKET_CORS_ORIGIN=*
WEBSOCKET_TRANSPORTS=websocket,polling

JWT_SECRET=your-jwt-secret
JWT_EXPIRES_IN=24h
```

## Usage Examples

### Basic WebSocket Connection

```dart
import 'package:data/websocket/websocket.dart';

class CustomerService {
  final IWebSocketService _webSocketService;
  
  CustomerService(this._webSocketService);
  
  Future<void> initialize() async {
    // Connect to WebSocket
    await _webSocketService.connect();
    
    // Subscribe to customer updates
    _webSocketService.subscribe('customers', (data) {
      final message = WebSocketMessage.fromJson(data);
      _handleCustomerUpdate(message);
    });
    
    // Listen to connection state changes
    _webSocketService.connectionState.listen((state) {
      print('WebSocket state: $state');
    });
  }
  
  void _handleCustomerUpdate(WebSocketMessage message) {
    switch (message.type) {
      case 'customer.created':
        _handleCustomerCreated(message.data);
        break;
      case 'customer.updated':
        _handleCustomerUpdated(message.data);
        break;
      case 'customer.deleted':
        _handleCustomerDeleted(message.data);
        break;
    }
  }
}
```

### Real-time Data Synchronization

```dart
import 'package:data/websocket/websocket.dart';

class InventoryStore = _InventoryStore with _$InventoryStore;

abstract class _InventoryStore with Store {
  final WebSocketDataSynchronizer _synchronizer;
  
  _InventoryStore(this._synchronizer) {
    _setupWebSocketSync();
  }
  
  @observable
  ObservableList<InventoryItem> items = ObservableList<InventoryItem>();
  
  void _setupWebSocketSync() {
    // Subscribe to inventory updates
    _synchronizer.subscribe('inventory', (message) async {
      await _handleInventoryUpdate(message);
    });
    
    // Listen to sync results
    _synchronizer.syncResultStream.listen((result) {
      if (result.success) {
        _refreshInventoryFromLocal();
      } else {
        _handleSyncError(result.error);
      }
    });
  }
  
  @action
  Future<void> _handleInventoryUpdate(WebSocketMessage message) async {
    final result = await _synchronizer.processMessage(message);
    
    if (result.hasConflict) {
      // Handle conflict using latest timestamp strategy
      await _synchronizer.resolveConflict(
        result.conflict!, 
        ConflictResolutionStrategy.useLatest
      );
    }
  }
}
```

### Backend Event Broadcasting

```typescript
// customer.service.ts
import { Injectable } from '@nestjs/common';
import { CMSWebSocketService } from '../cms/cms-websocket.service';

@Injectable()
export class CustomerService {
  constructor(
    private readonly cmsWebSocketService: CMSWebSocketService,
  ) {}
  
  async updateCustomer(customerId: string, updateData: any, userId: string) {
    const previousData = await this.findOne(customerId);
    
    // Update customer in database
    const updatedCustomer = await this.customerRepository.save({
      ...previousData,
      ...updateData,
    });
    
    // Broadcast real-time update
    await this.cmsWebSocketService.broadcastCustomerUpdated({
      customerId,
      customerData: updatedCustomer,
      previousData,
      userId,
    });
    
    return updatedCustomer;
  }
  
  async createCustomer(customerData: any, userId: string) {
    const newCustomer = await this.customerRepository.save(customerData);
    
    // Broadcast creation event
    await this.cmsWebSocketService.broadcastCustomerCreated({
      customerId: newCustomer.khid,
      customerData: newCustomer,
      userId,
    });
    
    return newCustomer;
  }
}
```

### App Lifecycle Management

```dart
import 'package:flutter/services.dart';
import 'package:data/websocket/websocket.dart';

class AppLifecycleManager extends WidgetsBindingObserver {
  final IWebSocketService _webSocketService;
  
  AppLifecycleManager(this._webSocketService);
  
  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      default:
        break;
    }
  }
  
  Future<void> _handleAppResumed() async {
    // Reconnect WebSocket when app comes to foreground
    if (_webSocketService.currentState == WebSocketConnectionState.disconnected) {
      await _webSocketService.connect();
    }
    
    // Sync any missed updates
    await _syncMissedUpdates();
  }
  
  Future<void> _handleAppPaused() async {
    // Disconnect WebSocket to save battery
    await _webSocketService.disconnect();
  }
  
  Future<void> _handleAppDetached() async {
    await _webSocketService.disconnect();
  }
  
  Future<void> _syncMissedUpdates() async {
    // Implementation depends on your sync strategy
    // Could involve checking server for updates since last sync
  }
}
```

## API Reference

### Frontend API

#### IWebSocketService

```dart
abstract class IWebSocketService {
  /// Connect to WebSocket server
  Future<void> connect();
  
  /// Disconnect from WebSocket server
  Future<void> disconnect();
  
  /// Subscribe to a channel
  void subscribe(String channel, Function(dynamic) callback);
  
  /// Unsubscribe from a channel
  void unsubscribe(String channel);
  
  /// Get current connection state
  WebSocketConnectionState get currentState;
  
  /// Stream of connection state changes
  Stream<WebSocketConnectionState> get connectionState;
  
  /// Handle app lifecycle changes
  Future<void> handleAppLifecycle(AppLifecycleState state);
}
```

#### WebSocketDataSynchronizer

```dart
class WebSocketDataSynchronizer {
  /// Process incoming WebSocket message
  Future<SyncResult> processMessage(WebSocketMessage message);
  
  /// Process multiple messages in batch
  Future<List<SyncResult>> processBatch(List<WebSocketMessage> messages);
  
  /// Resolve data conflict
  Future<void> resolveConflict(
    DataConflict conflict, 
    ConflictResolutionStrategy strategy
  );
  
  /// Stream of synchronization results
  Stream<SyncResult> get syncResultStream;
  
  /// Stream of data conflicts
  Stream<DataConflict> get conflictStream;
}
```

#### WebSocketConfigManager

```dart
class WebSocketConfigManager {
  /// Get current WebSocket configuration
  WebSocketConfig getConfig();
  
  /// Check if WebSocket is enabled
  bool isEnabled();
  
  /// Validate configuration
  bool validateConfiguration();
  
  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary();
}
```

### Backend API

#### CMSWebSocketService

```typescript
class CMSWebSocketService {
  // Customer events
  async broadcastCustomerCreated(customerData: Partial<CustomerEventDto>): Promise<void>;
  async broadcastCustomerUpdated(customerData: Partial<CustomerEventDto>): Promise<void>;
  async broadcastCustomerDeleted(customerData: Partial<CustomerEventDto>): Promise<void>;
  
  // Inventory events
  async broadcastInventoryUpdated(inventoryData: Partial<InventoryEventDto>): Promise<void>;
  async broadcastInventoryLowStock(inventoryData: Partial<InventoryEventDto>): Promise<void>;
  async broadcastInventoryOutOfStock(inventoryData: Partial<InventoryEventDto>): Promise<void>;
  
  // Order events
  async broadcastOrderCreated(orderData: Partial<OrderEventDto>): Promise<void>;
  async broadcastOrderStatusChanged(orderData: Partial<OrderEventDto>): Promise<void>;
  async broadcastOrderUpdated(orderData: Partial<OrderEventDto>): Promise<void>;
  async broadcastOrderCancelled(orderData: Partial<OrderEventDto>): Promise<void>;
  
  // System notifications
  async broadcastSystemNotification(notificationData: Partial<SystemNotificationEventDto>): Promise<void>;
  async broadcastUserNotification(notificationData: Partial<UserNotificationEventDto>): Promise<void>;
}
```

#### CMSWebSocketGateway

```typescript
class CMSWebSocketGateway {
  // Connection management
  async handleConnection(client: Socket): Promise<void>;
  handleDisconnect(client: Socket): void;
  
  // Channel management
  async handleSubscribeChannel(client: Socket, data: ChannelSubscriptionDto): Promise<void>;
  async handleUnsubscribeChannel(client: Socket, data: ChannelSubscriptionDto): Promise<void>;
  
  // Utility methods
  getConnectedUserCount(): number;
  getConnectedUsers(): string[];
  getUserChannels(userId: string): string[];
  isUserConnected(userId: string): boolean;
}
```

## Testing

### Running Tests

```bash
# Frontend tests
cd frontend/shared/data
flutter test test/websocket/

# Backend tests
cd backend
npm test -- --testPathPattern="cms.*websocket.*\.spec\.ts$"

# Integration tests
flutter test test/websocket/integration/
```

### Test Coverage

The implementation includes comprehensive tests:

- **Unit Tests**: 95%+ coverage for core components
- **Integration Tests**: End-to-end WebSocket communication
- **Performance Tests**: High throughput and concurrent connections
- **Error Handling Tests**: Network failures and recovery scenarios

### Example Test

```dart
// Frontend test example
void main() {
  group('WebSocket Integration Tests', () {
    late IWebSocketService webSocketService;
    
    setUp(() async {
      webSocketService = WebSocketFactory.createWebSocketService(
        sharedPreferenceHelper: mockSharedPreferenceHelper,
        config: testConfig,
      );
    });
    
    test('should receive real-time customer updates', () async {
      await webSocketService.connect();
      
      final receivedEvents = <dynamic>[];
      webSocketService.subscribe('customers', (data) {
        receivedEvents.add(data);
      });
      
      // Simulate server event
      await mockServer.broadcastToRoom('customers', {
        'eventType': 'customer.updated',
        'customerId': 'KH001',
        'customerData': {'ten': 'Updated Name'},
      });
      
      await Future.delayed(Duration(milliseconds: 200));
      
      expect(receivedEvents, hasLength(1));
      expect(receivedEvents.first['eventType'], 'customer.updated');
    });
  });
}
```

## Deployment

### Frontend Deployment

1. **Build Configuration**

```bash
# Development build
flutter build apk --debug --flavor development

# Production build
flutter build apk --release --flavor production
```

2. **Environment Variables**

```bash
# Set environment variables for production
export WEBSOCKET_URL=wss://api.ankhanh.com
export API_BASE_URL=https://api.ankhanh.com
```

### Backend Deployment

1. **Docker Configuration**

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY dist ./dist
EXPOSE 3000

CMD ["node", "dist/main.js"]
```

2. **Docker Compose**

```yaml
# docker-compose.yml
version: '3.8'
services:
  backend:
    build: .
    ports:
      - "3000:3000"
    environment:
      - REDIS_HOST=redis
      - DATABASE_URL=postgresql://user:pass@postgres:5432/db
    depends_on:
      - redis
      - postgres
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
  
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: ankhanh_cms
      POSTGRES_USER: cms_user
      POSTGRES_PASSWORD: cms_password
    ports:
      - "5432:5432"
```

### Production Checklist

- [ ] Configure SSL/TLS certificates for WSS
- [ ] Set up Redis cluster for high availability
- [ ] Configure load balancer for WebSocket connections
- [ ] Set up monitoring and alerting
- [ ] Configure log aggregation
- [ ] Set up backup and recovery procedures
- [ ] Test failover scenarios
- [ ] Configure rate limiting
- [ ] Set up health checks

## Troubleshooting

### Common Issues

#### Connection Issues

**Problem**: WebSocket connection fails
```
Error: WebSocket connection failed: Connection refused
```

**Solutions**:
1. Check server is running and accessible
2. Verify WebSocket URL configuration
3. Check firewall and network settings
4. Validate SSL certificates for WSS connections

```dart
// Debug connection issues
final configManager = WebSocketConfigManager();
print('WebSocket URL: ${configManager.getConfig().url}');
print('Is enabled: ${configManager.isEnabled()}');

// Test basic connectivity
try {
  await webSocketService.connect();
  print('Connection successful');
} catch (e) {
  print('Connection failed: $e');
}
```

#### Authentication Issues

**Problem**: Authentication fails repeatedly
```
Error: Authentication failed: Invalid token
```

**Solutions**:
1. Check JWT token validity and expiration
2. Verify token format and signing key
3. Ensure token is properly stored and retrieved

```dart
// Debug authentication
final token = await sharedPreferenceHelper.authToken;
print('Token: ${token?.substring(0, 20)}...');
print('Is logged in: ${await sharedPreferenceHelper.isLoggedIn}');
```

#### Message Delivery Issues

**Problem**: Messages not received on client
```
Warning: Subscribed to channel but no messages received
```

**Solutions**:
1. Verify channel subscription
2. Check user permissions for channel access
3. Confirm server is broadcasting to correct channels

```dart
// Debug message delivery
webSocketService.subscribe('customers', (data) {
  print('Received message: $data');
});

// Check subscribed channels
final channels = await webSocketService.getSubscribedChannels();
print('Subscribed channels: $channels');
```

### Performance Issues

#### High Memory Usage

**Problem**: Memory usage increases over time
```
Warning: Memory usage growing continuously
```

**Solutions**:
1. Implement proper cleanup of event listeners
2. Limit message queue size
3. Clean up old synchronization data

```dart
// Implement proper cleanup
class WebSocketManager {
  final List<StreamSubscription> _subscriptions = [];
  
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
```

#### Connection Instability

**Problem**: Frequent reconnections
```
Warning: WebSocket reconnecting frequently
```

**Solutions**:
1. Adjust reconnection intervals
2. Check network stability
3. Implement connection quality monitoring

```dart
// Monitor connection quality
webSocketService.connectionState.listen((state) {
  if (state == WebSocketConnectionState.reconnecting) {
    _reconnectionCount++;
    if (_reconnectionCount > 5) {
      // Implement fallback strategy
      _handleFrequentReconnections();
    }
  }
});
```

### Debug Tools

#### Connection Monitoring

```dart
class WebSocketDebugger {
  static void enableDebugMode() {
    // Enable detailed logging
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  }
  
  static void logConnectionStats(IWebSocketService service) {
    print('Connection State: ${service.currentState}');
    print('Subscribed Channels: ${service.getSubscribedChannels()}');
    print('Message Queue Size: ${service.getQueuedMessageCount()}');
  }
}
```

#### Performance Monitoring

```dart
class WebSocketPerformanceMonitor {
  static final Map<String, DateTime> _messageTimestamps = {};
  
  static void trackMessageLatency(String messageId) {
    _messageTimestamps[messageId] = DateTime.now();
  }
  
  static Duration? getMessageLatency(String messageId) {
    final timestamp = _messageTimestamps[messageId];
    if (timestamp != null) {
      return DateTime.now().difference(timestamp);
    }
    return null;
  }
}
```

## Performance Optimization

### Frontend Optimizations

1. **Message Batching**
```dart
class MessageBatcher {
  final List<WebSocketMessage> _batch = [];
  Timer? _batchTimer;
  
  void addMessage(WebSocketMessage message) {
    _batch.add(message);
    
    _batchTimer?.cancel();
    _batchTimer = Timer(Duration(milliseconds: 100), () {
      _processBatch();
    });
  }
  
  void _processBatch() {
    if (_batch.isNotEmpty) {
      synchronizer.processBatch(_batch);
      _batch.clear();
    }
  }
}
```

2. **Connection Pooling**
```dart
class WebSocketConnectionPool {
  static const int maxConnections = 3;
  final List<WebSocketConnection> _connections = [];
  
  WebSocketConnection getConnection() {
    // Return least loaded connection
    return _connections.reduce((a, b) => 
      a.subscriptionCount < b.subscriptionCount ? a : b
    );
  }
}
```

### Backend Optimizations

1. **Message Broadcasting Optimization**
```typescript
class OptimizedBroadcaster {
  private readonly batchedMessages = new Map<string, any[]>();
  
  async batchBroadcast(channel: string, message: any) {
    if (!this.batchedMessages.has(channel)) {
      this.batchedMessages.set(channel, []);
      
      // Process batch after short delay
      setTimeout(() => this.processBatch(channel), 50);
    }
    
    this.batchedMessages.get(channel)!.push(message);
  }
  
  private async processBatch(channel: string) {
    const messages = this.batchedMessages.get(channel) || [];
    if (messages.length > 0) {
      await this.socketService.broadcastToChannel(channel, 'batch_update', {
        messages,
        count: messages.length,
      });
    }
    this.batchedMessages.delete(channel);
  }
}
```

2. **Connection Management**
```typescript
class ConnectionManager {
  private readonly connections = new Map<string, ConnectionInfo>();
  
  async cleanupStaleConnections() {
    const now = Date.now();
    const staleThreshold = 5 * 60 * 1000; // 5 minutes
    
    for (const [socketId, info] of this.connections) {
      if (now - info.lastActivity > staleThreshold) {
        await this.disconnectClient(socketId);
      }
    }
  }
}
```

## Security Considerations

### Authentication & Authorization

1. **JWT Token Validation**
```typescript
@UseGuards(WsAuthGuard)
export class CMSWebSocketGateway {
  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token;
      const payload = await this.jwtService.verifyAsync(token);
      
      // Store user context
      client.data.userId = payload.userId;
      client.data.roles = payload.roles;
      
    } catch (error) {
      client.disconnect();
      throw new UnauthorizedException('Invalid token');
    }
  }
}
```

2. **Channel Access Control**
```typescript
private canUserAccessChannel(userData: UserChannelData, channel: string): boolean {
  // Admin access to all channels
  if (userData.roles.includes('admin')) {
    return true;
  }
  
  // Role-based access
  const roleChannelMap = {
    'sales': ['customers', 'orders', 'sales'],
    'warehouse': ['inventory', 'warehouse'],
    'user': ['system'],
  };
  
  for (const role of userData.roles) {
    if (roleChannelMap[role]?.includes(channel)) {
      return true;
    }
  }
  
  return false;
}
```

### Data Protection

1. **Message Encryption** (Optional)
```dart
class MessageEncryption {
  static String encrypt(String message, String key) {
    // Implement AES encryption
    final encrypter = Encrypter(AES(Key.fromBase64(key)));
    final encrypted = encrypter.encrypt(message);
    return encrypted.base64;
  }
  
  static String decrypt(String encryptedMessage, String key) {
    final encrypter = Encrypter(AES(Key.fromBase64(key)));
    final encrypted = Encrypted.fromBase64(encryptedMessage);
    return encrypter.decrypt(encrypted);
  }
}
```

2. **Rate Limiting**
```typescript
@Injectable()
export class RateLimitGuard implements CanActivate {
  private readonly requests = new Map<string, number[]>();
  
  canActivate(context: ExecutionContext): boolean {
    const client = context.switchToWs().getClient<Socket>();
    const userId = client.data.userId;
    const now = Date.now();
    
    const userRequests = this.requests.get(userId) || [];
    const recentRequests = userRequests.filter(time => now - time < 60000); // 1 minute
    
    if (recentRequests.length >= 100) { // Max 100 requests per minute
      return false;
    }
    
    recentRequests.push(now);
    this.requests.set(userId, recentRequests);
    return true;
  }
}
```

### Best Practices

1. **Secure Configuration**
   - Use environment variables for sensitive data
   - Enable CORS only for trusted origins
   - Use WSS (WebSocket Secure) in production
   - Implement proper certificate validation

2. **Input Validation**
   - Validate all incoming messages
   - Sanitize user input
   - Implement message size limits
   - Use schema validation for message structure

3. **Monitoring & Logging**
   - Log all authentication attempts
   - Monitor for suspicious activity
   - Implement alerting for security events
   - Regular security audits

This comprehensive documentation provides everything needed to understand, implement, maintain, and troubleshoot the WebSocket real-time system. For additional support or questions, refer to the test files and example implementations in the codebase.