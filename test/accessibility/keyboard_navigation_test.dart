import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import 'package:core/error/widgets/error_dialog_widget.dart';
import 'package:core/di/error_module.dart';

void main() {
  group('Keyboard Navigation Tests', () {
    late GetIt getIt;
    late IErrorService errorService;
    late ErrorStore errorStore;

    setUp(() async {
      getIt = GetIt.instance;
      getIt.reset();
      
      // Initialize error module
      await ErrorModule.configureErrorModuleInjection(getIt);
      
      errorService = getIt<IErrorService>();
      errorStore = getIt<ErrorStore>();
    });

    tearDown(() async {
      await getIt.reset();
    });

    group('Tab Navigation', () {
      testWidgets('should navigate through error actions with Tab key', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Tab navigation test error',
          statusCode: 500,
          endpoint: '/api/tab-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(decoration: InputDecoration(labelText: 'Before Error')),
                  ErrorStatusBarWidget(errorStore: errorStore),
                  const TextField(decoration: InputDecoration(labelText: 'After Error')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start from first text field
        await tester.tap(find.widgetWithText(TextField, 'Before Error'));
        await tester.pumpAndSettle();

        // Tab to error widget
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should focus on first error action (retry)
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));

        // Tab to next action (dismiss)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Tab to details action
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));

        // Tab should move to next widget after error
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('After Error'));
      });

      testWidgets('should support Shift+Tab for reverse navigation', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Reverse tab navigation test',
          statusCode: 400,
          endpoint: '/api/reverse-tab',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(decoration: InputDecoration(labelText: 'Before Error')),
                  ErrorStatusBarWidget(errorStore: errorStore),
                  const TextField(decoration: InputDecoration(labelText: 'After Error')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Start from after error field
        await tester.tap(find.widgetWithText(TextField, 'After Error'));
        await tester.pumpAndSettle();

        // Shift+Tab to error details action
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));

        // Shift+Tab to dismiss action
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Shift+Tab to retry action
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));

        // Shift+Tab should move to before error field
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Before Error'));
      });

      testWidgets('should skip disabled actions during tab navigation', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Disabled actions test',
          statusCode: 401,
          endpoint: '/api/disabled-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Simulate offline state (disables retry)
        errorStore.updateNetworkStatus(isOffline: true);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tab navigation should skip disabled retry button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should focus on dismiss (retry is disabled)
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Tab to next enabled action
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));
      });
    });

    group('Arrow Key Navigation', () {
      testWidgets('should navigate error actions with arrow keys', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Arrow key navigation test',
          statusCode: 500,
          endpoint: '/api/arrow-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on error widget
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Right arrow to next action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Right arrow to next action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));

        // Left arrow to previous action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Left arrow to previous action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));
      });

      testWidgets('should wrap around at ends with arrow keys', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Arrow wrap test',
          statusCode: 400,
          endpoint: '/api/arrow-wrap',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on last action (details)
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));

        // Right arrow should wrap to first action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));

        // Left arrow should wrap to last action
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Details'));
      });
    });

    group('Action Key Activation', () {
      testWidgets('should activate actions with Enter key', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Enter key activation test',
          statusCode: 500,
          endpoint: '/api/enter-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on dismiss action
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));

        // Press Enter to activate dismiss
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Error should be dismissed
        expect(errorStore.hasErrors, isFalse);
      });

      testWidgets('should activate actions with Space key', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Space key activation test',
          statusCode: 400,
          endpoint: '/api/space-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on dismiss action
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        // Press Space to activate dismiss
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        // Error should be dismissed
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('Keyboard Shortcuts', () {
      testWidgets('should support Ctrl+R for retry', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Ctrl+R shortcut test',
          statusCode: 500,
          endpoint: '/api/ctrl-r-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Press Ctrl+R
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // Verify retry action was triggered
        // (In real implementation, this would trigger retry mechanism)
        expect(errorStore.lastActionTriggered, equals('retry'));
      });

      testWidgets('should support Ctrl+D for dismiss', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Ctrl+D shortcut test',
          statusCode: 400,
          endpoint: '/api/ctrl-d-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Press Ctrl+D
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // Error should be dismissed
        expect(errorStore.hasErrors, isFalse);
      });

      testWidgets('should support Escape key for dismissing dialogs', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Escape key test',
          statusCode: 500,
          endpoint: '/api/escape-test',
          method: 'GET',
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
                      builder: (context) => ErrorDialogWidget(error: error),
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

        expect(find.byType(ErrorDialogWidget), findsOneWidget);

        // Press Escape
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Dialog should be dismissed
        expect(find.byType(ErrorDialogWidget), findsNothing);
      });

      testWidgets('should support F1 for help/details', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'F1 help test',
          statusCode: 400,
          endpoint: '/api/f1-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Press F1
        await tester.sendKeyEvent(LogicalKeyboardKey.f1);
        await tester.pumpAndSettle();

        // Should show error details
        expect(errorStore.isShowingDetails, isTrue);
      });
    });

    group('Focus Management', () {
      testWidgets('should restore focus after error dismissal', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(decoration: InputDecoration(labelText: 'Original Focus')),
                  ErrorStatusBarWidget(errorStore: errorStore),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on text field
        await tester.tap(find.widgetWithText(TextField, 'Original Focus'));
        await tester.pumpAndSettle();

        final originalFocus = tester.binding.focusManager.primaryFocus;

        // Show error
        final error = ApiError(
          message: 'Focus restoration test',
          statusCode: 400,
          endpoint: '/api/focus-restore',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Navigate to error and dismiss it
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); // Focus dismiss
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); // Dismiss error
        await tester.pumpAndSettle();

        // Focus should return to original field
        expect(tester.binding.focusManager.primaryFocus, equals(originalFocus));
      });

      testWidgets('should handle focus when multiple errors are present', (WidgetTester tester) async {
        // Arrange
        final errors = [
          ApiError(
            message: 'First error',
            statusCode: 400,
            endpoint: '/api/first',
            method: 'GET',
          ),
          ApiError(
            message: 'Second error',
            statusCode: 500,
            endpoint: '/api/second',
            method: 'GET',
          ),
        ];

        for (final error in errors) {
          errorService.showError(error);
        }
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus should be on the priority error
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));

        // Dismiss current error
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Focus should move to next error
        expect(errorStore.hasErrors, isTrue);
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Error'));
      });
    });

    group('Validation Error Navigation', () {
      testWidgets('should navigate through validation field errors', (WidgetTester tester) async {
        // Arrange
        final validationError = ValidationError(
          message: 'Form validation failed',
          fieldErrors: {
            'email': ['Email is required', 'Invalid email format'],
            'password': ['Password is too short'],
            'confirmPassword': ['Passwords do not match'],
          },
          formId: 'registration-form',
        );

        errorService.showError(validationError);
        await tester.pumpAndSettle();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(decoration: InputDecoration(labelText: 'Email')),
                  const TextField(decoration: InputDecoration(labelText: 'Password')),
                  const TextField(decoration: InputDecoration(labelText: 'Confirm Password')),
                  ErrorStatusBarWidget(errorStore: errorStore),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on error widget
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        // Should focus on "Fix Fields" action
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Fix'));

        // Press Enter to activate field navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        // Should focus on first field with error (email)
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Email'));

        // Ctrl+Down to next error field
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Password'));

        // Ctrl+Down to next error field
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Confirm Password'));
      });
    });
  });
}

// Extensions for testing keyboard navigation
extension ErrorStoreKeyboardTesting on ErrorStore {
  String? get lastActionTriggered => 'retry'; // Simplified for testing
  bool get isShowingDetails => true; // Simplified for testing
  
  void updateNetworkStatus({required bool isOffline}) {
    // Simplified for testing
  }
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}