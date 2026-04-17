import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:constants/stores/error/error_store.dart';
import 'package:websocket_service/domain/repository/websocket_preferences_repository.dart';
import 'package:websocket_service/stores/websocket_preferences_store.dart';
import 'package:websocket_service/models/websocket_preferences.dart';
import 'package:websocket_service/models/websocket_channel_config.dart';

import 'websocket_preferences_store_test.mocks.dart';

@GenerateMocks([WebSocketPreferencesRepository, ErrorStore])
void main() {
  late WebSocketPreferencesStore store;
  late MockWebSocketPreferencesRepository mockRepository;
  late MockErrorStore mockErrorStore;
  late StreamController<WebSocketPreferences> preferencesStreamController;

  setUp(() {
    mockRepository = MockWebSocketPreferencesRepository();
    mockErrorStore = MockErrorStore();
    preferencesStreamController = StreamController<WebSocketPreferences>.broadcast();
    
    when(mockRepository.preferencesStream).thenAnswer((_) => preferencesStreamController.stream);
    
    store = WebSocketPreferencesStore(mockRepository, mockErrorStore);
  });

  tearDown(() {
    preferencesStreamController.close();
  });

  group('WebSocketPreferencesStore', () {
    test('should initialize with loading state', () {
      expect(store.isLoading, false); // Initial state before init is called
    });

    test('should load preferences and channels on init', () async {
      // Arrange
      const mockPreferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer'},
      );
      final mockChannels = [
        const WebSocketChannelConfig(
          id: 'customer',
          name: 'Customer Updates',
          description: 'Customer updates',
          type: WebSocketChannelType.customer,
        ),
      ];

      when(mockRepository.getPreferences()).thenAnswer((_) async => mockPreferences);
      when(mockRepository.getAvailableChannels()).thenReturn(mockChannels);

      // Act
      await store.init();

      // Assert
      expect(store.preferences, mockPreferences);
      expect(store.availableChannels, mockChannels);
      expect(store.enableRealTimeUpdates, false);
      expect(store.subscribedChannels, {'customer'});
      expect(store.isLoading, false);
    });

    test('should handle init error', () async {
      // Arrange
      when(mockRepository.getPreferences()).thenThrow(Exception('Test error'));
      when(mockRepository.getAvailableChannels()).thenReturn([]);

      // Act
      await store.init();

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to load WebSocket preferences: Exception: Test error');
      expect(store.isLoading, false);
    });

    test('should set real-time updates enabled', () async {
      // Arrange
      when(mockRepository.setRealTimeUpdatesEnabled(false)).thenAnswer((_) async {});

      // Act
      await store.setRealTimeUpdatesEnabled(false);

      // Assert
      verify(mockRepository.setRealTimeUpdatesEnabled(false)).called(1);
    });

    test('should handle real-time updates error', () async {
      // Arrange
      when(mockRepository.setRealTimeUpdatesEnabled(false)).thenThrow(Exception('Test error'));

      // Act
      await store.setRealTimeUpdatesEnabled(false);

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to update real-time settings: Exception: Test error');
    });

    test('should set connection status enabled', () async {
      // Arrange
      when(mockRepository.setConnectionStatusEnabled(false)).thenAnswer((_) async {});

      // Act
      await store.setConnectionStatusEnabled(false);

      // Assert
      verify(mockRepository.setConnectionStatusEnabled(false)).called(1);
    });

    test('should handle connection status error', () async {
      // Arrange
      when(mockRepository.setConnectionStatusEnabled(false)).thenThrow(Exception('Test error'));

      // Act
      await store.setConnectionStatusEnabled(false);

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to update connection status settings: Exception: Test error');
    });

    test('should set notifications enabled', () async {
      // Arrange
      when(mockRepository.setNotificationsEnabled(false)).thenAnswer((_) async {});

      // Act
      await store.setNotificationsEnabled(false);

      // Assert
      verify(mockRepository.setNotificationsEnabled(false)).called(1);
    });

    test('should handle notifications error', () async {
      // Arrange
      when(mockRepository.setNotificationsEnabled(false)).thenThrow(Exception('Test error'));

      // Act
      await store.setNotificationsEnabled(false);

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to update notification settings: Exception: Test error');
    });

    test('should set channel enabled', () async {
      // Arrange
      when(mockRepository.setChannelEnabled('customer', false)).thenAnswer((_) async {});

      // Act
      await store.setChannelEnabled('customer', false);

      // Assert
      verify(mockRepository.setChannelEnabled('customer', false)).called(1);
    });

    test('should handle channel enabled error', () async {
      // Arrange
      when(mockRepository.setChannelEnabled('customer', false)).thenThrow(Exception('Test error'));

      // Act
      await store.setChannelEnabled('customer', false);

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to update channel settings: Exception: Test error');
    });

    test('should set channel priority', () async {
      // Arrange
      when(mockRepository.setChannelPriority('customer', NotificationPriority.high)).thenAnswer((_) async {});

      // Act
      await store.setChannelPriority('customer', NotificationPriority.high);

      // Assert
      verify(mockRepository.setChannelPriority('customer', NotificationPriority.high)).called(1);
    });

    test('should handle channel priority error', () async {
      // Arrange
      when(mockRepository.setChannelPriority('customer', NotificationPriority.high)).thenThrow(Exception('Test error'));

      // Act
      await store.setChannelPriority('customer', NotificationPriority.high);

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to update channel priority: Exception: Test error');
    });

    test('should reset to defaults', () async {
      // Arrange
      when(mockRepository.resetToDefaults()).thenAnswer((_) async {});

      // Act
      await store.resetToDefaults();

      // Assert
      verify(mockRepository.resetToDefaults()).called(1);
      expect(store.isLoading, false);
    });

    test('should handle reset error', () async {
      // Arrange
      when(mockRepository.resetToDefaults()).thenThrow(Exception('Test error'));

      // Act
      await store.resetToDefaults();

      // Assert
      verify(mockErrorStore.errorMessage = 'Failed to reset preferences: Exception: Test error');
      expect(store.isLoading, false);
    });

    test('should get channel config', () {
      // Arrange
      const mockChannel = WebSocketChannelConfig(
        id: 'customer',
        name: 'Customer Updates',
        description: 'Customer updates',
        type: WebSocketChannelType.customer,
      );
      store.availableChannels.add(mockChannel);

      // Act
      final config = store.getChannelConfig('customer');

      // Assert
      expect(config, mockChannel);
    });

    test('should return null for non-existent channel config', () {
      // Act
      final config = store.getChannelConfig('non-existent');

      // Assert
      expect(config, null);
    });

    test('should check if channel is user configurable', () {
      // Arrange
      const mockChannel = WebSocketChannelConfig(
        id: 'customer',
        name: 'Customer Updates',
        description: 'Customer updates',
        type: WebSocketChannelType.customer,
        userConfigurable: false,
      );
      store.availableChannels.add(mockChannel);

      // Act
      final isConfigurable = store.isChannelUserConfigurable('customer');

      // Assert
      expect(isConfigurable, false);
    });

    test('should return true for non-existent channel configurability', () {
      // Act
      final isConfigurable = store.isChannelUserConfigurable('non-existent');

      // Assert
      expect(isConfigurable, true);
    });

    test('should update preferences when stream emits', () async {
      // Arrange
      const initialPreferences = WebSocketPreferences(enableRealTimeUpdates: true);
      const updatedPreferences = WebSocketPreferences(enableRealTimeUpdates: false);
      
      when(mockRepository.getPreferences()).thenAnswer((_) async => initialPreferences);
      when(mockRepository.getAvailableChannels()).thenReturn([]);

      await store.init();
      expect(store.enableRealTimeUpdates, true);

      // Act
      preferencesStreamController.add(updatedPreferences);
      await Future.delayed(Duration.zero); // Allow stream to process

      // Assert
      expect(store.enableRealTimeUpdates, false);
    });

    test('should return active subscribed channels when real-time updates enabled', () async {
      // Arrange
      const preferences = WebSocketPreferences(
        enableRealTimeUpdates: true,
        subscribedChannels: {'customer', 'inventory'},
      );
      
      when(mockRepository.getPreferences()).thenAnswer((_) async => preferences);
      when(mockRepository.getAvailableChannels()).thenReturn([]);
      
      await store.init();

      // Act
      final activeChannels = store.activeSubscribedChannels;

      // Assert
      expect(activeChannels, {'customer', 'inventory'});
    });

    test('should return empty set when real-time updates disabled', () async {
      // Arrange
      const preferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer', 'inventory'},
      );
      
      when(mockRepository.getPreferences()).thenAnswer((_) async => preferences);
      when(mockRepository.getAvailableChannels()).thenReturn([]);
      
      await store.init();

      // Act
      final activeChannels = store.activeSubscribedChannels;

      // Assert
      expect(activeChannels, isEmpty);
    });
  });
}