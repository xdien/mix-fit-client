import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/services/error_service_interface.dart';
import 'package:core/error/services/network_monitor.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/models/error_severity.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';
import '../../../lib/presentation/widgets/app_layout.dart';

// Mock classes
class MockErrorService extends Mock implements IErrorService {}
class MockNetworkMonitor extends Mock implements NetworkMonitor {}

void main() {
  group('AppLayout', () {
    late ErrorStore errorStore;
    late MockErrorService mockErrorService;
    late MockNetworkMonitor mockNetworkMonitor;

    setUp(() {
      // Reset GetIt
      GetIt.instance.reset();

      // Create mocks
      mockErrorService = MockErrorService();
      mockNetworkMonitor = MockNetworkMonitor();

      // Create error store with mocks
      errorStore = ErrorStore(mockErrorService, mockNetworkMonitor);

      // Register in GetIt
      GetIt.instance.registerSingleton<ErrorStore>(errorStore);

      // Setup mock defaults
      when(mockErrorService.hasErrors).thenReturn(false);
      when(mockErrorService.activeErrors).thenReturn([]);
      when(mockErrorService.currentError).thenReturn(null);
      when(mockNetworkMonitor.isOffline).thenReturn(false);
    });

    tearDown(() {
      GetIt.instance.reset();
      errorStore.dispose();
    });

    group('Layout Structure', () {
      testWidgets('should render child widget', (WidgetTester tester) async {
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
        expect(find.text('Test Drawer'), findsOneWidget);
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
      testWidgets('should not show error bar when no errors', (WidgetTester tester) async {
        // Arrange
        errorStore.hideErrorBar();

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

      testWidgets('should show error bar when errors exist', (WidgetTester tester) async {
        // Arrange
        final testError = ApiError(
          message: 'Test error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
        );
        
        // Simulate error state
        errorStore.showErrorBar();
        when(mockErrorService.hasErrors).thenReturn(true);
        when(mockErrorService.activeErrors).thenReturn([testError]);
        when(mockErrorService.currentError).thenReturn(testError);

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
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });

      testWidgets('should show error bar when offline', (WidgetTester tester) async {
        // Arrange
        errorStore.showErrorBar();
        when(mockNetworkMonitor.isOffline).thenReturn(true);

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
        expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      });

      testWidgets('should animate error bar height changes', (WidgetTester tester) async {
        // Arrange
        errorStore.showErrorBar();
        errorStore.expandErrorBar();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Text('Test Content'),
            ),
          ),
        );
        await tester.pump();

        // Get initial height
        final expandedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(expandedContainer.height, equals(56.0));

        // Minimize error bar
        errorStore.minimizeErrorBar();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150)); // Mid-animation

        // Check that animation is in progress
        final animatingContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(animatingContainer.height, equals(32.0));

        // Complete animation
        await tester.pumpAndSettle();

        // Verify final state
        final minimizedContainer = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        expect(minimizedContainer.height, equals(32.0));
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
                  return Text('Mobile: ${context.isMobile}');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Mobile: true'), findsOneWidget);

        // Test tablet layout
        await tester.binding.setSurfaceSize(const Size(800, 600));
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Builder(
                builder: (context) {
                  return Text('Tablet: ${context.isTablet}');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Tablet: true'), findsOneWidget);

        // Test desktop layout
        await tester.binding.setSurfaceSize(const Size(1400, 900));
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Builder(
                builder: (context) {
                  return Text('Desktop: ${context.isDesktop}');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Desktop: true'), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Error Bar Styling', () {
      testWidgets('should apply correct background color for critical errors', (WidgetTester tester) async {
        // Arrange
        final criticalError = ApiError(
          message: 'Critical error',
          statusCode: 500,
          endpoint: '/test',
          method: 'GET',
          severity: ErrorSeverity.critical,
        );
        
        errorStore.showErrorBar();
        when(mockErrorService.hasErrors).thenReturn(true);
        when(mockErrorService.activeErrors).thenReturn([criticalError]);
        when(mockErrorService.currentError).thenReturn(criticalError);

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
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedContainer),
            matching: find.byType(Container),
          ).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.red.shade100));
      });

      testWidgets('should apply correct background color for offline state', (WidgetTester tester) async {
        // Arrange
        errorStore.showErrorBar();
        when(mockNetworkMonitor.isOffline).thenReturn(true);
        when(mockErrorService.hasErrors).thenReturn(false);

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
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedContainer),
            matching: find.byType(Container),
          ).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, equals(Colors.grey.shade200));
      });

      testWidgets('should include shadow in error bar styling', (WidgetTester tester) async {
        // Arrange
        errorStore.showErrorBar();

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
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AnimatedContainer),
            matching: find.byType(Container),
          ).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, equals(1));
        expect(decoration.boxShadow!.first.color, equals(Colors.black.withOpacity(0.1)));
      });
    });

    group('Layout Behavior', () {
      testWidgets('should expand main content when error bar is hidden', (WidgetTester tester) async {
        // Arrange
        errorStore.hideErrorBar();

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: AppLayout(
              child: Container(
                key: const Key('main-content'),
                child: Text('Test Content'),
              ),
            ),
          ),
        );
        await tester.pump();

        // Assert
        final expanded = tester.widget<Expanded>(
          find.ancestor(
            of: find.byKey(const Key('main-content')),
            matching: find.byType(Expanded),
          ),
        );
        expect(expanded, isNotNull);
      });

      testWidgets('should maintain proper column layout', (WidgetTester tester) async {
        // Arrange
        errorStore.showErrorBar();

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
        expect(find.byType(Column), findsOneWidget);
        
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.children.length, equals(2)); // Error bar + Expanded content
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

    testWidgets('should fallback to mobile when tablet/desktop not provided', (WidgetTester tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Text('Mobile Layout'),
          ),
        ),
      );

      // Assert
      expect(find.text('Mobile Layout'), findsOneWidget);

      // Reset
      await tester.binding.setSurfaceSize(null);
    });
  });
}