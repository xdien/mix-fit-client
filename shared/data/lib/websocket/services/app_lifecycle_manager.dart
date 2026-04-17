import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import 'missed_update_synchronizer.dart';

/// Manages WebSocket connections based on app lifecycle state changes
/// 
/// This class monitors app lifecycle events and automatically manages
/// WebSocket connections to preserve battery life and handle background/foreground
/// transitions gracefully.
class AppLifecycleManager with WidgetsBindingObserver {
  final IWebSocketService _webSocketService;
  final MissedUpdateSynchronizer _missedUpdateSynchronizer;
  final bool Function()? _hasActiveSubscriptionsCallback;
  
  AppLifecycleState? _previousState;
  DateTime? _backgroundTime;
  Timer? _debounceTimer;
  bool _isDisposed = false;
  
  // Configuration for lifecycle management
  static const Duration _debounceDelay = Duration(milliseconds: 500);
  static const Duration _maxBackgroundDuration = Duration(minutes: 30);
  
  final StreamController<AppLifecycleEvent> _lifecycleEventController =
      StreamController<AppLifecycleEvent>.broadcast();

  AppLifecycleManager(
    this._webSocketService,
    this._missedUpdateSynchronizer, {
    bool Function()? hasActiveSubscriptionsCallback,
  }) : _hasActiveSubscriptionsCallback = hasActiveSubscriptionsCallback {
    _initialize();
  }

  /// Stream of app lifecycle events
  Stream<AppLifecycleEvent> get lifecycleEvents => _lifecycleEventController.stream;

  /// Current app lifecycle state
  AppLifecycleState? get currentState => _previousState;

  /// Time when app went to background (if applicable)
  DateTime? get backgroundTime => _backgroundTime;

  void _initialize() {
    developer.log('Initializing AppLifecycleManager', name: 'AppLifecycleManager');
    WidgetsBinding.instance.addObserver(this);
    _previousState = WidgetsBinding.instance.lifecycleState;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;
    
    developer.log('App lifecycle state changed: $_previousState -> $state', name: 'AppLifecycleManager');
    
    // Cancel any pending debounced operations
    _debounceTimer?.cancel();
    
    // Debounce rapid state changes to avoid unnecessary connection operations
    _debounceTimer = Timer(_debounceDelay, () {
      if (!_isDisposed) {
        _handleLifecycleChange(_previousState, state);
        _previousState = state;
      }
    });
  }

