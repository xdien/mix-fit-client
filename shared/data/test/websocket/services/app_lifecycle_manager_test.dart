import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/websocket.dart';

// Manual mocks
class MockIWebSocketService extends Mock implements IWebSocketService {
  @override
  Stream<WebSocketConnectionState> get connectionState => super.noSuchMethod(
    Invocation.getter(#connectionState),
    returnValue: const Stream.empty(),
    returnValueForMissingStub: const Stream.empty(),
  );

  @override
  WebSocketConnectionState get currentState => super.noSuchMethod(
    Invocation.getter(#currentState),
    returnValue: WebSocketConnectionState.disconnected,
    returnValueForMissingStub: WebSocketConnectionState.disconnected,
  );

  @override
  Future<void> connect() => super.noSuchMethod(
    Invocation.method(#connect, []),
    returnValue: Future.value(),
    returnValueForMissingStub: Future.value(),
  );

  @override
  Future<void> disconnect() => super.noSuchMethod(
    Invocation.method(#disconnect, []),
    returnValue: Future.value(),
    returnValueForMissingStub: Future.value(),
  );

  @override
  void subscribe(String channel, Function(dynamic) callback) => super.noSuchMethod(
    Invocation.method(#subscribe, [channel, callback]),
    returnValueForMissingStub: null,
  );

  @override
  void unsubscribe(String channel) => super.noSuchMethod(
    Invocation.method(#unsubscribe, [channel]),
    returnValueForMissingStub: null,
  );

  @override
  Future<void> handleAppLifecycle(AppLifecycleState state) => super.noSuchMethod(
    Invocation.method(#handleAppLifecycle, [state]),
    returnValue: Future.value(),
    returnValueForMissingStub: Future.value(),
  );

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );
}

class MockMissedUpdateSynchronizer extends Mock implements MissedUpdateSynchronizer {
  @override
  Stream<SynchronizationEvent> get synchronizationEvents => super.noSuchMethod(
    Invocation.getter(#synchronizationEvents),
    returnValue: const Stream.empty(),
  );

  @override
  bool get isSynchronizing => super.noSuchMethod(
    Invocation.getter(#isSynchronizing),
    returnValue: false,
  );

  @override
  Future<SynchronizationResult> synchronizeMissedUpdates({
    required DateTime backgroundTime,
    required DateTime resumeTime,
  }) => super.noSuchMethod(
    Invocation.method(#synchronizeMissedUpdates, [], {
      #backgroundTime: backgroundTime,
      #resumeTime: resumeTime,
    }),
    returnValue: Future.value(SynchronizationResult.success(
      updatesProcessed: 0,
      duration: Duration.zero,
      backgroundDuration: Duration.zero,
    )),
  );

  @override
  Future<SynchronizationResult> performFullDataRefresh() => super.noSuchMethod(
    Invocation.method(#performFullDataRefresh, []),
    returnValue: Future.value(SynchronizationResult.fullRefresh(duration: Duration.zero)),
  );

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
  );
}
void main() {
  group('AppLifecycleManager', () {
    late MockIWebSocketService mockWebSocketService;
    late MockMissedUpdateSynchronizer mockSynchronizer;
    late AppLifecycleManager lifecycleManager;
    late StreamController<WebSocketConnectionState> connectionStateController;
    
    bool hasActiveSubscriptions = true;

    setUp(() {
      mockWebSocketService = MockIWebSocketService();
      mockSynchronizer = MockMissedUpdateSynchronizer();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
      
      // Setup mock behavior
      when(mockWebSocketService.connectionState).thenAnswer((_) => connectionStateController.stream);
      when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
      when(mockWebSocketService.connect()).thenAnswer((_) async {});
      when(mockWebSocketService.disconnect()).thenAnswer((_) async {});
      // Setup default behavior for any DateTime values
      when(mockSynchronizer.synchronizeMissedUpdates(
        backgroundTime: any,
        resumeTime: any,
      )).thenAnswer((_) async => SynchronizationResult.success(
        updatesProcessed: 5,
        duration: const Duration(seconds: 1),
        backgroundDuration: const Duration(minutes: 2),
      ));
      when(mockSynchronizer.performFullDataRefresh()).thenAnswer((_) async => SynchronizationResult.fullRefresh(
        duration: const Duration(seconds: 2),
      ));
      
      lifecycleManager = AppLifecycleManager(
        mockWebSocketService,
        mockSynchronizer,
        hasActiveSubscriptionsCallback: () => hasActiveSubscriptions,
      );
    });

    tearDown(() {
      lifecycleManager.dispose();
      connectionStateController.close();
    });

    group('Initialization', () {
      test('should initialize with correct initial state', () {
        expect(lifecycleManager.currentState, isNull);
        expect(lifecycleManager.backgroundTime, isNull);
        
        final stats = lifecycleManager.getStats();
        expect(stats.isManaging, isTrue);
        expect(stats.currentState, isNull);
        expect(stats.backgroundTime, isNull);
      });

      test('should emit lifecycle events', () {
        final events = <AppLifecycleEvent>[];
        lifecycleManager.lifecycleEvents.listen(events.add);

        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for debounce
        return Future.delayed(const Duration(milliseconds: 600)).then((_) {
          expect(events, hasLength(1));
          expect(events.first.currentState, AppLifecycleState.paused);
          expect(events.first.previousState, isNull);
        });
      });
    });

    group('App Paused', () {
      test('should disconnect WebSocket when app is paused', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));
        
        verify(mockWebSocketService.disconnect()).called(1);
        expect(lifecycleManager.backgroundTime, isNotNull);
      });

      test('should not disconnect if already disconnected', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));
        
        verify(mockWebSocketService.disconnect()).called(1); // Still called for safety
        expect(lifecycleManager.backgroundTime, isNotNull);
      });
    });

    group('App Detached', () {
      test('should disconnect WebSocket when app is detached', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.detached);
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));
        
        verify(mockWebSocketService.disconnect()).called(1);
        expect(lifecycleManager.backgroundTime, isNotNull);
      });
    });

    group('App Resumed', () {
      test('should reconnect WebSocket when app is resumed with active subscriptions', () async {
        hasActiveSubscriptions = true;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        
        // First pause the app
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Then resume
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verify(mockWebSocketService.connect()).called(1);
      });

      test('should not reconnect if no active subscriptions', () async {
        hasActiveSubscriptions = false;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verifyNever(mockWebSocketService.connect());
      });

      test('should synchronize missed updates after significant background time', () async {
        hasActiveSubscriptions = true;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        
        // Simulate app going to background
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Wait for more than 1 minute (simulated)
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Resume app
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verify(mockWebSocketService.connect()).called(1);
        verify(mockSynchronizer.synchronizeMissedUpdates(
          backgroundTime: argThat(isA<DateTime>(), named: 'backgroundTime'),
          resumeTime: argThat(isA<DateTime>(), named: 'resumeTime'),
        )).called(1);
      });

      test('should clear background time after resume', () async {
        hasActiveSubscriptions = true;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        
        // Pause
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        expect(lifecycleManager.backgroundTime, isNotNull);
        
        // Resume
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        expect(lifecycleManager.backgroundTime, isNull);
      });
    });

    group('App Inactive', () {
      test('should not disconnect WebSocket when app is inactive', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.inactive);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verifyNever(mockWebSocketService.disconnect());
        expect(lifecycleManager.backgroundTime, isNull);
      });
    });

    group('App Hidden', () {
      test('should not disconnect WebSocket when app is hidden', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.hidden);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verifyNever(mockWebSocketService.disconnect());
        expect(lifecycleManager.backgroundTime, isNull);
      });
    });

    group('Debouncing', () {
      test('should debounce rapid state changes', () async {
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.connected);
        
        // Rapid state changes
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for debounce
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Should only process the last state change
        verify(mockWebSocketService.disconnect()).called(1);
        verifyNever(mockWebSocketService.connect());
      });
    });

    group('Error Handling', () {
      test('should handle connection errors gracefully', () async {
        hasActiveSubscriptions = true;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        when(mockWebSocketService.connect()).thenThrow(Exception('Connection failed'));
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Should not throw exception
        verify(mockWebSocketService.connect()).called(1);
      });

      test('should handle synchronization errors gracefully', () async {
        hasActiveSubscriptions = true;
        when(mockWebSocketService.currentState).thenReturn(WebSocketConnectionState.disconnected);
        when(mockSynchronizer.synchronizeMissedUpdates(
          backgroundTime: argThat(isA<DateTime>(), named: 'backgroundTime'),
          resumeTime: argThat(isA<DateTime>(), named: 'resumeTime'),
        )).thenThrow(Exception('Sync failed'));
        
        // Pause and resume
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Should not throw exception
        verify(mockWebSocketService.connect()).called(1);
      });
    });

    group('Statistics', () {
      test('should provide accurate statistics', () async {
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        
        final stats = lifecycleManager.getStats();
        expect(stats.currentState, AppLifecycleState.paused);
        expect(stats.backgroundTime, isNotNull);
        expect(stats.isManaging, isTrue);
        expect(stats.backgroundDuration, isNotNull);
      });
    });

    group('Disposal', () {
      test('should stop managing lifecycle after disposal', () async {
        lifecycleManager.dispose();
        
        final stats = lifecycleManager.getStats();
        expect(stats.isManaging, isFalse);
        
        // Should not process lifecycle changes after disposal
        lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
        await Future.delayed(const Duration(milliseconds: 600));
        
        verifyNever(mockWebSocketService.disconnect());
      });

      test('should close streams on disposal', () async {
        bool streamClosed = false;
        lifecycleManager.lifecycleEvents.listen(
          (_) {},
          onDone: () => streamClosed = true,
        );
        
        lifecycleManager.dispose();
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(streamClosed, isTrue);
      });
    });
  });
}