import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/client_error.dart';
import 'package:core/error/models/error_action.dart';
import 'package:core/error/models/error_severity.dart';
import 'package:core/error/models/error_type.dart';
import 'package:core/error/widgets/error_dialog_widget.dart';

void main() {
  group('ErrorDialogWidget', () {
    Widget createTestWidget({
      required AppError error,
      VoidCallback? onDismiss,
      bool showDetails = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ErrorDialogWidget.show(
                context: context,
                error: error,
                onDismiss: onDismiss,
                showDetails: showDetails,
              ),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('should display critical error dialog with correct styling', (tester) async {
      final criticalError = ApiError(
        message: 'Critical system failure',
        statusCode: 500,
        endpoint: '/api/critical',
        method: 'POST',
      );

      await tester.pumpWidget(createTestWidget(error: criticalError));
      
      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show dialog with critical error styling
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Critical Error'), findsOneWidget);
      expect(find.text('Critical system failure'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should display error dialog with correct styling', (tester) async {
      final error = ApiError(
        message: 'API request failed',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: error));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Error Occurred'), findsOneWidget);
      expect(find.text('API request failed'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should display warning dialog with correct styling', (tester) async {
      final warning = ApiError(
        message: 'This is a warning',
        statusCode: 300,
        endpoint: '/api/redirect',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: warning));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Warning'), findsOneWidget);
      expect(find.text('This is a warning'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('should display info dialog with correct styling', (tester) async {
      final info = ApiError(
        message: 'Information message',
        statusCode: 200,
        endpoint: '/api/info',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: info));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Information'), findsOneWidget);
      expect(find.text('Information message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should show resolution guidance for authentication errors', (tester) async {
      final authError = ApiError(
        message: 'Authentication failed',
        statusCode: 401,
        endpoint: '/api/login',
        method: 'POST',
      );

      await tester.pumpWidget(createTestWidget(error: authError));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('How to resolve this:'), findsOneWidget);
      expect(find.text('Check your login credentials'), findsOneWidget);
      expect(find.text('Try logging out and logging back in'), findsOneWidget);
      expect(find.text('Contact support if the problem persists'), findsOneWidget);
    });

    testWidgets('should show resolution guidance for network errors', (tester) async {
      final networkError = NetworkError(
        message: 'Network connection failed',
        networkType: NetworkErrorType.timeout,
        timeout: const Duration(seconds: 30),
      );

      await tester.pumpWidget(createTestWidget(error: networkError));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('How to resolve this:'), findsOneWidget);
      expect(find.text('Check your internet connection'), findsOneWidget);
      expect(find.text('Try refreshing the page or restarting the app'), findsOneWidget);
      expect(find.text('Wait a moment and try again'), findsOneWidget);
    });

    testWidgets('should show resolution guidance for API/server errors', (tester) async {
      final serverError = ApiError(
        message: 'Internal server error',
        statusCode: 500,
        endpoint: '/api/server',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: serverError));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('How to resolve this:'), findsOneWidget);
      expect(find.text('Try the action again in a few moments'), findsOneWidget);
      expect(find.text('Check your internet connection'), findsOneWidget);
      expect(find.text('Contact support if the error continues'), findsOneWidget);
    });

    testWidgets('should show resolution guidance for validation errors', (tester) async {
      final validationError = ValidationError(
        message: 'Form validation failed',
        fieldErrors: {'email': ['Invalid email format']},
      );

      await tester.pumpWidget(createTestWidget(error: validationError));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('How to resolve this:'), findsOneWidget);
      expect(find.text('Check the highlighted fields for errors'), findsOneWidget);
      expect(find.text('Ensure all required information is provided'), findsOneWidget);
      expect(find.text('Verify the format of your input'), findsOneWidget);
    });

    testWidgets('should show technical details when showDetails is true', (tester) async {
      final errorWithMetadata = ApiError(
        message: 'Error with metadata',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'POST',
      );

      await tester.pumpWidget(createTestWidget(
        error: errorWithMetadata,
        showDetails: true,
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show technical details expansion tile
      expect(find.text('Technical Details'), findsOneWidget);
      
      // Expand the details
      await tester.tap(find.text('Technical Details'));
      await tester.pumpAndSettle();

      // Should show error details
      expect(find.textContaining('Error ID:'), findsOneWidget);
      expect(find.textContaining('Type:'), findsOneWidget);
      expect(find.textContaining('Timestamp:'), findsOneWidget);
      expect(find.textContaining('Status Code:'), findsOneWidget);
      expect(find.textContaining('Endpoint:'), findsOneWidget);
      expect(find.textContaining('Method:'), findsOneWidget);
    });

    testWidgets('should not show technical details when showDetails is false', (tester) async {
      final errorWithMetadata = ApiError(
        message: 'Error without details',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'POST',
      );

      await tester.pumpWidget(createTestWidget(
        error: errorWithMetadata,
        showDetails: false,
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should not show technical details
      expect(find.text('Technical Details'), findsNothing);
    });

    testWidgets('should display custom error actions', (tester) async {
      bool retryCalled = false;
      bool contactSupportCalled = false;

      final errorWithActions = ApiError(
        message: 'Error with custom actions',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction.retry(() => retryCalled = true),
          ErrorAction.contactSupport(() => contactSupportCalled = true),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithActions));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show custom action buttons
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);

      // Test retry action
      await tester.tap(find.text('Retry'));
      expect(retryCalled, isTrue);
    });

    testWidgets('should display primary and secondary actions with correct styling', (tester) async {
      final errorWithMixedActions = ApiError(
        message: 'Error with mixed actions',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction(
            id: 'primary',
            label: 'Primary Action',
            onPressed: () {},
            isPrimary: true,
          ),
          ErrorAction(
            id: 'secondary',
            label: 'Secondary Action',
            onPressed: () {},
            isPrimary: false,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithMixedActions));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show both actions
      expect(find.text('Primary Action'), findsOneWidget);
      expect(find.text('Secondary Action'), findsOneWidget);

      // Primary action should be FilledButton, secondary should be TextButton
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.byType(TextButton), findsAtLeastNWidgets(1)); // At least one (could include Close button)
    });

    testWidgets('should show default close button when no dismiss action provided', (tester) async {
      final errorWithoutDismiss = ApiError(
        message: 'Error without dismiss',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(error: errorWithoutDismiss));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show default close button
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('should not show default close button when dismiss action provided', (tester) async {
      final errorWithDismiss = ApiError(
        message: 'Error with dismiss',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction.dismiss(() {}),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithDismiss));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show custom dismiss button, not default close
      expect(find.text('Dismiss'), findsOneWidget);
      expect(find.text('Close'), findsNothing);
    });

    testWidgets('should call onDismiss callback when close button is tapped', (tester) async {
      bool dismissCalled = false;
      
      final error = ApiError(
        message: 'Test error',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'GET',
      );

      await tester.pumpWidget(createTestWidget(
        error: error,
        onDismiss: () => dismissCalled = true,
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      expect(dismissCalled, isTrue);
    });

    testWidgets('should close dialog when action buttons are tapped', (tester) async {
      final errorWithActions = ApiError(
        message: 'Error with actions',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction.retry(() {}),
          ErrorAction.dismiss(() {}),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithActions));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);

      // Tap retry button - should close dialog
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('should format metadata keys correctly', (tester) async {
      final errorWithComplexMetadata = ClientError.withMetadata(
        message: 'Client error with complex metadata',
        stackTrace: 'Stack trace here',
        componentName: 'TestComponent',
        metadata: {
          'requestId': 'req-123',
          'userId': 'user-456',
          'errorCode': 'ERR_001',
          'camelCaseKey': 'camelValue',
          'snake_case_key': 'snakeValue',
          'stackTrace': 'Stack trace here',
          'componentName': 'TestComponent',
        },
      );

      await tester.pumpWidget(createTestWidget(
        error: errorWithComplexMetadata,
        showDetails: true,
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Expand technical details
      await tester.tap(find.text('Technical Details'));
      await tester.pumpAndSettle();

      // Should format metadata keys properly
      expect(find.textContaining('Request Id:'), findsOneWidget);
      expect(find.textContaining('User Id:'), findsOneWidget);
      expect(find.textContaining('Error Code:'), findsOneWidget);
      expect(find.textContaining('Camel Case Key:'), findsOneWidget);
      expect(find.textContaining('Snake Case Key:'), findsOneWidget);
    });

    testWidgets('should have proper accessibility labels', (tester) async {
      final error = ApiError(
        message: 'Accessible error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        actions: [
          ErrorAction.retry(() {}),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: error));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should have semantic labels
      expect(find.bySemanticsLabel('Error dialog: critical - Accessible error'), findsOneWidget);
      expect(find.bySemanticsLabel('critical error icon'), findsOneWidget);
      expect(find.bySemanticsLabel('Retry button'), findsOneWidget);
      expect(find.bySemanticsLabel('Close dialog button'), findsOneWidget);
    });

    testWidgets('should format timestamps correctly', (tester) async {
      final now = DateTime.now();
      final recentError = ApiError(
        message: 'Recent error',
        statusCode: 500,
        endpoint: '/api/test',
        method: 'GET',
        timestamp: now.subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(createTestWidget(
        error: recentError,
        showDetails: true,
      ));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Expand technical details
      await tester.tap(find.text('Technical Details'));
      await tester.pumpAndSettle();

      // Should show formatted timestamp
      expect(find.textContaining('5 minutes ago'), findsOneWidget);
    });

    testWidgets('should handle destructive actions with correct styling', (tester) async {
      final errorWithDestructiveAction = ApiError(
        message: 'Error with destructive action',
        statusCode: 400,
        endpoint: '/api/test',
        method: 'DELETE',
        actions: [
          ErrorAction(
            id: 'delete',
            label: 'Delete Anyway',
            onPressed: () {},
            isPrimary: true,
            isDestructive: true,
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(error: errorWithDestructiveAction));
      
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Should show destructive action button
      expect(find.text('Delete Anyway'), findsOneWidget);
      
      // Should be styled as destructive (red color)
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.style?.backgroundColor?.resolve({}), equals(Colors.red));
    });
  });
}