  void _handleLifecycleChange(AppLifecycleState? previousState, AppLifecycleState currentState) {
    final event = AppLifecycleEvent(
      previousState: previousState,
      currentState: currentState,
      timestamp: DateTime.now(),
    );
    
    _lifecycleEventController.add(event);
    
    switch (currentState) {
      case AppLifecycleState.resumed:
        _handleAppResumed(previousState);
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  void _handleAppResumed(AppLifecycleState? previousState) async {
    developer.log('Handling app resumed from $previousState', name: 'AppLifecycleManager');
    
    try {
      // Calculate background duration if we have a background time
      Duration? backgroundDuration;
      if (_backgroundTime != null) {
        backgroundDuration = DateTime.now().difference(_backgroundTime!);
        developer.log('App was in background for ${backgroundDuration.inSeconds} seconds', name: 'AppLifecycleManager');
      }
      
      // Check if WebSocket service has active subscriptions
      final currentConnectionState = _webSocketService.currentState;
      final shouldReconnect = currentConnectionState == WebSocketConnectionState.disconnected &&
          _hasActiveSubscriptions();
      
      if (shouldReconnect) {
        developer.log('Reconnecting WebSocket after app resume', name: 'AppLifecycleManager');
        await _webSocketService.connect();
        
        // Synchronize missed updates if we were in background for a significant time
        if (backgroundDuration != null && backgroundDuration > const Duration(minutes: 1)) {
          await _synchronizeMissedUpdates(backgroundDuration);
        }
      }
      
      _backgroundTime = null;
    } catch (error) {
      developer.log('Error handling app resume: $error', name: 'AppLifecycleManager');
    }
  }

  void _handleAppPaused() async {
    developer.log('Handling app paused', name: 'AppLifecycleManager');
    
    try {
      _backgroundTime = DateTime.now();
      
      // Disconnect WebSocket to preserve battery
      if (_webSocketService.currentState == WebSocketConnectionState.connected) {
        developer.log('Disconnecting WebSocket due to app pause', name: 'AppLifecycleManager');
        await _webSocketService.disconnect();
      }
    } catch (error) {
      developer.log('Error handling app pause: $error', name: 'AppLifecycleManager');
    }
  }

  void _handleAppDetached() async {
    developer.log('Handling app detached', name: 'AppLifecycleManager');
    
    try {
      _backgroundTime = DateTime.now();
      
      // Ensure WebSocket is disconnected when app is detached
      if (_webSocketService.currentState != WebSocketConnectionState.disconnected) {
        developer.log('Disconnecting WebSocket due to app detach', name: 'AppLifecycleManager');
        await _webSocketService.disconnect();
      }
    } catch (error) {
      developer.log('Error handling app detach: $error', name: 'AppLifecycleManager');
    }
  }

  void _handleAppInactive() {
    developer.log('Handling app inactive', name: 'AppLifecycleManager');
    // App is inactive but still visible (e.g., during phone call)
    // We don't disconnect WebSocket in this state to maintain real-time updates
  }

  void _handleAppHidden() {
    developer.log('Handling app hidden', name: 'AppLifecycleManager');
    // App is hidden but not necessarily paused
    // Similar to inactive, we maintain connection
  }

  bool _hasActiveSubscriptions() {
    // Use the provided callback if available
    if (_hasActiveSubscriptionsCallback != null) {
      return _hasActiveSubscriptionsCallback!();
    }
    
    // Fallback: assume there are active subscriptions if the service was previously connected
    return true;
  }

  Future<void> _synchronizeMissedUpdates(Duration backgroundDuration) async {
    try {
      developer.log('Synchronizing missed updates for ${backgroundDuration.inMinutes} minutes', name: 'AppLifecycleManager');
      
      // Only synchronize if background duration is within reasonable limits
      if (backgroundDuration <= _maxBackgroundDuration) {
        await _missedUpdateSynchronizer.synchronizeMissedUpdates(
          backgroundTime: _backgroundTime!,
          resumeTime: DateTime.now(),
        );
      } else {
        developer.log('Background duration too long (${backgroundDuration.inMinutes} min), skipping sync', name: 'AppLifecycleManager');
        // For very long background periods, we might want to trigger a full data refresh
        await _missedUpdateSynchronizer.performFullDataRefresh();
      }
    } catch (error) {
      developer.log('Error synchronizing missed updates: $error', name: 'AppLifecycleManager');
    }
  }

  /// Manually trigger a lifecycle state change (useful for testing)
  void simulateLifecycleChange(AppLifecycleState state) {
    if (!_isDisposed) {
      didChangeAppLifecycleState(state);
    }
  }

  /// Get statistics about lifecycle management
  AppLifecycleStats getStats() {
    return AppLifecycleStats(
      currentState: _previousState,
      backgroundTime: _backgroundTime,
      isManaging: !_isDisposed,
    );
  }

  void dispose() {
    if (_isDisposed) return;
    
    developer.log('Disposing AppLifecycleManager', name: 'AppLifecycleManager');
    _isDisposed = true;
    
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleEventController.close();
  }
}

/// Represents an app lifecycle event
class AppLifecycleEvent {
  final AppLifecycleState? previousState;
  final AppLifecycleState currentState;
  final DateTime timestamp;

  const AppLifecycleEvent({
    required this.previousState,
    required this.currentState,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'AppLifecycleEvent(previous: $previousState, current: $currentState, timestamp: $timestamp)';
  }
}

/// Statistics about app lifecycle management
class AppLifecycleStats {
  final AppLifecycleState? currentState;
  final DateTime? backgroundTime;
  final bool isManaging;

  const AppLifecycleStats({
    required this.currentState,
    required this.backgroundTime,
    required this.isManaging,
  });

  Duration? get backgroundDuration {
    if (backgroundTime == null) return null;
    return DateTime.now().difference(backgroundTime!);
  }

  @override
  String toString() {
    return 'AppLifecycleStats(currentState: $currentState, backgroundTime: $backgroundTime, isManaging: $isManaging)';
  }
}