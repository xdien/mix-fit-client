import 'package:flutter_test/flutter_test.dart';

// Import all integration test suites
import 'websocket_e2e_integration_test.dart' as e2e_tests;
import 'websocket_auth_reconnection_integration_test.dart' as auth_reconnection_tests;
import 'websocket_lifecycle_integration_test.dart' as lifecycle_tests;
import 'websocket_performance_integration_test.dart' as performance_tests;

/// Comprehensive WebSocket Integration Test Suite
/// 
/// This test suite combines all WebSocket integration tests to provide
/// complete coverage of the WebSocket functionality including:
/// 
/// 1. End-to-end connection and data flow
/// 2. Authentication and reconnection scenarios
/// 3. App lifecycle management
/// 4. Performance and load testing
/// 
/// Requirements covered:
/// - 4.1: Network interruption handling
/// - 4.2: Automatic reconnection
/// - 4.3: Exponential backoff strategy
/// - 5.1: JWT authentication
/// - 8.1: Background connection management
/// - 8.2: Foreground reconnection
void main() {
  group('WebSocket Comprehensive Integration Tests', () {
    group('End-to-End Integration Tests', () {
      e2e_tests.main();
    });

    group('Authentication & Reconnection Integration Tests', () {
      auth_reconnection_tests.main();
    });

    group('App Lifecycle Integration Tests', () {
      lifecycle_tests.main();
    });

    group('Performance Integration Tests', () {
      performance_tests.main();
    });
  });
}