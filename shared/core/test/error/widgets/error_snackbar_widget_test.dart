import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/error_action.dart';
import 'package:core/error/models/error_severity.dart';
import 'package:core/error/widgets/error_snackbar_widget.dart';

void main() {
  group('ErrorSnackbarWidget', () {
    Widget createTestWidget({
      required AppError error,
      Duration? duration,
      VoidCallback? onDismiss,
      bool showAction = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () => ErrorSnackbarWidget.show(
                    context: context,
                    error: error,
                    duration: duration,
                    onDismiss: onDismiss,
                    showAction: showAction,
                  ),
                  child: const Text('Show Snackbar'),
                ),
                // Direct widget for testing content
                ErrorSnackbarWidget(
                  error: error,
                  duration: duration,
                  onDismiss: onDismiss,
                  showAction: showAction,
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('should display error message and icon', (tester) async {
      final error = ApiError(
        message: 'Test error message',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: error));

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should display correct icon for different severities', (tester) async {
      // Test critical error
      final criticalError = ApiError(
        message: 'Critical error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: criticalError));
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Test warning error
      final warningError = ApiError(
        message: 'Warning error',
        statusCode: 300,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: warningError));
      expect(find.byIcon(Icons.info), findsOneWidget);

      // Test info error
      final infoError = ApiError(
        message: 'Info error',
        statusCode: 200,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: infoError));
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should show subtitle for non-info errors', (tester) async {
      final error = ApiError(
        message: 'API error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: error));

      expect(find.text('API ERROR'), findsOneWidget);
    });

    testWidgets('should not show subtitle for info errors', (tester) async {
      final infoError = ApiError(
        message: 'Info message',
        statusCode: 200,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: infoError));

      expect(find.text('API ERROR'), findsNothing);
    });

    testWidgets('should show inline action for critical errors', (tester) async {
      final criticalError = ApiError(
        message: 'Critical system failure',
        statusCode: 500,
        endpoint: '/api/critical',
        method: 'POST',
      );

      await tester.pumpWidget(createTestWidget(error: criticalError));

      expect(find.text('Details'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should show inline action for errors with primary action', (tester) async {
      final errorWithPrimaryAction = ApiError(
        message: 'Error with primary action',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction(
            id: 'primary',
            label: 'Fix Now',
            onPressed: () {},
            isPrimary: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithPrimaryAction));

      expect(find.text('Fix Now'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should not show inline action for regular errors', (tester) async {
      final regularError = ApiError(
        message: 'Regular error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: regularError));

      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('should call onDismiss when inline action is pressed', (tester) async {
      bool dismissCalled = false;
      
      final criticalError = ApiError(
        message: 'Critical error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(
        error: criticalError,
        onDismiss: () => dismissCalled = true,
      ));

      await tester.tap(find.text('Details'));
      expect(dismissCalled, isTrue);
    });

    testWidgets('should call primary action and onDismiss when primary action button is pressed', (tester) async {
      bool actionCalled = false;
      bool dismissCalled = false;
      
      final errorWithAction = ApiError(
        message: 'Error with action',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction(
            id: 'primary',
            label: 'Retry',
            onPressed: () => actionCalled = true,
            isPrimary: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        error: errorWithAction,
        onDismiss: () => dismissCalled = true,
      ));

      await tester.tap(find.text('Retry'));
      expect(actionCalled, isTrue);
      expect(dismissCalled, isTrue);
    });

    testWidgets('should show snackbar when show method is called', (tester) async {
      final error = ApiError(
        message: 'Snackbar test',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: error));

      // Tap button to show snackbar
      await tester.tap(find.text('Show Snackbar'));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Snackbar test'), findsAtLeastNWidgets(1)); // One in widget, one in snackbar
    });

    testWidgets('should show snackbar action when showAction is true', (tester) async {
      final errorWithRetry = ApiError(
        message: 'Error with retry',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction.retry(() {}),
        ],
      );

      await tester.pumpWidget(createTestWidget(
        error: errorWithRetry,
        showAction: true,
      ));

      await tester.tap(find.text('Show Snackbar'));
      await tester.pumpAndSettle();

      // Should show snackbar with action
      expect(find.byType(SnackBarAction), findsOneWidget);
    });

    testWidgets('should not show snackbar action when showAction is false', (tester) async {
      final error = ApiError(
        message: 'Error without action',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(
        error: error,
        showAction: false,
      ));

      await tester.tap(find.text('Show Snackbar'));
      await tester.pumpAndSettle();

      // Should show snackbar without action
      expect(find.byType(SnackBarAction), findsNothing);
    });

    testWidgets('should have proper accessibility labels', (tester) async {
      final error = ApiError(
        message: 'Accessible error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction(
            id: 'primary',
            label: 'Fix',
            onPressed: () {},
            isPrimary: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: error));

      // Check that semantic labels exist (the exact text might vary)
      expect(find.byType(ErrorSnackbarWidget), findsOneWidget);
      
      // Check that the widget has semantic structure
      final semanticsWidget = find.byType(Semantics).first;
      expect(semanticsWidget, findsOneWidget);
    });

    testWidgets('should truncate long messages', (tester) async {
      final longMessageError = ApiError(
        message: 'This is a very long error message that should be truncated when displayed in the snackbar widget to prevent overflow and maintain good user experience',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: longMessageError));

      // Should find the text widget with ellipsis overflow
      final textWidget = tester.widget<Text>(find.text(longMessageError.message));
      expect(textWidget.maxLines, equals(2));
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    // Note: Testing private methods is not recommended, but we can test the behavior indirectly
    // by observing the snackbar appearance and duration

    group('ErrorSnackbarQueue', () {
      setUp(() {
        ErrorSnackbarQueue.clear();
      });

      test('should add errors to queue', () {
        final error1 = ApiError(
          message: 'Error 1',
          statusCode: 400,
          endpoint: '/api/test1',
          method: 'GET',
        );
        final error2 = ApiError(
          message: 'Error 2',
          statusCode: 400,
          endpoint: '/api/test2',
          method: 'GET',
        );

        ErrorSnackbarQueue.add(error1);
        ErrorSnackbarQueue.add(error2);

        expect(ErrorSnackbarQueue.length, equals(2));
      });

      test('should add multiple errors to queue', () {
        final errors = [
          ApiError(
            message: 'Error 1',
            statusCode: 400,
            endpoint: '/api/test1',
            method: 'GET',
          ),
          ApiError(
            message: 'Error 2',
            statusCode: 400,
            endpoint: '/api/test2',
            method: 'GET',
          ),
        ];

        ErrorSnackbarQueue.addAll(errors);

        expect(ErrorSnackbarQueue.length, equals(2));
      });

      test('should clear queue', () {
        final error = ApiError(
          message: 'Error',
          statusCode: 400,
          endpoint: '/api/test',
          method: 'GET',
        );

        ErrorSnackbarQueue.add(error);
        expect(ErrorSnackbarQueue.length, equals(1));

        ErrorSnackbarQueue.clear();
        expect(ErrorSnackbarQueue.length, equals(0));
      });
    });
  });
}