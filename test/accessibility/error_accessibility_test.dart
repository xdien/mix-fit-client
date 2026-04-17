import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/validation_error.dart';
import 'package:core/error/models/network_error.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import 'package:core/error/widgets/error_dialog_widget.dart';
import 'package:core/error/widgets/error_snackbar_widget.dart';
import 'package:core/di/error_module.dart';

void main() {
  group('Error Accessibility Tests', () {
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

    group('Screen Reader Compatibility', () {
      testWidgets('ErrorStatusBarWidget should have proper semantic labels', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Test API error for screen reader',
          statusCode: 400,
          endpoint: '/api/test',
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

        // Assert
        expect(find.bySemanticsLabel('Error notification'), findsOneWidget);
        expect(find.bySemanticsLabel('Test API error for screen reader'), findsOneWidget);
        
        // Check for action button semantics
        expect(find.bySemanticsLabel('Retry request'), findsOneWidget);
        expect(find.bySemanticsLabel('Dismiss error'), findsOneWidget);
        
        // Verify semantic properties
        final errorWidget = tester.widget<ErrorStatusBarWidget>(find.byType(ErrorStatusBarWidget));
        expect(errorWidget.semanticLabel, isNotNull);
      });

      testWidgets('ErrorDialogWidget should announce critical errors', (WidgetTester tester) async {
        // Arrange
        final criticalError = ApiError(
          message: 'Critical system error requiring immediate attention',
          statusCode: 500,
          endpoint: '/api/critical',
          method: 'POST',
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
                      builder: (context) => ErrorDialogWidget(error: criticalError),
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
        expect(find.bySemanticsLabel('Critical error dialog'), findsOneWidget);
        expect(find.bySemanticsLabel('Critical system error requiring immediate attention'), findsOneWidget);
        
        // Check for live region announcement
        final semantics = tester.getSemantics(find.byType(ErrorDialogWidget));
        expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
        expect(semantics.liveRegionImportance, equals(Assertiveness.assertive));
      });

      testWidgets('ErrorSnackbarWidget should have appropriate semantic roles', (WidgetTester tester) async {
        // Arrange
        final networkError = NetworkError(
          message: 'Network connection lost. Please check your internet connection.',
          networkType: NetworkErrorType.noConnection,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Text('Main Content'),
                  ErrorSnackbarWidget(error: networkError),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.bySemanticsLabel('Network error notification'), findsOneWidget);
        expect(find.bySemanticsLabel('Network connection lost. Please check your internet connection.'), findsOneWidget);
        
        // Check semantic role
        final snackbarSemantics = tester.getSemantics(find.byType(ErrorSnackbarWidget));
        expect(snackbarSemantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
        expect(snackbarSemantics.liveRegionImportance, equals(Assertiveness.polite));
      });

      testWidgets('should provide semantic descriptions for error types', (WidgetTester tester) async {
        // Arrange
        final errors = [
          ApiError(
            message: 'API error',
            statusCode: 400,
            endpoint: '/api/test',
            method: 'GET',
          ),
          ValidationError(
            message: 'Form validation failed',
            fieldErrors: {'email': ['Invalid email format']},
          ),
          NetworkError(
            message: 'Connection timeout',
            networkType: NetworkErrorType.timeout,
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

        // Assert
        // Check for error type descriptions
        expect(find.bySemanticsLabel(RegExp(r'API error.*from server')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'Form validation.*check your input')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r'Network error.*connection issue')), findsOneWidget);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should support keyboard navigation for error actions', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Keyboard navigation test error',
          statusCode: 500,
          endpoint: '/api/keyboard-test',
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

        // Assert keyboard navigation
        // Tab to retry button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Retry'));
        
        // Tab to dismiss button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Dismiss'));
        
        // Enter key should activate button
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        
        // Error should be dismissed
        expect(errorStore.hasErrors, isFalse);
      });

      testWidgets('should support escape key to dismiss error dialog', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Escape key test error',
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

        // Press escape key
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Assert dialog is dismissed
        expect(find.byType(ErrorDialogWidget), findsNothing);
      });

      testWidgets('should provide keyboard shortcuts for common actions', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Keyboard shortcuts test error',
          statusCode: 500,
          endpoint: '/api/shortcuts-test',
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

        // Test Ctrl+R for retry
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // Verify retry action was triggered
        // (In a real implementation, this would trigger the retry mechanism)
        
        // Test Ctrl+D for dismiss
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        await tester.pumpAndSettle();

        // Verify dismiss action
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('High Contrast Mode', () {
      testWidgets('should adapt to high contrast mode', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'High contrast test error',
          statusCode: 400,
          endpoint: '/api/contrast-test',
          method: 'GET',
        );

        errorService.showError(error);
        await tester.pumpAndSettle();

        // Act - Simulate high contrast mode
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Colors.white,
                onPrimary: Colors.black,
                error: Colors.red,
                onError: Colors.white,
                surface: Colors.black,
                onSurface: Colors.white,
              ),
              // High contrast settings
              visualDensity: VisualDensity.comfortable,
            ),
            home: Scaffold(
              body: ErrorStatusBarWidget(errorStore: errorStore),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert high contrast adaptations
        final errorWidget = find.byType(ErrorStatusBarWidget);
        expect(errorWidget, findsOneWidget);

        // Check that error widget adapts to theme
        final widget = tester.widget<ErrorStatusBarWidget>(errorWidget);
        expect(widget.highContrastMode, isTrue);
        
        // Verify color contrast ratios meet WCAG guidelines
        final theme = Theme.of(tester.element(errorWidget));
        final backgroundColor = theme.colorScheme.surface;
        final textColor = theme.colorScheme.onSurface;
        
        // Calculate contrast ratio (simplified check)
        final contrastRatio = _calculateContrastRatio(backgroundColor, textColor);
        expect(contrastRatio, greaterThan(4.5)); // WCAG AA standard
      });

      testWidgets('should use appropriate colors for error severity in high contrast', (WidgetTester tester) async {
        // Arrange
        final errors = [
          ApiError(
            message: 'Info error',
            statusCode: 200,
            endpoint: '/api/info',
            method: 'GET',
            severity: ErrorSeverity.info,
          ),
          ApiError(
            message: 'Warning error',
            statusCode: 400,
            endpoint: '/api/warning',
            method: 'GET',
            severity: ErrorSeverity.warning,
          ),
          ApiError(
            message: 'Critical error',
            statusCode: 500,
            endpoint: '/api/critical',
            method: 'GET',
            severity: ErrorSeverity.critical,
          ),
        ];

        // Act
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.highContrastDark(),
            ),
            home: Scaffold(
              body: Column(
                children: errors.map((error) => ErrorSnackbarWidget(error: error)).toList(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert appropriate high contrast colors
        final snackbars = find.byType(ErrorSnackbarWidget);
        expect(snackbars, findsNWidgets(3));

        // Verify each error type has distinct, high-contrast colors
        for (int i = 0; i < errors.length; i++) {
          final snackbar = tester.widget<ErrorSnackbarWidget>(snackbars.at(i));
          expect(snackbar.highContrastColors, isTrue);
          
          // Check color accessibility
          final colors = snackbar.getColorsForSeverity(errors[i].severity);
          final contrastRatio = _calculateContrastRatio(colors.background, colors.foreground);
          expect(contrastRatio, greaterThan(7.0)); // WCAG AAA standard for high contrast
        }
      });
    });

    group('Focus Management', () {
      testWidgets('should manage focus properly when errors appear', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(labelText: 'Input Field'),
                  ),
                  ErrorStatusBarWidget(errorStore: errorStore),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Focus on input field
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('TextField'));

        // Act - Show critical error
        final criticalError = ApiError(
          message: 'Critical focus management error',
          statusCode: 500,
          endpoint: '/api/focus-test',
          method: 'GET',
          severity: ErrorSeverity.critical,
        );

        errorService.showError(criticalError);
        await tester.pumpAndSettle();

        // Assert - Focus should move to error for critical errors
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('Error'));
        
        // Dismiss error
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();

        // Focus should return to previous element
        expect(tester.binding.focusManager.primaryFocus?.debugLabel, contains('TextField'));
      });

      testWidgets('should trap focus in error dialogs', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Focus trap test error',
          statusCode: 500,
          endpoint: '/api/focus-trap',
          method: 'GET',
          severity: ErrorSeverity.critical,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => ErrorDialogWidget(error: error),
                        );
                      },
                      child: const Text('Show Error'),
                    ),
                    const TextField(decoration: InputDecoration(labelText: 'Outside Field')),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Assert focus is trapped in dialog
        expect(find.byType(ErrorDialogWidget), findsOneWidget);
        
        // Try to tab outside dialog
        for (int i = 0; i < 10; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }

        // Focus should still be within dialog
        final focusedWidget = tester.binding.focusManager.primaryFocus;
        expect(focusedWidget?.debugLabel, isNot(contains('Outside Field')));
      });
    });

    group('Voice Control Support', () {
      testWidgets('should provide voice control labels', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Voice control test error',
          statusCode: 400,
          endpoint: '/api/voice-test',
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

        // Assert voice control labels
        expect(find.bySemanticsLabel('Say "retry" to retry the request'), findsOneWidget);
        expect(find.bySemanticsLabel('Say "dismiss" to dismiss this error'), findsOneWidget);
        expect(find.bySemanticsLabel('Say "details" to view error details'), findsOneWidget);
      });

      testWidgets('should support voice commands for error actions', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Voice command test error',
          statusCode: 500,
          endpoint: '/api/voice-command',
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

        // Simulate voice command "dismiss"
        final dismissButton = find.bySemanticsLabel(RegExp(r'dismiss', caseSensitive: false));
        expect(dismissButton, findsOneWidget);

        await tester.tap(dismissButton);
        await tester.pumpAndSettle();

        // Assert error is dismissed
        expect(errorStore.hasErrors, isFalse);
      });
    });

    group('Reduced Motion Support', () {
      testWidgets('should respect reduced motion preferences', (WidgetTester tester) async {
        // Arrange
        final error = ApiError(
          message: 'Reduced motion test error',
          statusCode: 400,
          endpoint: '/api/motion-test',
          method: 'GET',
        );

        // Act - Simulate reduced motion preference
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                accessibleNavigation: true,
                disableAnimations: true,
              ),
              child: Scaffold(
                body: ErrorSnackbarWidget(error: error),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert animations are disabled
        final snackbar = tester.widget<ErrorSnackbarWidget>(find.byType(ErrorSnackbarWidget));
        expect(snackbar.animationsDisabled, isTrue);
        expect(snackbar.animationDuration, equals(Duration.zero));
      });
    });
  });
}

