import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:data/websocket/websocket.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppLifecycleManager - Basic Tests', () {
    late AppLifecycleManager lifecycleManager;
    late TestWebSocketService testWebSocketService;
    late TestMissedUpdateSynchronizer testSynchronizer;

    setUp(() {
      testWebSocketService = TestWebSocketService();
      testSynchronizer = TestMissedUpdateSynchronizer();
      
      lifecycleManager = AppLifecycleManager(
        testWebSocketService,
        testSynchronizer,
        hasActiveSubscriptionsCallback: () => true,
      );
    });

    tearDown(() {
      lifecycleManager.dispose();
    });

    test('should initialize correctly', () {
      expect(lifecycleManager.currentState, isNull);
      expect(lifecycleManager.backgroundTime, isNull);
      
      final stats = lifecycleManager.getStats();
      expect(stats.isManaging, isTrue);
    });

    test('should emit lifecycle events', () async {
      final events = <AppLifecycleEvent>[];
      lifecycleManager.lifecycleEvents.listen(events.add);

      lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
      
      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 600));
      
      expect(events, hasLength(1));
      expect(events.first.currentState, AppLifecycleState.paused);
    });

    test('should handle app pause', () async {
      // First connect the service
      await testWebSocketService.connect();
      
      lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
      
      // Wait for debounce
      await Future.delayed(const Duration(milliseconds: 600));
      
      expect(testWebSocketService.disconnectCalled, isTrue);
      expect(lifecycleManager.backgroundTime, isNotNull);
    });

    test('should handle app resume', () async {
      // First connect and then pause
      await testWebSocketService.connect();
      lifecycleManager.simulateLifecycleChange(AppLifecycleState.paused);
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Reset the flag to test resume
      testWebSocketService.connectCalled = false;
      
      // Then resume
      lifecycleManager.simulateLifecycleChange(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 600));
      
      expect(testWebSocketService.connectCalled, isTrue);
      expect(lifecycleManager.backgroundTime, isNull);
    });

    test('should provide statistics', () {
      final stats = lifecycleManager.getStats();
      expect(stats.isManaging, isTrue);
      expect(stats.currentState, isNull);
      expect(stats.backgroundTime, isNull);
    });

    test('should dispose properly', () {
      lifecycleManager.dispose();
      
      final stats = lifecycleManager.getStats();
      expect(stats.isManaging, isFalse);
    });
  });
}

class TestWebSocketService implements IWebSocketService {
  final StreamController<WebSocketConnectionState> _stateController = 
      StreamController<WebSocketConnectionState>.broadcast();
  
  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;
  bool connectCalled = false;
  bool disconnectCalled = false;

  @override
  Stream<WebSocketConnectionState> get connectionState => _stateController.stream;

  @override
  WebSocketConnectionState get currentState => _currentState;

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
    _stateController.close();
  }
}

class TestMissedUpdateSynchronizer implements MissedUpdateSynchronizer {
  final StreamController<SynchronizationEvent> _eventController = 
      StreamController<SynchronizationEvent>.broadcast();
  
  bool _isSynchronizing = false;

  @override
  Stream<SynchronizationEvent> get synchronizationEvents => _eventController.stream;

  @override
  bool get isSynchronizing => _isSynchronizing;

  @override
  Future<SynchronizationResult> synchronizeMissedUpdates({
    required DateTime backgroundTime,
    required DateTime resumeTime,
  }) async {
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
    _isSynchronizing = true;
    
    await Future.delayed(const Duration(milliseconds: 200));
    
    _isSynchronizing = false;
    return SynchronizationResult.fullRefresh(
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _eventController.close();
  }
}