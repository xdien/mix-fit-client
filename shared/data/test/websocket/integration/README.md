# WebSocket Integration Tests

This directory contains comprehensive integration tests for the WebSocket real-time mobile feature. These tests cover all aspects of WebSocket functionality including connection management, authentication, data synchronization, app lifecycle handling, and performance testing.

## Test Coverage

### Requirements Covered

- **4.1**: Network interruption handling
- **4.2**: Automatic reconnection
- **4.3**: Exponential backoff strategy
- **5.1**: JWT authentication
- **8.1**: Background connection management
- **8.2**: Foreground reconnection

### Test Suites

#### 1. End-to-End Integration Tests (`websocket_e2e_integration_test.dart`)

**Purpose**: Complete WebSocket connection and data flow testing

**Coverage**:
- Full connection establishment and authentication flow
- Real-time message sending and receiving
- Channel subscription and unsubscription
- Error handling and recovery scenarios
- Network issue simulation
- High-throughput message processing
- Concurrent subscription management

**Key Features**:
- Mock WebSocket server for controlled testing
- Authentication failure scenarios
- Message integrity verification
- Performance metrics collection

#### 2. Authentication & Reconnection Tests (`websocket_auth_reconnection_integration_test.dart`)

**Purpose**: Authentication flow and reconnection strategy testing

**Coverage**:
- JWT token authentication
- Token expiration and refresh handling
- Authentication timeout scenarios
- Exponential backoff implementation
- Connection state management
- Error reporting and handling

**Key Features**:
- Multiple authentication scenarios
- Reconnection timing verification
- Concurrent authentication handling
- Meaningful error information validation

#### 3. App Lifecycle Integration Tests (`websocket_lifecycle_integration_test.dart`)

**Purpose**: App lifecycle state management and data synchronization

**Coverage**:
- Background/foreground state transitions
- Connection management during lifecycle changes
- Missed update synchronization
- Subscription persistence across lifecycle changes
- Debouncing of rapid state changes

**Key Features**:
- Lifecycle state simulation
- Background time tracking
- Synchronization verification
- Performance during lifecycle changes

#### 4. Performance Integration Tests (`websocket_performance_integration_test.dart`)

**Purpose**: Load testing, throughput measurement, and resource usage validation

**Coverage**:
- High-frequency message burst handling
- Large payload processing
- Concurrent message processing
- Memory pressure testing
- Connection performance metrics
- Subscription/unsubscription performance

**Key Features**:
- Throughput measurement
- Latency tracking
- Resource usage monitoring
- Performance benchmarking

## Mock WebSocket Server

The `MockWebSocketServer` class provides a comprehensive testing environment that simulates various real-world scenarios:

### Features

- **Connection Management**: Handles WebSocket connections with configurable delays
- **Authentication Simulation**: JWT token validation with configurable success/failure
- **Channel Management**: Subscription/unsubscription with proper event tracking
- **Message Broadcasting**: Channel-based message distribution
- **Error Simulation**: Network issues, server overload, connection drops
- **Performance Testing**: Configurable message delays, corruption, and drop rates

### Configuration Options

```dart
// Connection behavior
mockServer.connectionDelay = Duration(seconds: 1);
mockServer.maxConnections = 10;

// Authentication behavior
mockServer.shouldRejectAuth = true;

// Network simulation
mockServer.simulateNetworkIssues();
mockServer.simulateServerOverload();
mockServer.simulateConnectionDrops();

// Message behavior
mockServer.messageDelay = Duration(milliseconds: 100);
mockServer.messageDropRate = 0.1; // 10% drop rate
mockServer.shouldCorruptMessages = true;
```

## Running the Tests

### Prerequisites

1. Flutter SDK installed and in PATH
2. Dependencies installed (`flutter pub get`)
3. Running from the `frontend/shared/data` directory

### Running All Tests

```bash
# Run all integration tests
dart test/websocket/integration/run_integration_tests.dart

# Run with verbose output
dart test/websocket/integration/run_integration_tests.dart --verbose
```

### Running Specific Test Suites

```bash
# Run only end-to-end tests
dart test/websocket/integration/run_integration_tests.dart --e2e

# Run only authentication tests
dart test/websocket/integration/run_integration_tests.dart --auth

# Run only lifecycle tests
dart test/websocket/integration/run_integration_tests.dart --lifecycle

# Run only performance tests
dart test/websocket/integration/run_integration_tests.dart --performance
```

### Running Individual Test Files

```bash
# Run specific test file
flutter test test/websocket/integration/websocket_e2e_integration_test.dart

# Run with verbose output
flutter test test/websocket/integration/websocket_e2e_integration_test.dart --reporter=expanded
```