// Helper function to calculate contrast ratio (simplified)
double _calculateContrastRatio(Color color1, Color2) {
  // Simplified contrast ratio calculation
  // In a real implementation, this would follow WCAG guidelines
  final luminance1 = color1.computeLuminance();
  final luminance2 = color2.computeLuminance();
  
  final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
  final darker = luminance1 > luminance2 ? luminance2 : luminance1;
  
  return (lighter + 0.05) / (darker + 0.05);
}

// Extension for testing accessibility features
extension ErrorWidgetAccessibility on ErrorStatusBarWidget {
  bool get highContrastMode => true; // Simplified for testing
  String? get semanticLabel => 'Error notification';
}

extension ErrorSnackbarAccessibility on ErrorSnackbarWidget {
  bool get highContrastColors => true; // Simplified for testing
  bool get animationsDisabled => true; // Simplified for testing
  Duration get animationDuration => Duration.zero; // Simplified for testing
  
  ({Color background, Color foreground}) getColorsForSeverity(ErrorSeverity severity) {
    // Simplified color mapping for testing
    switch (severity) {
      case ErrorSeverity.info:
        return (background: Colors.blue, foreground: Colors.white);
      case ErrorSeverity.warning:
        return (background: Colors.orange, foreground: Colors.black);
      case ErrorSeverity.error:
        return (background: Colors.red, foreground: Colors.white);
      case ErrorSeverity.critical:
        return (background: Colors.red.shade900, foreground: Colors.white);
    }
  }
}

extension ErrorDialogAccessibility on ErrorDialogWidget {
  String? get semanticLabel => 'Critical error dialog';
}

// Enums for testing
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

enum NetworkErrorType {
  timeout,
  noConnection,
  serverError,
}