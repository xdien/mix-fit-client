import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('LifecycleAwareWebSocketService - Basic Tests', () {
    late TestWebSocketService baseService;
    late TestMissedUpdateSynchronizer synchronizer;
    late LifecycleAwareWebSocketService lifecycleAwareService;

    setUp(() {
      baseService = TestWebSocketService();
      synchronizer = TestMissedUpdateSynchronizer();
      
      lifecycleAwareService = LifecycleAwareWebSocketService(
        baseService,
        missedUpdateSynchronizer: synchronizer,
      );
    });

    tearDown(() {
      lifecycleAwareService.dispose();
    });

    test('should initialize with base service', () {
      expect(lifecycleAwareService.currentState, WebSocketConnectionState.disconnected);
      expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      expect(lifecycleAwareService.isSynchronizing, isFalse);
    });

    test('should delegate connect to base service', () async {
      await lifecycleAwareService.connect();
      expect(baseService.connectCalled, isTrue);
    });

    test('should delegate disconnect to base service', () async {
      await lifecycleAwareService.disconnect();
      expect(baseService.disconnectCalled, isTrue);
    });

    test('should track active subscriptions', () {
      expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      expect(lifecycleAwareService.getActiveChannels(), isEmpty);

      final callback = (data) {};
      lifecycleAwareService.subscribe('test-channel', callback);

      expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
      expect(lifecycleAwareService.getActiveChannels(), contains('test-channel'));
    });

    test('should remove subscriptions on unsubscribe', () {
      final callback = (data) {};
      lifecycleAwareService.subscribe('test-channel', callback);
      expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);

      lifecycleAwareService.unsubscribe('test-channel');
      expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      expect(lifecycleAwareService.getActiveChannels(), isEmpty);
    });

    test('should handle multiple subscriptions', () {
      lifecycleAwareService.subscribe('channel1', (data) {});
      lifecycleAwareService.subscribe('channel2', (data) {});
      lifecycleAwareService.subscribe('channel3', (data) {});

      expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
      expect(lifecycleAwareService.getActiveChannels(), hasLength(3));
      expect(lifecycleAwareService.getActiveChannels(), containsAll(['channel1', 'channel2', 'channel3']));
    });

    test('should synchronize missed updates', () async {
      final backgroundTime = DateTime.now().subtract(const Duration(minutes: 5));
      final resumeTime = DateTime.now();

      final result = await lifecycleAwareService.synchronizeMissedUpdates(
        backgroundTime: backgroundTime,
        resumeTime: resumeTime,
      );

      expect(result.isSuccess, isTrue);
      expect(synchronizer.synchronizeCalled, isTrue);
    });

    test('should perform full data refresh', () async {
      final result = await lifecycleAwareService.performFullDataRefresh();

      expect(result.isSuccess, isTrue);
      expect(synchronizer.fullRefreshCalled, isTrue);
    });

    test('should provide lifecycle statistics', () {
      final stats = lifecycleAwareService.lifecycleStats;
      expect(stats, isA<AppLifecycleStats>());
      expect(stats.isManaging, isTrue);
    });

    test('should simulate lifecycle changes', () async {
      final events = <AppLifecycleEvent>[];
      lifecycleAwareService.lifecycleEvents.listen(events.add);

      lifecycleAwareService.simulateLifecycleChange(AppLifecycleState.paused);
      
      // Wait for event processing
      await Future.delayed(const Duration(milliseconds: 600));
      
      expect(events, isNotEmpty);
      expect(events.first.currentState, AppLifecycleState.paused);
    });

    test('should dispose all components', () {
      lifecycleAwareService.dispose();
      
      expect(baseService.disposeCalled, isTrue);
      expect(synchronizer.disposeCalled, isTrue);
      expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
    });

    test('should clear active subscriptions on dispose', () {
      lifecycleAwareService.subscribe('test-channel', (data) {});
      expect(lifecycleAwareService.hasActiveSubscriptions(), isTrue);
      
      lifecycleAwareService.dispose();
      expect(lifecycleAwareService.hasActiveSubscriptions(), isFalse);
      expect(lifecycleAwareService.getActiveChannels(), isEmpty);
    });
  });
}

class TestWebSocketService implements WebSocketService {
  final StreamController<WebSocketConnectionState> _stateController = 
      StreamController<WebSocketConnectionState>.broadcast();
  final StreamController<WebSocketError> _errorController = 
      StreamController<WebSocketError>.broadcast();
  
  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;
  WebSocketError? _lastError;
  bool connectCalled = false;
  bool disconnectCalled = false;
  bool disposeCalled = false;

  @override
  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;

  @override
  WebSocketConnectionState get currentState => _currentState;

  @override
  Stream<WebSocketError> get errorStream => _errorController.stream;

  @override
  WebSocketError? get lastError => _lastError;

  @override
  Future<void> connect() async {
    connectCalled = true;
    _currentState = WebSocketConnectionState.connected;
    _stateController.add(_currentState);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
    _currentState = WebSocketConnectionState.disconnected;
    _stateController.add(_currentState);
  }

  @override
  void subscribe(String channel, Function(dynamic) callback) {}

  @override
  void unsubscribe(String channel) {}

  @override
  Future<void> handleAppLifecycle(AppLifecycleState state) async {}

  @override
  void dispose() {
    disposeCalled = true;
    _stateController.close();
    _errorController.close();
  }
}

class TestMissedUpdateSynchronizer implements MissedUpdateSynchronizer {
  final StreamController<SynchronizationEvent> _eventController = 
      StreamController<SynchronizationEvent>.broadcast();
  
  bool _isSynchronizing = false;
  bool synchronizeCalled = false;
  bool fullRefreshCalled = false;
  bool disposeCalled = false;

  @override
  Stream<SynchronizationEvent> get synchronizationEvents => _eventController.stream;

  @override
  bool get isSynchronizing => _isSynchronizing;

  @override
  Future<SynchronizationResult> synchronizeMissedUpdates({
    required DateTime backgroundTime,
    required DateTime resumeTime,
  }) async {
    synchronizeCalled = true;
    _isSynchronizing = true;
    
    await Future.delayed(const Duration(milliseconds: 100));
    
    _isSynchronizing = false;
    return SynchronizationResult.success(
      updatesProcessed: 5,
      duration: const Duration(milliseconds: 100),
      backgroundDuration: resumeTime.difference(backgroundTime),
    );
  }

  @override
  Future<SynchronizationResult> performFullDataRefresh() async {
    fullRefreshCalled = true;
    _isSynchronizing = true;
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    _isSynchronizing = false;
    return SynchronizationResult.fullRefresh(
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    disposeCalled = true;
    _eventController.close();
  }
}