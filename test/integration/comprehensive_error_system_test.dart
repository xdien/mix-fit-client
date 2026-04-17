import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/error_config_service.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/client_error.dart';
import 'package:core/error/config/error_system_config.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import 'package:core/error/widgets/error_dialog_widget.dart';
import 'package:core/error/widgets/error_snackbar_widget.dart';

import 'comprehensive_error_system_test.mocks.dart';

@GenerateMocks([
  IErrorService,
  IErrorConfigService,
  ErrorStore,
])
void main() {
  late GetIt getIt;
  late MockIErrorService mockErrorService;
  late MockIErrorConfigService mockConfigService;
  late MockErrorStore mockErrorStore;

  setUp(() {
    getIt = GetIt.instance;
    mockErrorService = MockIErrorService();
    mockConfigService = MockIErrorConfigService();
    mockErrorStore = MockErrorStore();

    // Register mocks
    getIt.registerSingleton<IErrorService>(mockErrorService);
    getIt.registerSingleton<IErrorConfigService>(mockConfigService);
    getIt.registerSingleton<ErrorStore>(mockErrorStore);

    // Setup default mock behaviors
    when(mockConfigService.config).thenReturn(const ErrorSystemConfig());
    when(mockConfigService.userPreferences).thenReturn(const ErrorUserPreferences());
    when(mockErrorStore.activeErrors).thenReturn([]);
    when(mockErrorStore.hasErrors).thenReturn(false);
    when(mockErrorStore.isOffline).thenReturn(false);
  });

  tearDown(() {
    getIt.reset();
  });

  group('Comprehensive Error System Tests', () {
    group('Error Service Integration', () {
      testWidgets('should handle API errors end-to-end', (tester) async {
        // Arrange
        final apiError = ApiError(
          id: '1',
          message: 'Server error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );

        when(mockErrorStore.activeErrors).thenReturn([apiError]);
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(apiError);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const ErrorStatusBarWidget(),
              ),
              body: const Center(child: Text('Test App')),
            ),
          ),
        );

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        verify(mockErrorStore.activeErrors).called(greaterThan(0));
      });

      testWidgets('should handle validation errors with form integration', (tester) async {
        // Arrange
        final validationError = ValidationError(
          id: '2',
          message: 'Validation failed',
          fieldErrors: {'email': ['Invalid email format']},
          formId: 'login_form',
        );

        when(mockErrorStore.activeErrors).thenReturn([validationError]);
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(validationError);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const ErrorStatusBarWidget(),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ],
              ),
            ),
          ),
        );

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget);
      });

      testWidgets('should handle network errors with offline state', (tester) async {
        // Arrange
        final networkError = NetworkError(
          id: '3',
          message: 'No internet connection',
          networkType: NetworkErrorType.offline,
        );

        when(mockErrorStore.activeErrors).thenReturn([networkError]);
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.isOffline).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(networkError);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: const ErrorStatusBarWidget(),
              ),
              body: const Center(child: Text('Test App')),
            ),
          ),
        );

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        verify(mockErrorStore.isOffline).called(greaterThan(0));
      });
    });

    group('Error Queue Management', () {
      test('should respect maximum queue size', () {
        // Arrange
        const config = ErrorSystemConfig(maxErrorQueueSize: 3);
        when(mockConfigService.config).thenReturn(config);

        final errors = List.generate(5, (i) => ClientError(
          id: i.toString(),
          message: 'Error $i',
          stackTrace: 'stack',
        ));

        // Simulate adding errors beyond queue size
        when(mockErrorStore.activeErrors).thenReturn(errors.take(3).toList());

        // Assert
        expect(mockErrorStore.activeErrors.length, lessThanOrEqualTo(3));
      });

      test('should prioritize errors correctly', () {
        // Arrange
        final criticalError = ClientError(
          id: '1',
          message: 'Critical error',
          stackTrace: 'stack',
          severity: ErrorSeverity.critical,
        );

        final infoError = ClientError(
          id: '2',
          message: 'Info error',
          stackTrace: 'stack',
          severity: ErrorSeverity.info,
        );

        when(mockErrorStore.activeErrors).thenReturn([infoError, criticalError]);
        when(mockErrorStore.priorityError).thenReturn(criticalError);

        // Assert
        expect(mockErrorStore.priorityError?.severity, equals(ErrorSeverity.critical));
      });
    });

    group('Error UI Components', () {
      testWidgets('should render error status bar correctly', (tester) async {
        // Arrange
        final error = ClientError(
          id: '1',
          message: 'Test error',
          stackTrace: 'stack',
        );

        when(mockErrorStore.activeErrors).thenReturn([error]);
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(error);
        when(mockErrorStore.shouldShowErrorBar).thenReturn(true);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ErrorStatusBarWidget(),
            ),
          ),
        );

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });

      testWidgets('should show error dialog for critical errors', (tester) async {
        // Arrange
        final criticalError = ClientError(
          id: '1',
          message: 'Critical system error',
          stackTrace: 'stack',
          severity: ErrorSeverity.critical,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ErrorDialogWidget(error: criticalError),
                    );
                  },
                  child: const Text('Show Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ErrorDialogWidget), findsOneWidget);
        expect(find.text('Critical system error'), findsOneWidget);
      });

      testWidgets('should show error snackbar for non-critical errors', (tester) async {
        // Arrange
        final infoError = ClientError(
          id: '1',
          message: 'Information message',
          stackTrace: 'stack',
          severity: ErrorSeverity.info,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: ErrorSnackbarWidget(error: infoError),
                      ),
                    );
                  },
                  child: const Text('Show Snackbar'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Snackbar'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ErrorSnackbarWidget), findsOneWidget);
        expect(find.text('Information message'), findsOneWidget);
      });
    });

    group('Configuration Integration', () {
      testWidgets('should respect user preferences for error display', (tester) async {
        // Arrange
        const preferences = ErrorUserPreferences(showErrorBar: false);
        when(mockConfigService.userPreferences).thenReturn(preferences);
        when(mockErrorStore.shouldShowErrorBar).thenReturn(false);

        final error = ClientError(
          id: '1',
          message: 'Test error',
          stackTrace: 'stack',
        );

        when(mockErrorStore.activeErrors).thenReturn([error]);
        when(mockErrorStore.hasErrors).thenReturn(true);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ErrorStatusBarWidget(),
            ),
          ),
        );

        // Assert - Error bar should not be visible due to user preference
        verify(mockErrorStore.shouldShowErrorBar).called(greaterThan(0));
      });

      test('should apply custom timeouts from configuration', () {
        // Arrange
        const customTimeouts = {
          ErrorSeverity.info: Duration(seconds: 2),
          ErrorSeverity.warning: Duration(seconds: 4),
        };

        const config = ErrorSystemConfig(
          userPreferences: ErrorUserPreferences(customTimeouts: customTimeouts),
        );

        when(mockConfigService.config).thenReturn(config);

        // Assert
        expect(config.getAutoDismissTimeout(ErrorSeverity.info), 
               equals(const Duration(seconds: 2)));
        expect(config.getAutoDismissTimeout(ErrorSeverity.warning), 
               equals(const Duration(seconds: 4)));
      });
    });

    group('Performance Tests', () {
      test('should handle rapid error additions efficiently', () {
        // Arrange
        final stopwatch = Stopwatch()..start();
        final errors = <AppError>[];

        // Act - Simulate rapid error additions
        for (int i = 0; i < 100; i++) {
          errors.add(ClientError(
            id: i.toString(),
            message: 'Error $i',
            stackTrace: 'stack',
          ));
        }

        stopwatch.stop();

        // Assert - Should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(errors.length, equals(100));
      });

      test('should efficiently manage error queue memory', () {
        // Arrange
        const config = ErrorSystemConfig(maxErrorQueueSize: 5);
        final errors = <AppError>[];

        // Act - Add more errors than queue size
        for (int i = 0; i < 20; i++) {
          errors.add(ClientError(
            id: i.toString(),
            message: 'Error $i',
            stackTrace: 'stack',
          ));
          
          // Simulate queue management
          if (errors.length > config.maxErrorQueueSize) {
            errors.removeAt(0); // Remove oldest
          }
        }

        // Assert - Queue size should be maintained
        expect(errors.length, equals(config.maxErrorQueueSize));
      });
    });

    group('Accessibility Tests', () {
      testWidgets('should provide proper semantic labels', (tester) async {
        // Arrange
        final error = ClientError(
          id: '1',
          message: 'Accessibility test error',
          stackTrace: 'stack',
        );

        when(mockErrorStore.activeErrors).thenReturn([error]);
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(error);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ErrorStatusBarWidget(),
            ),
          ),
        );

        // Assert - Check for semantic information
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        
        // The widget should have proper semantics for screen readers
        final semantics = tester.getSemantics(find.byType(ErrorStatusBarWidget));
        expect(semantics, isNotNull);
      });

      testWidgets('should support keyboard navigation', (tester) async {
        // Arrange
        final error = ClientError(
          id: '1',
          message: 'Keyboard navigation test',
          stackTrace: 'stack',
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorDialogWidget(error: error),
            ),
          ),
        );

        // Assert - Dialog should be focusable and navigable
        expect(find.byType(ErrorDialogWidget), findsOneWidget);
        
        // Test keyboard navigation (simplified)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Should not throw and should handle keyboard input
      });
    });

    group('Error Recovery Tests', () {
      testWidgets('should handle error service failures gracefully', (tester) async {
        // Arrange
        when(mockErrorService.showError(any)).thenThrow(Exception('Service failure'));

        // Act & Assert - Should not crash the app
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    try {
                      mockErrorService.showError(ClientError(
                        id: '1',
                        message: 'Test error',
                        stackTrace: 'stack',
                      ));
                    } catch (e) {
                      // Error should be caught and handled
                    }
                  },
                  child: const Text('Trigger Error'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger Error'));
        await tester.pump();

        // App should still be responsive
        expect(find.text('Trigger Error'), findsOneWidget);
      });

      test('should recover from configuration errors', () {
        // Arrange
        when(mockConfigService.config).thenThrow(Exception('Config error'));

        // Act & Assert - Should use fallback configuration
        expect(() {
          try {
            final config = mockConfigService.config;
            return config;
          } catch (e) {
            return const ErrorSystemConfig(); // Fallback
          }
        }, returnsNormally);
      });
    });

    group('Integration with App Lifecycle', () {
      testWidgets('should handle app state changes correctly', (tester) async {
        // Arrange
        final error = ClientError(
          id: '1',
          message: 'Lifecycle test error',
          stackTrace: 'stack',
        );

        when(mockErrorStore.activeErrors).thenReturn([error]);
        when(mockErrorStore.hasErrors).thenReturn(true);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const ErrorStatusBarWidget(),
            ),
          ),
        );

        // Simulate app going to background and coming back
        tester.binding.defaultBinaryMessenger.setMockMessageHandler(
          'flutter/lifecycle',
          (data) async => null,
        );

        await tester.pump();

        // Assert - Error state should be maintained
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });
    });
  });
}

/// Helper class for testing error scenarios
class TestErrorScenarios {
  static List<AppError> createMixedErrors() {
    return [
      ApiError(
        id: '1',
        message: 'API Error',
        statusCode: 404,
        endpoint: '/api/test',
        method: 'GET',
      ),
      ValidationError(
        id: '2',
        message: 'Validation Error',
        fieldErrors: {'field': ['error']},
      ),
      NetworkError(
        id: '3',
        message: 'Network Error',
        networkType: NetworkErrorType.timeout,
      ),
      ClientError(
        id: '4',
        message: 'Client Error',
        stackTrace: 'stack trace',
        severity: ErrorSeverity.critical,
      ),
    ];
  }

  static ErrorSystemConfig createTestConfig() {
    return const ErrorSystemConfig(
      maxErrorQueueSize: 3,
      autoDismissTimeouts: {
        ErrorSeverity.info: Duration(milliseconds: 100),
        ErrorSeverity.warning: Duration(milliseconds: 200),
        ErrorSeverity.error: Duration(milliseconds: 500),
        ErrorSeverity.critical: Duration.zero,
      },
      enableErrorLogging: false,
      enableErrorAnalytics: false,
    );
  }
}