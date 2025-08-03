# WebSocket Connection Status UI Components

This package provides a comprehensive set of UI components for displaying WebSocket connection status in Flutter applications. The components are designed to work with the existing WebSocket implementation and provide real-time feedback to users about their connection status.

## Components Overview

### 1. WebSocketConnectionStatusWidget
A compact widget that displays the current connection state with appropriate icons and colors.

**Features:**
- Visual indicators for all connection states (connected, connecting, reconnecting, disconnected, error)
- Compact and full display modes
- Customizable text display
- Tap callback support

**Usage:**
```dart
WebSocketConnectionStatusWidget(
  connectionState: WebSocketConnectionState.connected,
  showText: true,
  isCompact: false,
  onTap: () => print('Status tapped'),
)
```

### 2. WebSocketConnectionQualityWidget
Displays connection quality using signal strength bars similar to mobile network indicators.

**Features:**
- Signal strength visualization (4 bars)
- Quality levels: excellent, good, fair, poor, offline
- Automatic quality determination based on response time and reconnect attempts
- Optional quality text display

**Usage:**
```dart
WebSocketConnectionQualityWidget.fromMetrics(
  connectionState: WebSocketConnectionState.connected,
  lastResponseTime: Duration(milliseconds: 150),
  reconnectAttempts: 0,
  showQualityText: true,
)
```

### 3. WebSocketStatusBarWidget
A comprehensive status bar that combines connection status and quality indicators with user interaction capabilities.

**Features:**
- Full and minimized display modes
- Connection details section
- Retry and dismiss actions
- Automatic state-based styling
- Error information display

**Usage:**
```dart
WebSocketStatusBarWidget(
  connectionState: connectionState,
  lastError: lastError,
  reconnectAttempts: reconnectAttempts,
  showDetails: true,
  isMinimized: false,
  onRetry: () => retryConnection(),
  onDismiss: () => hideStatusBar(),
)
```

### 4. WebSocketOfflineModeWidget
A modal-style widget that appears when the connection is offline, providing detailed information and actions.

**Features:**
- Contextual messaging based on connection state
- Queued updates information
- Last connected time display
- Retry connection functionality
- Error-specific hints and suggestions

**Usage:**
```dart
WebSocketOfflineModeWidget(
  connectionState: WebSocketConnectionState.disconnected,
  lastConnectedTime: DateTime.now().subtract(Duration(minutes: 5)),
  queuedUpdatesCount: 3,
  onRetryConnection: () => retryConnection(),
  onViewQueuedUpdates: () => showQueuedUpdates(),
)
```

### 5. WebSocketStatusPage
A full-page or dialog component that provides comprehensive connection status information.

**Features:**
- Detailed connection overview
- Error information display
- Queued updates management
- Connection metrics
- Action buttons for retry and error clearing

**Usage:**
```dart
// As a dialog
showDialog(
  context: context,
  builder: (context) => WebSocketStatusPage(
    statusStore: statusStore,
    isDialog: true,
  ),
);

// As a full page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => WebSocketStatusPage(
      statusStore: statusStore,
      isDialog: false,
    ),
  ),
);
```

### 6. WebSocketStatusStore
A MobX store that manages the UI state for WebSocket status components.

**Features:**
- Reactive state management
- Connection state tracking
- Error handling
- UI visibility controls
- Automatic status bar behavior

**Usage:**
```dart
final statusStore = WebSocketStatusStore(webSocketService);

// Use with Observer widgets
Observer(
  builder: (context) => WebSocketStatusBarWidget(
    connectionState: statusStore.connectionState,
    lastError: statusStore.lastError,
    // ... other properties
  ),
)
```

## Integration Patterns

### Basic Integration
For simple status indication:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WebSocketStatusBarWidget(
          connectionState: connectionState,
          isMinimized: true,
        ),
        Expanded(child: YourAppContent()),
      ],
    );
  }
}
```

### Full Integration
For comprehensive status management:

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late WebSocketStatusStore statusStore;

  @override
  void initState() {
    super.initState();
    statusStore = WebSocketStatusStore(webSocketService);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Observer(
            builder: (context) => statusStore.isStatusBarVisible
                ? WebSocketStatusBarWidget(
                    connectionState: statusStore.connectionState,
                    lastError: statusStore.lastError,
                    onRetry: () => statusStore.retryConnection(),
                    onDismiss: () => statusStore.hideStatusBar(),
                  )
                : SizedBox.shrink(),
          ),
          Expanded(
            child: Stack(
              children: [
                YourAppContent(),
                Observer(
                  builder: (context) => statusStore.shouldShowOfflineMode
                      ? WebSocketOfflineModeWidget(
                          connectionState: statusStore.connectionState,
                          onRetryConnection: () => statusStore.retryConnection(),
                        )
                      : SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

## Styling and Theming

All components respect the current Flutter theme and provide consistent styling:

- **Colors**: Automatically adapt to light/dark themes
- **Typography**: Uses theme text styles
- **Spacing**: Consistent with Material Design guidelines
- **Animations**: Smooth transitions between states

### Custom Styling
Components can be customized by wrapping them in Theme widgets:

```dart
Theme(
  data: Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: Colors.blue,
      error: Colors.red,
    ),
  ),
  child: WebSocketStatusBarWidget(...),
)
```

## State Management

The components work with any state management solution but are optimized for MobX:

```dart
// MobX integration
Observer(
  builder: (context) => WebSocketConnectionStatusWidget(
    connectionState: store.connectionState,
  ),
)

// Manual state management
StatefulWidget with setState()
StreamBuilder for reactive updates
Provider/Riverpod integration
```

## Accessibility

All components include proper accessibility support:

- **Semantic labels**: Screen reader friendly
- **Focus management**: Keyboard navigation support
- **High contrast**: Respects system accessibility settings
- **Touch targets**: Minimum 44px touch targets

## Testing

The components are designed to be easily testable:

```dart
testWidgets('displays connected state correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: WebSocketConnectionStatusWidget(
        connectionState: WebSocketConnectionState.connected,
      ),
    ),
  );

  expect(find.byIcon(Icons.wifi), findsOneWidget);
  expect(find.text('Connected'), findsOneWidget);
});
```

## Performance Considerations

- **Efficient rebuilds**: Only rebuild when necessary
- **Memory management**: Proper disposal of resources
- **Animation optimization**: Smooth 60fps animations
- **Lazy loading**: Components only render when visible

## Requirements Mapping

This implementation satisfies the following requirements:

- **9.1**: ✅ Connected status indicator with visual feedback
- **9.2**: ✅ Disconnected status indicator with appropriate styling
- **9.3**: ✅ Reconnecting status indicator with progress animation
- **9.4**: ✅ Offline mode display with contextual information
- **9.5**: ✅ Connection quality indicators with signal strength visualization

## Examples

See `websocket_status_integration_example.dart` for complete integration examples showing:

- Full-featured integration with all components
- Minimal integration for simple use cases
- Dialog-based status details
- Offline mode handling
- Error state management

## Dependencies

- `flutter/material.dart`: Core Flutter widgets
- `flutter_mobx`: Reactive state management
- `data/websocket`: WebSocket models and interfaces

## Migration Guide

If upgrading from a previous version:

1. Update import statements to use the new widget exports
2. Replace any custom status indicators with the provided components
3. Integrate the WebSocketStatusStore for reactive updates
4. Update theme customizations to use the new styling approach