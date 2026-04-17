import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import '../interfaces/i_websocket_service.dart';
import '../models/websocket_connection_state.dart';
import '../models/websocket_message.dart';
import 'websocket_service.dart';
import 'app_lifecycle_manager.dart';
import 'missed_update_synchronizer.dart';

/// Enhanced WebSocket service with integrated app lifecycle management
/// 
/// This service extends the base WebSocket functionality with automatic
/// lifecycle management, handling background/foreground transitions and
/// missed update synchronization.
class LifecycleAwareWebSocketService implements IWebSocketService {
  final WebSocketService _baseService;
  late final AppLifecycleManager _lifecycleManager;
  late final MissedUpdateSynchronizer _missedUpdateSynchronizer;
  
  final Map<String, Function(dynamic)> _activeSubscriptions = {};
  bool _isDisposed = false;

  LifecycleAwareWebSocketService(
    this._baseService, {
    MissedUpdateSynchronizer? missedUpdateSynchronizer,
  }) {
    _missedUpdateSynchronizer = missedUpdateSynchronizer ?? _createDefaultSynchronizer();
    _lifecycleManager = AppLifecycleManager(
      _baseService, 
      _missedUpdateSynchronizer,
      hasActiveSubscriptionsCallback: () => hasActiveSubscriptions(),
    );
    _setupLifecycleIntegration();
  }

  @override
  Stream<WebSocketConnectionState> get connectionState => _baseService.connectionState;

  @override
  WebSocketConnectionState get currentState => _baseService.currentState;

  /// Stream of app lifecycle events
  Stream<AppLifecycleEvent> get lifecycleEvents => _lifecycleManager.lifecycleEvents;

  /// Stream of synchronization events
  Stream<SynchronizationEvent> get synchronizationEvents => _missedUpdateSynchronizer.synchronizationEvents;

  /// Get lifecycle management statistics
  AppLifecycleStats get lifecycleStats => _lifecycleManager.getStats();

  /// Whether missed update synchronization is in progress
  bool get isSynchronizing => _missedUpdateSynchronizer.isSynchronizing;

  @override
  Future<void> connect() async {
    if (_isDisposed) {
      developer.log('Service is disposed, cannot connect', name: 'LifecycleAwareWebSocketService');
      return;
    }
    
    developer.log('Connecting with lifecycle awareness', name: 'LifecycleAwareWebSocketService');
    await _baseService.connect();
  }

  @override
  Future<void> disconnect() async {
    developer.log('Disconnecting with lifecycle awareness', name: 'LifecycleAwareWebSocketService');
    await _baseService.disconnect();
  }

  @override
  void subscribe(String channel, Function(dynamic) callback) {
    if (_isDisposed) {
      developer.log('Service is disposed, cannot subscribe to $channel', name: 'LifecycleAwareWebSocketService');
      return;
    }
    
    developer.log('Subscribing to channel with lifecycle awareness: $channel', name: 'LifecycleAwareWebSocketService');
    
    // Store the subscription for lifecycle management
    _activeSubscriptions[channel] = callback;
    
    // Subscribe through base service
    _baseService.subscribe(channel, callback);
  }

  @override
  void unsubscribe(String channel) {
    developer.log('Unsubscribing from channel: $channel', name: 'LifecycleAwareWebSocketService');
    
    // Remove from active subscriptions
    _activeSubscriptions.remove(channel);
    
    // Unsubscribe through base service
    _baseService.unsubscribe(channel);
  }

  @override
  Future<void> handleAppLifecycle(AppLifecycleState state) async {
    // This is handled automatically by the lifecycle manager
    developer.log('App lifecycle handled automatically by lifecycle manager: $state', name: 'LifecycleAwareWebSocketService');
  }

  /// Manually trigger missed update synchronization
  Future<SynchronizationResult> synchronizeMissedUpdates({
    required DateTime backgroundTime,
    required DateTime resumeTime,
  }) async {
    return await _missedUpdateSynchronizer.synchronizeMissedUpdates(
      backgroundTime: backgroundTime,
      resumeTime: resumeTime,
    );
  }

  /// Perform a full data refresh
  Future<SynchronizationResult> performFullDataRefresh() async {
    return await _missedUpdateSynchronizer.performFullDataRefresh();
  }

  /// Check if there are active subscriptions
  bool hasActiveSubscriptions() {
    return _activeSubscriptions.isNotEmpty;
  }

  /// Get list of active subscription channels
  List<String> getActiveChannels() {
    return _activeSubscriptions.keys.toList();
  }

  /// Simulate app lifecycle change (useful for testing)
  void simulateLifecycleChange(AppLifecycleState state) {
    _lifecycleManager.simulateLifecycleChange(state);
  }

  void _setupLifecycleIntegration() {
    // Listen to lifecycle events for logging and additional processing
    _lifecycleManager.lifecycleEvents.listen((event) {
      developer.log('Lifecycle event: ${event.previousState} -> ${event.currentState}', name: 'LifecycleAwareWebSocketService');
    });

    // Listen to synchronization events for logging
    _missedUpdateSynchronizer.synchronizationEvents.listen((event) {
      developer.log('Synchronization event: ${event.type}', name: 'LifecycleAwareWebSocketService');
    });
  }

  MissedUpdateSynchronizer _createDefaultSynchronizer() {
    return MissedUpdateSynchronizer(
      fetchMissedUpdates: _fetchMissedUpdatesFromServer,
      processBatchUpdates: _processBatchUpdates,
      performFullRefresh: _performFullDataRefresh,
    );
  }

  /// Default implementation for fetching missed updates from server
  /// This should be customized based on your backend API
  Future<List<WebSocketMessage>> _fetchMissedUpdatesFromServer(DateTime from, DateTime to) async {
    developer.log('Fetching missed updates from $from to $to', name: 'LifecycleAwareWebSocketService');
    
    // TODO: Implement actual API call to fetch missed updates
    // This is a placeholder implementation
    try {
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return empty list for now - should be replaced with actual API call
      return <WebSocketMessage>[];
    } catch (error) {
      developer.log('Error fetching missed updates: $error', name: 'LifecycleAwareWebSocketService');
      rethrow;
    }
  }

  /// Default implementation for processing batch updates
  Future<void> _processBatchUpdates(List<WebSocketMessage> updates) async {
    developer.log('Processing batch of ${updates.length} updates', name: 'LifecycleAwareWebSocketService');
    
    try {
      for (final update in updates) {
        // Process each update through the appropriate subscription callback
        final callback = _activeSubscriptions[update.channel];
        if (callback != null) {
          callback(update.data);
        }
      }
    } catch (error) {
      developer.log('Error processing batch updates: $error', name: 'LifecycleAwareWebSocketService');
      rethrow;
    }
  }

  /// Default implementation for full data refresh
  Future<void> _performFullDataRefresh() async {
    developer.log('Performing full data refresh', name: 'LifecycleAwareWebSocketService');
    
    try {
      // TODO: Implement actual full data refresh logic
      // This might involve calling repository methods to refresh all data
      
      // Simulate refresh delay
      await Future.delayed(const Duration(seconds: 2));
      
      developer.log('Full data refresh completed', name: 'LifecycleAwareWebSocketService');
    } catch (error) {
      developer.log('Error during full data refresh: $error', name: 'LifecycleAwareWebSocketService');
      rethrow;
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    
    developer.log('Disposing LifecycleAwareWebSocketService', name: 'LifecycleAwareWebSocketService');
    _isDisposed = true;
    
    _lifecycleManager.dispose();
    _missedUpdateSynchronizer.dispose();
    _baseService.dispose();
    _activeSubscriptions.clear();
  }
}