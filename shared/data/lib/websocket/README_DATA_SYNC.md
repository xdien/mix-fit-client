# WebSocket Data Synchronization System

This document describes the real-time data synchronization system implemented for WebSocket communication in the Flutter mobile application.

## Overview

The WebSocket data synchronization system provides:

- **Real-time data updates** for customers, inventory, and orders
- **Conflict resolution** for concurrent data modifications
- **Message routing** to appropriate handlers
- **Local database integration** using Drift
- **Automatic synchronization** with the backend

## Architecture

### Core Components

1. **WebSocketDataSynchronizer** - Main orchestrator for data synchronization
2. **MessageRouter** - Routes incoming messages to appropriate handlers
3. **ConflictResolver** - Handles data conflicts during synchronization
4. **SyncDatabase** - Local Drift database for storing synchronized data

### Data Flow

```
WebSocket Message → MessageRouter → DataSynchronizer → ConflictResolver → Local Database
                                                    ↓
                                              UI Updates (MobX)
```

## Key Features

### Message Types

The system supports the following message types:

- `customer.updated` - Customer data changes
- `inventory.changed` - Inventory level changes
- `order.status.changed` - Order status updates
- `system.notification` - System-wide notifications

### Conflict Resolution Strategies

- **useRemote** - Use server data (default for inventory)
- **useLocal** - Use local data
- **useLatest** - Use data with latest timestamp (default for customers)
- **merge** - Merge both datasets using field-level rules (default for orders)
- **manual** - Require manual resolution

### Database Schema

The system maintains local copies of:

- **Customers** - Customer information with sync timestamps
- **Inventory** - Product inventory with quantities and prices
- **Orders** - Order data with status and payment information
- **SyncOperationEntries** - Pending synchronization operations

## Usage

### Basic Setup

```dart
// Initialize database
final database = SyncDatabase();

// Create data synchronizer
final synchronizer = WebSocketDataSynchronizer(database: database);

// Set up WebSocket service with synchronizer
final webSocketService = WebSocketService(config, authCallback);

// Subscribe to channels
webSocketService.subscribe('customers', (data) async {
  final message = WebSocketMessage.fromJson(data);
  await synchronizer.processMessage(message);
});
```

### Handling Sync Results

```dart
// Listen to synchronization results
synchronizer.syncResultStream.listen((result) {
  if (result.success) {
    print('Sync completed: ${result.operationId}');
  } else {
    print('Sync failed: ${result.error}');
  }
});
```

### Handling Conflicts

```dart
// Listen to conflicts
synchronizer.conflictStream.listen((conflict) {
  print('Conflict detected for ${conflict.entityType}:${conflict.entityId}');
  
  // Auto-resolve using latest timestamp
  synchronizer.resolveConflict(conflict, 'useLatest');
});
```

### Batch Processing

```dart
// Process multiple messages at once
final messages = [message1, message2, message3];
final results = await synchronizer.processBatch(messages);
```

## Configuration

### Conflict Resolution Rules

You can customize conflict resolution for different entity types:

```dart
final conflictResolver = ConflictResolver();

// Set default strategy for customers
conflictResolver.setDefaultStrategy('customer', ConflictResolutionStrategy.useLatest);

// Set field-level merge rules
conflictResolver.setFieldMergeRules('customer', {
  'name': ConflictResolutionStrategy.useLatest,
  'balance': ConflictResolutionStrategy.useRemote,
  'notes': ConflictResolutionStrategy.merge,
});
```

### Message Routing

```dart
final messageRouter = MessageRouter();

// Register custom handlers
messageRouter.registerHandler(WebSocketMessageType.customerUpdate, (message) async {
  // Custom customer update logic
});
```

## Testing

The system includes comprehensive unit tests:

- **MessageRouter** tests - Message routing and error handling
- **ConflictResolver** tests - All conflict resolution strategies
- **WebSocketDataSynchronizer** tests - End-to-end synchronization
- **WebSocketMessageType** tests - Message type parsing and properties

Run tests with:

```bash
flutter test test/websocket/
```

## Error Handling

The system provides robust error handling:

- **Network errors** - Automatic retry with exponential backoff
- **Authentication errors** - Token refresh and reconnection
- **Data conflicts** - Configurable resolution strategies
- **Message errors** - Graceful degradation and logging

## Performance Considerations

- **Batch processing** - Multiple messages processed efficiently
- **Debounced updates** - Prevents excessive UI updates
- **Background processing** - Non-blocking synchronization
- **Memory management** - Automatic cleanup of completed operations

## Integration with MobX

The synchronizer integrates with existing MobX stores:

```dart
// In your MobX store
@action
void handleWebSocketUpdate(WebSocketMessage message) {
  // Update observable data
  if (message.type == 'customer.updated') {
    updateCustomer(message.data);
  }
}
```

## Monitoring and Debugging

Enable detailed logging:

```dart
import 'dart:developer' as developer;

// All synchronization operations are logged with the name 'WebSocketDataSynchronizer'
// Filter logs in your IDE or debugging tools
```

## Best Practices

1. **Always handle conflicts** - Set up conflict listeners
2. **Use batch processing** - For multiple related updates
3. **Monitor sync results** - Handle failures appropriately
4. **Clean up resources** - Call dispose() when done
5. **Test thoroughly** - Use the provided test utilities

## Example Implementation

See `examples/data_synchronization_example.dart` for a complete working example.

## Dependencies

- `drift` - Local database ORM
- `socket_io_client` - WebSocket communication
- `freezed` - Immutable data models
- `mobx` - State management integration

## Future Enhancements

- **Offline queue** - Store updates when disconnected
- **Selective sync** - Choose which data types to synchronize
- **Compression** - Reduce message size for large datasets
- **Encryption** - End-to-end encryption for sensitive data