### Custom Timeout

```bash
# Set custom timeout (in milliseconds)
dart test/websocket/integration/run_integration_tests.dart --timeout=600000
```

## Test Structure

### Test Organization

Each test suite follows a consistent structure:

```dart
group('Test Suite Name', () {
  // Setup and teardown
  setUp(() async { /* Initialize test environment */ });
  tearDown(() async { /* Clean up resources */ });

  group('Feature Group', () {
    test('should do something specific', () async {
      // Arrange
      // Act
      // Assert
    });
  });
});
```

### Common Patterns

#### Mock Server Setup

```dart
setUp(() async {
  mockServer = MockWebSocketServer();
  await mockServer.start();
  
  // Configure authentication
  when(mockSharedPreferenceHelper.authToken)
      .thenAnswer((_) async => 'valid-test-token');
});
```

#### Connection Testing

```dart
test('should establish connection', () async {
  await webSocketService.connect();
  await Future.delayed(const Duration(milliseconds: 300));
  expect(webSocketService.currentState, WebSocketConnectionState.connected);
});
```

#### Message Testing

```dart
test('should receive messages', () async {
  final receivedMessages = <dynamic>[];
  webSocketService.subscribe('test-channel', (data) {
    receivedMessages.add(data);
  });
  
  await mockServer.broadcastToChannel('test-channel', {
    'type': 'test-message',
    'data': {'content': 'Hello'},
  });
  
  await Future.delayed(const Duration(milliseconds: 200));
  expect(receivedMessages, hasLength(1));
});
```

## Performance Benchmarks

### Expected Performance Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Connection Time | < 2 seconds | Average time to establish connection |
| Message Throughput | > 20 msg/sec | Messages processed per second |
| Message Latency | < 100ms | Time from send to receive |
| Reconnection Time | < 3 seconds | Time to reconnect after failure |
| Memory Usage | < 10MB | Approximate memory usage during tests |

### Performance Test Categories

1. **Throughput Tests**: High-frequency message bursts
2. **Latency Tests**: Message processing time measurement
3. **Load Tests**: Concurrent connections and subscriptions
4. **Stress Tests**: Resource usage under pressure
5. **Endurance Tests**: Long-running stability

## Troubleshooting

### Common Issues

#### Test Timeouts

```bash
# Increase timeout for slow environments
dart test/websocket/integration/run_integration_tests.dart --timeout=600000
```

#### Port Conflicts

The mock server uses random ports to avoid conflicts. If you encounter port issues:

```dart
// In test setup, specify a different port range
await mockServer.start(8080); // Use specific port
```

#### Memory Issues

For memory-intensive tests:

```bash
# Run tests individually
flutter test test/websocket/integration/websocket_performance_integration_test.dart
```

#### Authentication Failures

Ensure mock authentication is properly configured:

```dart
when(mockSharedPreferenceHelper.authToken)
    .thenAnswer((_) async => 'valid-test-token');
when(mockSharedPreferenceHelper.isLoggedIn)
    .thenAnswer((_) async => true);
```

### Debug Mode

Enable verbose output for detailed test information:

```bash
dart test/websocket/integration/run_integration_tests.dart --verbose
```

## Continuous Integration

### GitHub Actions Integration

```yaml
name: WebSocket Integration Tests
on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
        working-directory: frontend/shared/data
      - run: dart test/websocket/integration/run_integration_tests.dart
        working-directory: frontend/shared/data
```

### Test Reports

The test runner generates comprehensive reports including:

- Test suite pass/fail status
- Performance metrics
- Duration comparisons
- Requirements coverage verification

## Contributing

### Adding New Tests

1. Follow the existing test structure and naming conventions
2. Include proper setup and teardown
3. Add performance assertions where applicable
4. Update this README with new test descriptions
5. Ensure tests are deterministic and don't rely on external services

### Test Guidelines

- Use descriptive test names that explain the expected behavior
- Include both positive and negative test cases
- Test edge cases and error conditions
- Verify performance characteristics
- Clean up resources in tearDown methods
- Use appropriate timeouts for async operations

## Backend Integration Tests

The backend also includes comprehensive WebSocket integration tests located at:
`backend/test/e2e/websocket-integration.e2e-spec.ts`

These tests cover:
- Server-side WebSocket functionality
- CMS event broadcasting
- Authentication and authorization
- Channel management
- Error handling
- Performance and load testing

Run backend tests with:
```bash
cd backend
npm run test:e2e -- websocket-integration.e2e-spec.ts
```