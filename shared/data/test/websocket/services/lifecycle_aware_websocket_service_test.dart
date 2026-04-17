import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:data/websocket/websocket.dart';

// Manual mocks
class MockWebSocketService extends Mock implements WebSocketService {
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
    returnValueForMissingStub: const Stream.empty(),
  );

  @override
  bool get isSynchronizing => super.noSuchMethod(
    Invocation.getter(#isSynchronizing),
    returnValue: false,
    returnValueForMissingStub: false,
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
    returnValueForMissingStub: Future.value(SynchronizationResult.success(
      updatesProcessed: 0,
      duration: Duration.zero,
      backgroundDuration: Duration.zero,
    )),
  );

  @override
  Future<SynchronizationResult> performFullDataRefresh() => super.noSuchMethod(
    Invocation.method(#performFullDataRefresh, []),
    returnValue: Future.value(SynchronizationResult.fullRefresh(duration: Duration.zero)),
    returnValueForMissingStub: Future.value(SynchronizationResult.fullRefresh(duration: Duration.zero)),
  );

  @override
  void dispose() => super.noSuchMethod(
    Invocation.method(#dispose, []),
    returnValueForMissingStub: null,
  );
}
void main() {
  group('LifecycleAwareWebSocketService', () {
    late MockWebSocketService mockBaseService;
    late MockMissedUpdateSynchronizer mockSynchronizer;
    late LifecycleAwareWebSocketService lifecycleAwareService;
    late StreamController<WebSocketConnectionState> connectionStateController;

    setUp(() {
      mockBaseService = MockWebSocketService();
      mockSynchronizer = MockMissedUpdateSynchronizer();
      connectionStateController = StreamController<WebSocketConnectionState>.broadcast();

      // Setup mock behavior
      when(mockBaseService.connectionState).thenAnswer((_) => connectionStateController.stream);
      when(mockBaseService.currentState).thenReturn(WebSocketConnectionState.disconnected);
      when(mockBaseService.connect()).thenAnswer((_) async {});
      when(mockBaseService.disconnect()).thenAnswer((_) async {});
      when(mockBaseService.subscribe(any, any)).thenReturn(null);
      when(mockBaseService.unsubscribe(any)).thenReturn(null);
      when(mockBaseService.dispose()).thenReturn(null);
      
      when(mockSynchronizer.synchronizationEvents).thenAnswer((_) => const Stream.empty());
      when(mockSynchronizer.isSynchronizing).thenReturn(false);
      when(mockSynchronizer.synchronizeMissedUpdates(
        backgroundTime: argThat(isA<DateTime>(), named: 'backgroundTime'),
        resumeTime: argThat(isA<DateTime>(), named: 'resumeTime'),
      )).thenAnswer((_) async => SynchronizationResult.success(
        updatesProcessed: 5,
        duration: const Duration(seconds: 1),
        backgroundDuration: const Duration(minutes: 2),
      ));
      when(mockSynchronizer.performFullDataRefresh()).thenAnswer((_) async => SynchronizationResult.fullRefresh(
        duration: const Duration(seconds: 2),
      ));

      lifecycleAwareService = LifecycleAwareWebSocketService(
        mockBaseService,
        missedUpdateSynchronizer: mockSynchronizer,
      );
    });

    tearDown(() {
      lifecycleAwareService.dispose();
      connectionStateController.close();
    });

    group('Initialization', () {
      test('should initialize with base service', () {
        expect(lifecycleAwareService.currentState, WebSocketConnectionState.disconnected);
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
        expect(lifecycleAwareService.isSynchronizing, isFalse);
      });

      test('should provide access to lifecycle events', () {
        expect(lifecycleAwareService.lifecycleEvents, isA<Stream<AppLifecycleEvent>>());
      });

      test('should provide access to synchronization events', () {
        expect(lifecycleAwareService.synchronizationEvents, isA<Stream<SynchronizationEvent>>());
      });
    });

    group('Connection Management', () {
      test('should delegate connect to base service', () async {
        await lifecycleAwareService.connect();
        verify(mockBaseService.connect()).called(1);
      });

      test('should delegate disconnect to base service', () async {
        await lifecycleAwareService.disconnect();
        verify(mockBaseService.disconnect()).called(1);
      });

      test('should not connect when disposed', () async {
        lifecycleAwareService.dispose();
        await lifecycleAwareService.connect();
        verifyNever(mockBaseService.connect());
      });
    });

    group('Subscription Management', () {
      test('should track active subscriptions', () {
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
        expect(lifecycleAwareService.getActiveChannels(), isEmpty);

        final callback = (data) {};
        lifecycleAwareService.subscribe('test-channel', callback);

        expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
        expect(lifecycleAwareService.getActiveChannels(), contains('test-channel'));
        verify(mockBaseService.subscribe('test-channel', callback)).called(1);
      });

      test('should remove subscriptions on unsubscribe', () {
        final callback = (data) {};
        lifecycleAwareService.subscribe('test-channel', callback);
        expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);

        lifecycleAwareService.unsubscribe('test-channel');
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
        expect(lifecycleAwareService.getActiveChannels(), isEmpty);
        verify(mockBaseService.unsubscribe('test-channel')).called(1);
      });

      test('should not subscribe when disposed', () {
        lifecycleAwareService.dispose();
        lifecycleAwareService.subscribe('test-channel', (data) {});
        
        verifyNever(mockBaseService.subscribe(any, any));
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      });

      test('should handle multiple subscriptions', () {
        lifecycleAwareService.subscribe('channel1', (data) {});
        lifecycleAwareService.subscribe('channel2', (data) {});
        lifecycleAwareService.subscribe('channel3', (data) {});

        expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
        expect(lifecycleAwareService.getActiveChannels(), hasLength(3));
        expect(lifecycleAwareService.getActiveChannels(), containsAll(['channel1', 'channel2', 'channel3']));
      });
    });

    group('Lifecycle Integration', () {
      test('should simulate lifecycle changes', () {
        final events = <AppLifecycleEvent>[];
        lifecycleAwareService.lifecycleEvents.listen(events.add);

        lifecycleAwareService.simulateLifecycleChange(AppLifecycleState.paused);
        
        // Wait for event processing
        return Future.delayed(const Duration(milliseconds: 600)).then((_) {
          expect(events, isNotEmpty);
          expect(events.first.currentState, AppLifecycleState.paused);
        });
      });

      test('should provide lifecycle statistics', () {
        final stats = lifecycleAwareService.lifecycleStats;
        expect(stats, isA<AppLifecycleStats>());
        expect(stats.isManaging, isTrue);
      });
    });

    group('Missed Update Synchronization', () {
      test('should synchronize missed updates', () async {
        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        final result = await lifecycleAwareService.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(result.isSuccess, isTrue);
        verify(mockSynchronizer.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        )).called(1);
      });

      test('should perform full data refresh', () async {
        final result = await lifecycleAwareService.performFullDataRefresh();

        expect(result.isSuccess, isTrue);
        verify(mockSynchronizer.performFullDataRefresh()).called(1);
      });

      test('should report synchronization status', () {
        when(mockSynchronizer.isSynchronizing).thenReturn(true);
        expect(lifecycleAwareService.isSynchronizing, isTrue);

        when(mockSynchronizer.isSynchronizing).thenReturn(false);
        expect(lifecycleAwareService.isSynchronizing, isFalse);
      });
    });

    group('Connection State Delegation', () {
      test('should delegate connection state stream', () {
        expect(lifecycleAwareService.connectionState, equals(mockBaseService.connectionState));
      });

      test('should delegate current state', () {
        when(mockBaseService.currentState).thenReturn(WebSocketConnectionState.connected);
        expect(lifecycleAwareService.currentState, WebSocketConnectionState.connected);

        when(mockBaseService.currentState).thenReturn(WebSocketConnectionState.error);
        expect(lifecycleAwareService.currentState, WebSocketConnectionState.error);
      });
    });

    group('App Lifecycle Handling', () {
      test('should handle app lifecycle automatically', () async {
        // The handleAppLifecycle method should delegate to the lifecycle manager
        await lifecycleAwareService.handleAppLifecycle(AppLifecycleState.paused);
        
        // Since it's handled automatically, this should not throw or cause issues
        expect(true, isTrue); // Test passes if no exception is thrown
      });
    });

    group('Default Implementations', () {
      test('should handle fetch missed updates with empty result', () async {
        // Test the default implementation by creating a service without custom synchronizer
        final defaultService = LifecycleAwareWebSocketService(mockBaseService);
        
        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        // This should not throw and should return a result
        final result = await defaultService.synchronizeMissedUpdates(
          backgroundTime: backgroundTime,
          resumeTime: resumeTime,
        );

        expect(result, isA<SynchronizationResult>());
        defaultService.dispose();
      });

      test('should handle full data refresh with default implementation', () async {
        final defaultService = LifecycleAwareWebSocketService(mockBaseService);
        
        // This should not throw and should return a result
        final result = await defaultService.performFullDataRefresh();

        expect(result, isA<SynchronizationResult>());
        defaultService.dispose();
      });
    });

    group('Error Handling', () {
      test('should handle synchronization errors gracefully', () async {
        when(mockSynchronizer.synchronizeMissedUpdates(
          backgroundTime: argThat(isA<DateTime>(), named: 'backgroundTime'),
          resumeTime: argThat(isA<DateTime>(), named: 'resumeTime'),
        )).thenThrow(Exception('Sync error'));

        final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
        final resumeTime = DateTime.now();

        expect(
          () => lifecycleAwareService.synchronizeMissedUpdates(
            backgroundTime: backgroundTime,
            resumeTime: resumeTime,
          ),
          throwsException,
        );
      });

      test('should handle full refresh errors gracefully', () async {
        when(mockSynchronizer.performFullDataRefresh()).thenThrow(Exception('Refresh error'));

        expect(
          () => lifecycleAwareService.performFullDataRefresh(),
          throwsException,
        );
      });
    });

    group('Disposal', () {
      test('should dispose all components', () {
        lifecycleAwareService.dispose();
        
        verify(mockBaseService.dispose()).called(1);
        verify(mockSynchronizer.dispose()).called(1);
        
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      });

      test('should handle multiple dispose calls', () {
        lifecycleAwareService.dispose();
        lifecycleAwareService.dispose(); // Should not throw
        
        verify(mockBaseService.dispose()).called(1); // Should only be called once
      });

      test('should clear active subscriptions on dispose', () {
        lifecycleAwareService.subscribe('test-channel', (data) {});
        expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
        
        lifecycleAwareService.dispose();
        expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
        expect(lifecycleAwareService.getActiveChannels(), isEmpty);
      });
    });
  });
}