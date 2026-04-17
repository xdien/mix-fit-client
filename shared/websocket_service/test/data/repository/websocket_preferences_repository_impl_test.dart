import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';
import 'package:websocket_service/data/repository/websocket_preferences_repository_impl.dart';
import 'package:websocket_service/models/websocket_preferences.dart';

import 'websocket_preferences_repository_impl_test.mocks.dart';

@GenerateMocks([SharedPreferenceHelper, SharedPreferences])
void main() {
  late WebSocketPreferencesRepositoryImpl repository;
  late MockSharedPreferenceHelper mockSharedPrefsHelper;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPrefsHelper = MockSharedPreferenceHelper();
    mockSharedPreferences = MockSharedPreferences();
    
    when(mockSharedPrefsHelper.sharedPreferences).thenReturn(mockSharedPreferences);
    
    repository = WebSocketPreferencesRepositoryImpl(mockSharedPrefsHelper);
  });

  group('WebSocketPreferencesRepositoryImpl', () {
    test('should return default preferences when no stored preferences exist', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      final preferences = await repository.getPreferences();

      // Assert
      expect(preferences.enableRealTimeUpdates, true);
      expect(preferences.showConnectionStatus, true);
      expect(preferences.enableNotifications, true);
      expect(preferences.subscribedChannels.isNotEmpty, true);
      verify(mockSharedPreferences.setString('websocket_preferences', any)).called(1);
    });

    test('should return stored preferences when they exist', () async {
      // Arrange
      const storedPreferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'customer'},
        showConnectionStatus: false,
        enableNotifications: false,
      );
      final prefsJson = jsonEncode(storedPreferences.toJson());
      
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(prefsJson);

      // Act
      final preferences = await repository.getPreferences();

      // Assert
      expect(preferences.enableRealTimeUpdates, false);
      expect(preferences.subscribedChannels, {'customer'});
      expect(preferences.showConnectionStatus, false);
      expect(preferences.enableNotifications, false);
    });

    test('should save preferences correctly', () async {
      // Arrange
      const preferences = WebSocketPreferences(
        enableRealTimeUpdates: false,
        subscribedChannels: {'inventory'},
      );
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.savePreferences(preferences);

      // Assert
      final capturedJson = verify(mockSharedPreferences.setString('websocket_preferences', captureAny)).captured.single;
      final savedPreferences = WebSocketPreferences.fromJson(jsonDecode(capturedJson));
      expect(savedPreferences.enableRealTimeUpdates, false);
      expect(savedPreferences.subscribedChannels, {'inventory'});
    });

    test('should return available channels', () {
      // Act
      final channels = repository.getAvailableChannels();

      // Assert
      expect(channels.length, 5);
      expect(channels.any((c) => c.id == 'customer'), true);
      expect(channels.any((c) => c.id == 'inventory'), true);
      expect(channels.any((c) => c.id == 'order'), true);
      expect(channels.any((c) => c.id == 'system'), true);
      expect(channels.any((c) => c.id == 'notification'), true);
    });

    test('should set channel enabled correctly', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.setChannelEnabled('customer', false);

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.channelPreferences['customer'], false);
      expect(preferences.subscribedChannels.contains('customer'), false);
    });

    test('should set channel priority correctly', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.setChannelPriority('customer', NotificationPriority.high);

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.notificationPriorities['customer'], NotificationPriority.high);
    });

    test('should set real-time updates enabled correctly', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.setRealTimeUpdatesEnabled(false);

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.enableRealTimeUpdates, false);
    });

    test('should set connection status enabled correctly', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.setConnectionStatusEnabled(false);

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.showConnectionStatus, false);
    });

    test('should set notifications enabled correctly', () async {
      // Arrange
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(null);
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.setNotificationsEnabled(false);

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.enableNotifications, false);
    });

    test('should return subscribed channels correctly', () async {
      // Arrange
      const preferences = WebSocketPreferences(
        subscribedChannels: {'customer', 'inventory'},
      );
      final prefsJson = jsonEncode(preferences.toJson());
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(prefsJson);

      // Act
      await repository.getPreferences(); // Load preferences first
      final subscribedChannels = repository.getSubscribedChannels();

      // Assert
      expect(subscribedChannels, {'customer', 'inventory'});
    });

    test('should determine notification visibility correctly', () async {
      // Arrange
      const preferences = WebSocketPreferences(
        enableNotifications: true,
        channelPreferences: {'customer': true, 'inventory': false},
        notificationPriorities: {'customer': NotificationPriority.normal},
      );
      final prefsJson = jsonEncode(preferences.toJson());
      when(mockSharedPreferences.getString('websocket_preferences')).thenReturn(prefsJson);

      await repository.getPreferences(); // Load preferences first

      // Act & Assert
      expect(repository.shouldShowNotification('customer', NotificationPriority.high), true);
      expect(repository.shouldShowNotification('customer', NotificationPriority.low), false);
      expect(repository.shouldShowNotification('inventory', NotificationPriority.critical), false);
    });

    test('should reset to defaults correctly', () async {
      // Arrange
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

      // Act
      await repository.resetToDefaults();

      // Assert
      final preferences = await repository.getPreferences();
      expect(preferences.enableRealTimeUpdates, true);
      expect(preferences.showConnectionStatus, true);
      expect(preferences.enableNotifications, true);
      expect(preferences.subscribedChannels.isNotEmpty, true);
    });

    test('should emit preferences changes through stream', () async {
      // Arrange
      when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);
      const newPreferences = WebSocketPreferences(enableRealTimeUpdates: false);

      // Act
      final streamFuture = repository.preferencesStream.first;
      await repository.savePreferences(newPreferences);
      final emittedPreferences = await streamFuture;

      // Assert
      expect(emittedPreferences.enableRealTimeUpdates, false);
    });
  });
}