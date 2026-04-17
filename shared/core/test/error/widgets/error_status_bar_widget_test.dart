import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mobx/mobx.dart' as mobx;

import 'package:core/error/models/app_error.dart';
import 'package:core/error/models/error_action.dart';
import 'package:core/error/models/error_severity.dart';
import 'package:core/error/models/error_type.dart';
import 'package:core/error/models/network_status.dart';
import 'package:core/error/models/api_error.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';

import 'error_status_bar_widget_test.mocks.dart';

@GenerateMocks([ErrorStore])
void main() {
  group('ErrorStatusBarWidget', () {
    late MockErrorStore mockErrorStore;
    late Widget testWidget;

    setUp(() {
      mockErrorStore = MockErrorStore();
      
      // Setup default mock behavior
      when(mockErrorStore.shouldShowErrorBar).thenReturn(true);
      when(mockErrorStore.hasErrors).thenReturn(false);
      when(mockErrorStore.hasNetworkIssues).thenReturn(false);
      when(mockErrorStore.isOffline).thenReturn(false);
      when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.good);
      when(mockErrorStore.errorBarTitle).thenReturn('');
      when(mockErrorStore.networkStatusText).thenReturn('Good connection');
      when(mockErrorStore.priorityError).thenReturn(null);
      when(mockErrorStore.canRetryCurrentError).thenReturn(false);
      when(mockErrorStore.showNetworkStatusInBar).thenReturn(true);
      when(mockErrorStore.showErrorDetailsFlag).thenReturn(false);
      when(mockErrorStore.networkStatus).thenReturn(null);
    });

    Widget createTestWidget({
      bool showDetails = true,
      bool isMinimized = false,
      VoidCallback? onTap,
      VoidCallback? onMinimize,
      VoidCallback? onExpand,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorStatusBarWidget(
            errorStore: mockErrorStore,
            showDetails: showDetails,
            isMinimized: isMinimized,
            onTap: onTap,
            onMinimize: onMinimize,
            onExpand: onExpand,
          ),
        ),
      );
    }

    testWidgets('should not render when shouldShowErrorBar is false', (tester) async {
      when(mockErrorStore.shouldShowErrorBar).thenReturn(false);
      
      await tester.pumpWidget(createTestWidget());
      
      expect(find.byType(ErrorStatusBarWidget), findsOneWidget);
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Material), findsNothing);
    });

    testWidgets('should render minimized content when isMinimized is true', (tester) async {
      when(mockErrorStore.errorBarTitle).thenReturn('Test Error');
      
      await tester.pumpWidget(createTestWidget(isMinimized: true));
      await tester.pump();
      
      expect(find.text('Test Error'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing); // No expand button without callback
    });

    testWidgets('should render expand button in minimized mode when onExpand is provided', (tester) async {
      when(mockErrorStore.errorBarTitle).thenReturn('Test Error');
      bool expandCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        isMinimized: true,
        onExpand: () => expandCalled = true,
      ));
      await tester.pump();
      
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.expand_more));
      expect(expandCalled, isTrue);
    });

    testWidgets('should render full content when not minimized', (tester) async {
      when(mockErrorStore.errorBarTitle).thenReturn('Test Error');
      
      await tester.pumpWidget(createTestWidget(isMinimized: false));
      await tester.pump();
      
      expect(find.text('Test Error'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
    });

    group('Error States', () {
      testWidgets('should display critical error with correct styling', (tester) async {
        final criticalError = ApiError(
          message: 'Critical API Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          actions: [
            ErrorAction.retry(() {}),
            ErrorAction.dismiss(() {}),
          ],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(criticalError);
        when(mockErrorStore.errorBarTitle).thenReturn('Critical API Error');
        when(mockErrorStore.canRetryCurrentError).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.text('Critical API Error'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should display warning error with correct styling', (tester) async {
        final warningError = ApiError(
          message: 'Warning API Error',
          statusCode: 400,
          endpoint: '/api/test',
          method: 'POST',
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(warningError);
        when(mockErrorStore.errorBarTitle).thenReturn('Warning API Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.text('Warning API Error'), findsOneWidget);
        expect(find.byIcon(Icons.info), findsOneWidget);
      });

      testWidgets('should display info error with correct styling', (tester) async {
        final infoError = ApiError(
          message: 'Info API Error',
          statusCode: 200,
          endpoint: '/api/test',
          method: 'GET',
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(infoError);
        when(mockErrorStore.errorBarTitle).thenReturn('Info API Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.text('Info API Error'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });
    });

    group('Network States', () {
      testWidgets('should display offline indicator when offline', (tester) async {
        when(mockErrorStore.isOffline).thenReturn(true);
        when(mockErrorStore.hasNetworkIssues).thenReturn(true);
        when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.offline);
        when(mockErrorStore.errorBarTitle).thenReturn('No internet connection');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.text('No internet connection'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off), findsAtLeastNWidgets(1));
      });

      testWidgets('should display poor connection indicator', (tester) async {
        when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.poor);
        when(mockErrorStore.hasNetworkIssues).thenReturn(true);
        when(mockErrorStore.errorBarTitle).thenReturn('Poor network connection');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.text('Poor network connection'), findsOneWidget);
        expect(find.byIcon(Icons.signal_wifi_bad), findsOneWidget);
        expect(find.byIcon(Icons.network_wifi_1_bar), findsOneWidget);
      });

      testWidgets('should display excellent connection indicator', (tester) async {
        when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.excellent);
        when(mockErrorStore.errorBarTitle).thenReturn('All systems normal');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.signal_wifi_4_bar), findsOneWidget);
      });

      testWidgets('should hide network indicator when showNetworkStatusInBar is false', (tester) async {
        when(mockErrorStore.showNetworkStatusInBar).thenReturn(false);
        when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.excellent);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byIcon(Icons.signal_wifi_4_bar), findsNothing);
      });
    });

    group('Action Buttons', () {
      testWidgets('should display retry button when error can be retried', (tester) async {
        final retryableError = ApiError(
          message: 'Retryable Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          actions: [ErrorAction.retry(() {})],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(retryableError);
        when(mockErrorStore.canRetryCurrentError).thenReturn(true);
        when(mockErrorStore.errorBarTitle).thenReturn('Retryable Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should display dismiss button when error can be dismissed', (tester) async {
        final dismissibleError = ApiError(
          message: 'Dismissible Error',
          statusCode: 400,
          endpoint: '/api/test',
          method: 'GET',
          actions: [ErrorAction.dismiss(() {})],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(dismissibleError);
        when(mockErrorStore.errorBarTitle).thenReturn('Dismissible Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should display details button when error has details action', (tester) async {
        final detailsError = ApiError(
          message: 'Error with Details',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          actions: [ErrorAction.details(() {})],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(detailsError);
        when(mockErrorStore.errorBarTitle).thenReturn('Error with Details');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      });

      testWidgets('should display minimize button when onMinimize is provided', (tester) async {
        bool minimizeCalled = false;
        
        await tester.pumpWidget(createTestWidget(
          onMinimize: () => minimizeCalled = true,
        ));
        await tester.pump();
        
        expect(find.byIcon(Icons.expand_less), findsOneWidget);
        
        await tester.tap(find.byIcon(Icons.expand_less));
        expect(minimizeCalled, isTrue);
      });

      testWidgets('should call action callbacks when buttons are tapped', (tester) async {
        bool retryCalled = false;
        bool dismissCalled = false;
        bool detailsCalled = false;
        
        final actionError = ApiError(
          message: 'Action Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          actions: [
            ErrorAction.retry(() => retryCalled = true),
            ErrorAction.dismiss(() => dismissCalled = true),
            ErrorAction.details(() => detailsCalled = true),
          ],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(actionError);
        when(mockErrorStore.canRetryCurrentError).thenReturn(true);
        when(mockErrorStore.errorBarTitle).thenReturn('Action Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        await tester.tap(find.byIcon(Icons.refresh));
        expect(retryCalled, isTrue);
        
        await tester.tap(find.byIcon(Icons.close));
        expect(dismissCalled, isTrue);
        
        await tester.tap(find.byIcon(Icons.info_outline));
        expect(detailsCalled, isTrue);
      });
    });

    group('Details Section', () {
      testWidgets('should show details section when showDetails is true and showErrorDetailsFlag is true', (tester) async {
        final errorWithMetadata = ApiError(
          message: 'Error with Metadata',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(errorWithMetadata);
        when(mockErrorStore.errorBarTitle).thenReturn('Error with Metadata');
        when(mockErrorStore.showErrorDetailsFlag).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget(showDetails: true));
        await tester.pump();
        
        expect(find.text('Type: api (critical)'), findsOneWidget);
        expect(find.textContaining('statusCode: 500'), findsOneWidget);
        expect(find.textContaining('endpoint: /api/test'), findsOneWidget);
      });

      testWidgets('should show network details when network status is available', (tester) async {
        final networkStatus = NetworkStatus(
          isConnected: true,
          quality: NetworkQuality.good,
          latency: const Duration(milliseconds: 150),
          lastChecked: DateTime.now().subtract(const Duration(minutes: 2)),
        );
        
        when(mockErrorStore.networkStatus).thenReturn(networkStatus);
        when(mockErrorStore.showErrorDetailsFlag).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget(showDetails: true));
        await tester.pump();
        
        expect(find.textContaining('Network latency: 150ms'), findsOneWidget);
        expect(find.textContaining('Network checked: 2 minutes ago'), findsOneWidget);
      });

      testWidgets('should not show details section when showDetails is false', (tester) async {
        final errorWithMetadata = ApiError(
          message: 'Error with Metadata',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(errorWithMetadata);
        when(mockErrorStore.showErrorDetailsFlag).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget(showDetails: false));
        await tester.pump();
        
        expect(find.text('Type: api (critical)'), findsNothing);
        expect(find.textContaining('statusCode: 500'), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for error states', (tester) async {
        final criticalError = ApiError(
          message: 'Critical Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(criticalError);
        when(mockErrorStore.errorBarTitle).thenReturn('Critical Error');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(
          find.bySemanticsLabel('Error status bar: critical error - Critical Error'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('critical error icon'),
          findsOneWidget,
        );
      });

      testWidgets('should have proper semantic labels for network states', (tester) async {
        when(mockErrorStore.isOffline).thenReturn(true);
        when(mockErrorStore.hasNetworkIssues).thenReturn(true);
        when(mockErrorStore.errorBarTitle).thenReturn('No internet connection');
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(
          find.bySemanticsLabel('Network status bar: Device is offline'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Offline icon'),
          findsOneWidget,
        );
      });

      testWidgets('should have proper semantic labels for action buttons', (tester) async {
        final actionError = ApiError(
          message: 'Action Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
          actions: [
            ErrorAction.retry(() {}),
            ErrorAction.dismiss(() {}),
          ],
        );
        
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(actionError);
        when(mockErrorStore.canRetryCurrentError).thenReturn(true);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.bySemanticsLabel('Retry action'), findsOneWidget);
        expect(find.bySemanticsLabel('Dismiss error'), findsOneWidget);
      });

      testWidgets('should have proper semantic labels for network quality', (tester) async {
        when(mockErrorStore.networkQuality).thenReturn(NetworkQuality.excellent);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(
          find.bySemanticsLabel('Network quality: Excellent connection'),
          findsOneWidget,
        );
      });
    });

    group('Animation and Styling', () {
      testWidgets('should use AnimatedContainer for smooth transitions', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        expect(find.byType(AnimatedContainer), findsOneWidget);
      });

      testWidgets('should show elevation when there are errors or network issues', (tester) async {
        when(mockErrorStore.hasErrors).thenReturn(true);
        when(mockErrorStore.priorityError).thenReturn(ApiError(
          message: 'Test Error',
          statusCode: 500,
          endpoint: '/api/test',
          method: 'GET',
        ));
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        final material = tester.widget<Material>(find.byType(Material));
        expect(material.elevation, equals(2.0));
      });

      testWidgets('should not show elevation when no errors or network issues', (tester) async {
        when(mockErrorStore.hasErrors).thenReturn(false);
        when(mockErrorStore.hasNetworkIssues).thenReturn(false);
        
        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        
        final material = tester.widget<Material>(find.byType(Material));
        expect(material.elevation, equals(0.0));
      });
    });
  });
}