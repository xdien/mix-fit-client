import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/services/error_service.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import '../../../lib/presentation/widgets/app_layout.dart';

void main() {
  group('AppLayout Integration Tests', () {
    late ErrorStore errorStore;
    late IErrorService errorService;
    late NetworkMonitor networkMonitor;

    setUp(() {
      // Reset GetIt
      GetIt.instance.reset();

      // Create real instances for integration testing
      networkMonitor = NetworkMonitor();
      errorService = ErrorService(networkMonitor: networkMonitor);
      errorStore = ErrorStore(errorService, networkMonitor);

      // Register in GetIt
      GetIt.instance.registerSingleton<NetworkMonitor>(networkMonitor);
      GetIt.instance.registerSingleton<IErrorService>(errorService);
      GetIt.instance.registerSingleton<ErrorStore>(errorStore);
    });

    tearDown(() {
      errorStore.dispose();
      errorService.dispose();
      networkMonitor.dispose();
      GetIt.instance.reset();
    });

    group('Basic Layout', () {
      testWidgets('should render child widget correctly', (WidgetTester tester) async {
        // Arrange
        const testChild = Text('Test Content');

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: testChild,
            ),
          ),
        );

        // Assert
        expect(find.text('Test Content'), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should include drawer when provided', (WidgetTester tester) async {
        // Arrange
        final testDrawer = Drawer(
          child: Text('Test Drawer'),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              drawer: testDrawer,
              child: Text('Test Content'),
            ),
          ),
        );

        // Assert
        expect(find.byType(Drawer), findsOneWidget);
      });

      testWidgets('should include appBar when provided', (WidgetTester tester) async {
        // Arrange
        final testAppBar = AppBar(
          title: Text('Test AppBar'),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              appBar: testAppBar,
              child: Text('Test Content'),
            ),
          ),
        );

        // Assert
        expect(find.byType(AppBar), findsOneWidget);
        expect(find.text('Test AppBar'), findsOneWidget);
      });
    });

    group('Error Status Bar Integration', () {
      testWidgets('should not show error bar initially', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsNothing);
      });

      testWidgets('should show error bar when error is added', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );
        await tester.pump();

        // Act - add an error
        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });

      testWidgets('should hide error bar when error is cleared', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);

        // Act - clear the error
        errorService.clearError(testError.id);
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsNothing);
      });

      testWidgets('should show error bar with proper layout', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        // Act - add an error
        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(AnimatedContainer), findsOneWidget);
        expect(find.byType(Expanded), findsOneWidget);
        
        // Verify the column has the correct children
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.children.length, equals(2)); // Error bar container + Expanded content
      });
    });

    group('Error Bar Visibility Control', () {
      testWidgets('should respect error bar visibility settings', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);

        // Act - hide error bar
        errorStore.hideErrorBar();
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsNothing);

        // Act - show error bar again
        errorStore.showErrorBar();
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });

      testWidgets('should handle minimize/expand states', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Act - minimize error bar
        errorStore.minimizeErrorBar();
        await tester.pump();

        // Assert - error bar should still be visible but minimized
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        expect(errorStore.isErrorBarMinimized, isTrue);

        // Act - expand error bar
        errorStore.expandErrorBar();
        await tester.pump();

        // Assert
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
        expect(errorStore.isErrorBarMinimized, isFalse);
      });
    });

    group('Responsive Design', () {
      testWidgets('should handle different screen sizes', (WidgetTester tester) async {
        // Test mobile layout
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Builder(
                builder: (context) {
                  return Text('Width: ${context.screenWidth}');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Width: 400'), findsOneWidget);

        // Test tablet layout
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Builder(
                builder: (context) {
                  return Text('Width: ${context.screenWidth}');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.textContaining('Width: 800'), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Error Bar Styling', () {
      testWidgets('should apply proper container styling', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert
        expect(find.byType(AnimatedContainer), findsOneWidget);
        
        final animatedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        expect(animatedContainer.duration, equals(const Duration(milliseconds: 300)));
        expect(animatedContainer.curve, equals(Curves.easeInOut));
      });

      testWidgets('should have proper shadow styling', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedContainer),
            matching: find.byType(Container),
          ).first,
        );
        
        expect(container.decoration, isA<BoxDecoration>());
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
      });
    });

    group('Layout Behavior', () {
      testWidgets('should maintain proper column structure', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Container(
                key: const Key('test-content'),
                child: Text('Test Content'),
              ),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert
        expect(find.byType(Column), findsOneWidget);
        
        // Verify main content is in an Expanded widget
        expect(
          find.ancestor(
            of: find.byKey(const Key('test-content')),
            matching: find.byType(Expanded),
          ),
          findsOneWidget,
        );
      });

      testWidgets('should handle content overflow properly', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Column(
                children: List.generate(
                  100,
                  (index) => Text('Item $index'),
                ),
              ),
            ),
          ),
        );

        final testError = ApiError(
          message: 'Test error message',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        errorService.showError(testError);
        await tester.pump();

        // Assert - should not throw overflow errors
        expect(tester.takeException(), isNull);
      });
    });
  });

  group('ResponsiveLayout', () {
    testWidgets('should show mobile layout on small screens', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(400, 800));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile Layout'),
            tablet: Text('Tablet Layout'),
            desktop: Text('Desktop Layout'),
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsNothing);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show tablet layout on medium screens', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(800, 600));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile Layout'),
            tablet: Text('Tablet Layout'),
            desktop: Text('Desktop Layout'),
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsOneWidget);
      expect(find.text('Desktop Layout'), findsNothing);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('should show desktop layout on large screens', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile Layout'),
            tablet: Text('Tablet Layout'),
            desktop: Text('Desktop Layout'),
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsNothing);
      expect(find.text('Tablet Layout'), findsNothing);
      expect(find.text('Desktop Layout'), findsOneWidget);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });
}