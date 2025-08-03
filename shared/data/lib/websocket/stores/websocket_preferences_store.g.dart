// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_preferences_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WebSocketPreferencesStore on _WebSocketPreferencesStore, Store {
  Computed<bool>? _$isRealTimeEnabledComputed;

  @override
  bool get isRealTimeEnabled => (_$isRealTimeEnabledComputed ??= Computed<bool>(
          () => super.isRealTimeEnabled,
          name: '_WebSocketPreferencesStore.isRealTimeEnabled'))
      .value;
  Computed<bool>? _$isConnectionStatusVisibleComputed;

  @override
  bool get isConnectionStatusVisible => (_$isConnectionStatusVisibleComputed ??=
          Computed<bool>(() => super.isConnectionStatusVisible,
              name: '_WebSocketPreferencesStore.isConnectionStatusVisible'))
      .value;
  Computed<bool>? _$areNotificationsEnabledComputed;

  @override
  bool get areNotificationsEnabled => (_$areNotificationsEnabledComputed ??=
          Computed<bool>(() => super.areNotificationsEnabled,
              name: '_WebSocketPreferencesStore.areNotificationsEnabled'))
      .value;
  Computed<bool>? _$areSoundNotificationsEnabledComputed;

  @override
  bool get areSoundNotificationsEnabled =>
      (_$areSoundNotificationsEnabledComputed ??= Computed<bool>(
              () => super.areSoundNotificationsEnabled,
              name: '_WebSocketPreferencesStore.areSoundNotificationsEnabled'))
          .value;
  Computed<bool>? _$areVibrationNotificationsEnabledComputed;

  @override
  bool get areVibrationNotificationsEnabled =>
      (_$areVibrationNotificationsEnabledComputed ??= Computed<bool>(
              () => super.areVibrationNotificationsEnabled,
              name:
                  '_WebSocketPreferencesStore.areVibrationNotificationsEnabled'))
          .value;
  Computed<bool>? _$areForegroundNotificationsEnabledComputed;

  @override
  bool get areForegroundNotificationsEnabled =>
      (_$areForegroundNotificationsEnabledComputed ??= Computed<bool>(
              () => super.areForegroundNotificationsEnabled,
              name:
                  '_WebSocketPreferencesStore.areForegroundNotificationsEnabled'))
          .value;
  Computed<bool>? _$isOfflineQueueEnabledComputed;

  @override
  bool get isOfflineQueueEnabled => (_$isOfflineQueueEnabledComputed ??=
          Computed<bool>(() => super.isOfflineQueueEnabled,
              name: '_WebSocketPreferencesStore.isOfflineQueueEnabled'))
      .value;
  Computed<bool>? _$isAutoReconnectEnabledComputed;

  @override
  bool get isAutoReconnectEnabled => (_$isAutoReconnectEnabledComputed ??=
          Computed<bool>(() => super.isAutoReconnectEnabled,
              name: '_WebSocketPreferencesStore.isAutoReconnectEnabled'))
      .value;
  Computed<int>? _$maxQueuedMessagesComputed;

  @override
  int get maxQueuedMessages => (_$maxQueuedMessagesComputed ??= Computed<int>(
          () => super.maxQueuedMessages,
          name: '_WebSocketPreferencesStore.maxQueuedMessages'))
      .value;
  Computed<int>? _$heartbeatIntervalComputed;

  @override
  int get heartbeatInterval => (_$heartbeatIntervalComputed ??= Computed<int>(
          () => super.heartbeatInterval,
          name: '_WebSocketPreferencesStore.heartbeatInterval'))
      .value;
  Computed<Set<WebSocketMessageType>>? _$enabledMessageTypesComputed;

  @override
  Set<WebSocketMessageType> get enabledMessageTypes =>
      (_$enabledMessageTypesComputed ??= Computed<Set<WebSocketMessageType>>(
              () => super.enabledMessageTypes,
              name: '_WebSocketPreferencesStore.enabledMessageTypes'))
          .value;
  Computed<Set<String>>? _$enabledChannelsComputed;

  @override
  Set<String> get enabledChannels => (_$enabledChannelsComputed ??=
          Computed<Set<String>>(() => super.enabledChannels,
              name: '_WebSocketPreferencesStore.enabledChannels'))
      .value;
  Computed<Map<WebSocketMessageType, int>>? _$messagePrioritiesComputed;

  @override
  Map<WebSocketMessageType, int> get messagePriorities =>
      (_$messagePrioritiesComputed ??= Computed<Map<WebSocketMessageType, int>>(
              () => super.messagePriorities,
              name: '_WebSocketPreferencesStore.messagePriorities'))
          .value;

  late final _$preferencesAtom =
      Atom(name: '_WebSocketPreferencesStore.preferences', context: context);

  @override
  WebSocketPreferences get preferences {
    _$preferencesAtom.reportRead();
    return super.preferences;
  }

  @override
  set preferences(WebSocketPreferences value) {
    _$preferencesAtom.reportWrite(value, super.preferences, () {
      super.preferences = value;
    });
  }

  late final _$isLoadingAtom =
      Atom(name: '_WebSocketPreferencesStore.isLoading', context: context);

  @override
  bool get isLoading {
    _$isLoadingAtom.reportRead();
    return super.isLoading;
  }

  @override
  set isLoading(bool value) {
    _$isLoadingAtom.reportWrite(value, super.isLoading, () {
      super.isLoading = value;
    });
  }

  late final _$errorMessageAtom =
      Atom(name: '_WebSocketPreferencesStore.errorMessage', context: context);

  @override
  String? get errorMessage {
    _$errorMessageAtom.reportRead();
    return super.errorMessage;
  }

  @override
  set errorMessage(String? value) {
    _$errorMessageAtom.reportWrite(value, super.errorMessage, () {
      super.errorMessage = value;
    });
  }

  late final _$_initializeStoreAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore._initializeStore',
      context: context);

  @override
  Future<void> _initializeStore() {
    return _$_initializeStoreAsyncAction.run(() => super._initializeStore());
  }

  late final _$setRealTimeEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setRealTimeEnabled',
      context: context);

  @override
  Future<void> setRealTimeEnabled(bool enabled) {
    return _$setRealTimeEnabledAsyncAction
        .run(() => super.setRealTimeEnabled(enabled));
  }

  late final _$setConnectionStatusVisibleAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setConnectionStatusVisible',
      context: context);

  @override
  Future<void> setConnectionStatusVisible(bool visible) {
    return _$setConnectionStatusVisibleAsyncAction
        .run(() => super.setConnectionStatusVisible(visible));
  }

  late final _$setNotificationsEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setNotificationsEnabled',
      context: context);

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return _$setNotificationsEnabledAsyncAction
        .run(() => super.setNotificationsEnabled(enabled));
  }

  late final _$setSoundNotificationsEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setSoundNotificationsEnabled',
      context: context);

  @override
  Future<void> setSoundNotificationsEnabled(bool enabled) {
    return _$setSoundNotificationsEnabledAsyncAction
        .run(() => super.setSoundNotificationsEnabled(enabled));
  }

  late final _$setVibrationNotificationsEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setVibrationNotificationsEnabled',
      context: context);

  @override
  Future<void> setVibrationNotificationsEnabled(bool enabled) {
    return _$setVibrationNotificationsEnabledAsyncAction
        .run(() => super.setVibrationNotificationsEnabled(enabled));
  }

  late final _$setForegroundNotificationsEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setForegroundNotificationsEnabled',
      context: context);

  @override
  Future<void> setForegroundNotificationsEnabled(bool enabled) {
    return _$setForegroundNotificationsEnabledAsyncAction
        .run(() => super.setForegroundNotificationsEnabled(enabled));
  }

  late final _$setMessageTypeEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setMessageTypeEnabled',
      context: context);

  @override
  Future<void> setMessageTypeEnabled(
      WebSocketMessageType messageType, bool enabled) {
    return _$setMessageTypeEnabledAsyncAction
        .run(() => super.setMessageTypeEnabled(messageType, enabled));
  }

  late final _$setChannelEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setChannelEnabled',
      context: context);

  @override
  Future<void> setChannelEnabled(String channel, bool enabled) {
    return _$setChannelEnabledAsyncAction
        .run(() => super.setChannelEnabled(channel, enabled));
  }

  late final _$setMessageTypePriorityAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setMessageTypePriority',
      context: context);

  @override
  Future<void> setMessageTypePriority(
      WebSocketMessageType messageType, int priority) {
    return _$setMessageTypePriorityAsyncAction
        .run(() => super.setMessageTypePriority(messageType, priority));
  }

  late final _$setOfflineQueueEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setOfflineQueueEnabled',
      context: context);

  @override
  Future<void> setOfflineQueueEnabled(bool enabled) {
    return _$setOfflineQueueEnabledAsyncAction
        .run(() => super.setOfflineQueueEnabled(enabled));
  }

  late final _$setMaxQueuedMessagesAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setMaxQueuedMessages',
      context: context);

  @override
  Future<void> setMaxQueuedMessages(int maxMessages) {
    return _$setMaxQueuedMessagesAsyncAction
        .run(() => super.setMaxQueuedMessages(maxMessages));
  }

  late final _$setAutoReconnectEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setAutoReconnectEnabled',
      context: context);

  @override
  Future<void> setAutoReconnectEnabled(bool enabled) {
    return _$setAutoReconnectEnabledAsyncAction
        .run(() => super.setAutoReconnectEnabled(enabled));
  }

  late final _$setHeartbeatIntervalAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setHeartbeatInterval',
      context: context);

  @override
  Future<void> setHeartbeatInterval(int intervalSeconds) {
    return _$setHeartbeatIntervalAsyncAction
        .run(() => super.setHeartbeatInterval(intervalSeconds));
  }

  late final _$resetToDefaultsAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.resetToDefaults',
      context: context);

  @override
  Future<void> resetToDefaults() {
    return _$resetToDefaultsAsyncAction.run(() => super.resetToDefaults());
  }

  late final _$_WebSocketPreferencesStoreActionController =
      ActionController(name: '_WebSocketPreferencesStore', context: context);

  @override
  void clearError() {
    final _$actionInfo = _$_WebSocketPreferencesStoreActionController
        .startAction(name: '_WebSocketPreferencesStore.clearError');
    try {
      return super.clearError();
    } finally {
      _$_WebSocketPreferencesStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
preferences: ${preferences},
isLoading: ${isLoading},
errorMessage: ${errorMessage},
isRealTimeEnabled: ${isRealTimeEnabled},
isConnectionStatusVisible: ${isConnectionStatusVisible},
areNotificationsEnabled: ${areNotificationsEnabled},
areSoundNotificationsEnabled: ${areSoundNotificationsEnabled},
areVibrationNotificationsEnabled: ${areVibrationNotificationsEnabled},
areForegroundNotificationsEnabled: ${areForegroundNotificationsEnabled},
isOfflineQueueEnabled: ${isOfflineQueueEnabled},
isAutoReconnectEnabled: ${isAutoReconnectEnabled},
maxQueuedMessages: ${maxQueuedMessages},
heartbeatInterval: ${heartbeatInterval},
enabledMessageTypes: ${enabledMessageTypes},
enabledChannels: ${enabledChannels},
messagePriorities: ${messagePriorities}
    ''';
  }
}
