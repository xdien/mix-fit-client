# WebSocket Service - User Preferences and Notification Controls

This module implements user preferences and notification controls for the WebSocket real-time system, as specified in task 9 of the WebSocket implementation plan.

## Features

### ✅ WebSocket Preferences Management System
- Complete preferences storage using SharedPreferences
- Reactive preferences updates using MobX
- Type-safe preference models with Freezed
- Automatic preference persistence and loading

### ✅ Settings UI for Real-time Update Subscriptions
- Comprehensive preferences screen with Material Design
- Channel-specific subscription controls
- Priority-based notification filtering
- User-friendly toggle switches and selection chips

### ✅ Channel Subscription/Unsubscription
- Dynamic channel management based on user preferences
- Automatic subscription updates when preferences change
- Support for system-managed channels that cannot be disabled
- Real-time subscription state synchronization

### ✅ Notification Filtering and Priority Handling
- Four-level priority system (Low, Normal, High, Critical)
- Per-channel notification priority configuration
- Intelligent notification filtering based on user preferences
- Visual priority indicators with color coding

## Architecture

The module follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── models/                     # Data models
│   ├── websocket_preferences.dart
│   └── websocket_channel_config.dart
├── domain/                     # Business logic interfaces
│   └── repository/
│       └── websocket_preferences_repository.dart
├── data/                       # Data layer implementation
│   └── repository/
│       └── websocket_preferences_repository_impl.dart
├── stores/                     # MobX state management
│   └── websocket_preferences_store.dart
└── widgets/                    # UI components
    ├── websocket_preferences_screen.dart
    ├── websocket_channel_preferences_widget.dart
    ├── websocket_connection_status_widget.dart
    └── websocket_preferences_demo.dart
```

## Usage

### 1. Setup Dependencies

Add to your `pubspec.yaml`:

```yaml
dependencies:
  websocket_service:
    path: shared/websocket_service
```

### 2. Initialize the Preferences Store

```dart
import 'package:websocket_service/websocket_service.dart';
import 'package:get_it/get_it.dart';

// Register dependencies
GetIt.instance.registerLazySingleton<WebSocketPreferencesRepository>(
  () => WebSocketPreferencesRepositoryImpl(
    GetIt.instance<SharedPreferenceHelper>(),
  ),
);

GetIt.instance.registerLazySingleton<WebSocketPreferencesStore>(
  () => WebSocketPreferencesStore(
    GetIt.instance<WebSocketPreferencesRepository>(),
    GetIt.instance<ErrorStore>(),
  ),
);
```

### 3. Use the Preferences Screen

```dart
import 'package:websocket_service/websocket_service.dart';

// Navigate to preferences
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WebSocketPreferencesScreen(
      store: GetIt.instance<WebSocketPreferencesStore>(),
    ),
  ),
);
```

### 4. Display Connection Status

```dart
import 'package:websocket_service/websocket_service.dart';

// Show connection status widget
WebSocketConnectionStatusWidget(
  preferencesStore: preferencesStore,
  connectionState: currentConnectionState,
  onTap: () => showConnectionDetails(),
)

// Show connection status bar
WebSocketConnectionStatusBar(
  preferencesStore: preferencesStore,
  connectionState: currentConnectionState,
  errorMessage: errorMessage,
  onTap: () => showConnectionDetails(),
)
```

### 5. React to Preference Changes

```dart
import 'package:flutter_mobx/flutter_mobx.dart';

Observer(
  builder: (context) {
    final activeChannels = preferencesStore.activeSubscribedChannels;
    
    // Update WebSocket subscriptions based on preferences
    if (preferencesStore.enableRealTimeUpdates) {
      websocketService.subscribeToChannels(activeChannels);
    } else {
      websocketService.unsubscribeFromAllChannels();
    }
    
    return YourWidget();
  },
)
```

### 6. Check Notification Permissions

```dart
// Check if a notification should be shown
final shouldShow = preferencesStore.shouldShowNotification(
  'customer', 
  NotificationPriority.high,
);

if (shouldShow) {
  showNotification(message);
}
```

## Available Channels

The system supports the following predefined channels:

| Channel ID | Display Name | Type | Default Priority | User Configurable |
|------------|--------------|------|------------------|-------------------|
| `customer` | Customer Updates | Customer | Normal | ✅ |
| `inventory` | Inventory Changes | Inventory | High | ✅ |
| `order` | Order Status | Order | High | ✅ |
| `system` | System Notifications | System | Critical | ❌ |
| `notification` | General Notifications | Notification | Normal | ✅ |

## Notification Priority Levels

1. **Low (1)** - Non-critical updates, can be filtered out
2. **Normal (2)** - Standard notifications, default level
3. **High (3)** - Important updates that should be shown
4. **Critical (4)** - System-critical notifications, always shown

## Testing

The module includes comprehensive unit tests:

```bash
cd frontend/shared/websocket_service
flutter test
```

Test coverage includes:
- ✅ Model serialization/deserialization
- ✅ Repository implementation with mocked SharedPreferences
- ✅ Store state management and error handling
- ✅ Preference persistence and retrieval
- ✅ Channel subscription logic
- ✅ Notification filtering logic

## Integration with WebSocket Service

This preferences system is designed to integrate with the broader WebSocket service:

1. **Channel Subscriptions**: The `activeSubscribedChannels` computed property provides the list of channels to subscribe to
2. **Notification Filtering**: Use `shouldShowNotification()` to determine if incoming messages should trigger notifications
3. **Connection Status**: The status widgets provide visual feedback about WebSocket connection state
4. **User Control**: Users can enable/disable real-time updates globally or per-channel

## Requirements Fulfilled

This implementation fulfills all requirements from task 9:

- ✅ **6.1**: User can configure notification preferences through settings UI
- ✅ **6.2**: System unsubscribes from disabled WebSocket channels automatically
- ✅ **6.3**: Preference changes are applied immediately to subscription settings
- ✅ **6.4**: Critical system updates override user preferences when necessary

## Future Enhancements

Potential improvements for future iterations:

- [ ] Export/import preference configurations
- [ ] Role-based default preferences
- [ ] Advanced notification scheduling
- [ ] Channel grouping and bulk operations
- [ ] Usage analytics and recommendations