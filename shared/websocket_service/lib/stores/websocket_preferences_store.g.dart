// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_preferences_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WebSocketPreferencesStore on _WebSocketPreferencesStore, Store {
  Computed<Set<String>>? _$activeSubscribedChannelsComputed;

  @override
  Set<String> get activeSubscribedChannels =>
      (_$activeSubscribedChannelsComputed ??= Computed<Set<String>>(
              () => super.activeSubscribedChannels,
              name: '_WebSocketPreferencesStore.activeSubscribedChannels'))
          .value;

  late final _$_preferencesAtom =
      Atom(name: '_WebSocketPreferencesStore._preferences', context: context);

  @override
  WebSocketPreferences? get _preferences {
    _$_preferencesAtom.reportRead();
    return super._preferences;
  }

  @override
  set _preferences(WebSocketPreferences? value) {
    _$_preferencesAtom.reportWrite(value, super._preferences, () {
      super._preferences = value;
    });
  }

  late final _$_availableChannelsAtom = Atom(
      name: '_WebSocketPreferencesStore._availableChannels', context: context);

  @override
  List<WebSocketChannelConfig> get _availableChannels {
    _$_availableChannelsAtom.reportRead();
    return super._availableChannels;
  }

  @override
  set _availableChannels(List<WebSocketChannelConfig> value) {
    _$_availableChannelsAtom.reportWrite(value, super._availableChannels, () {
      super._availableChannels = value;
    });
  }

  late final _$_isLoadingAtom =
      Atom(name: '_WebSocketPreferencesStore._isLoading', context: context);

  @override
  bool get _isLoading {
    _$_isLoadingAtom.reportRead();
    return super._isLoading;
  }

  @override
  set _isLoading(bool value) {
    _$_isLoadingAtom.reportWrite(value, super._isLoading, () {
      super._isLoading = value;
    });
  }

  late final _$initAsyncAction =
      AsyncAction('_WebSocketPreferencesStore.init', context: context);

  @override
  Future<void> init() {
    return _$initAsyncAction.run(() => super.init());
  }

  late final _$setRealTimeUpdatesEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setRealTimeUpdatesEnabled',
      context: context);

  @override
  Future<void> setRealTimeUpdatesEnabled(bool enabled) {
    return _$setRealTimeUpdatesEnabledAsyncAction
        .run(() => super.setRealTimeUpdatesEnabled(enabled));
  }

  late final _$setConnectionStatusEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setConnectionStatusEnabled',
      context: context);

  @override
  Future<void> setConnectionStatusEnabled(bool enabled) {
    return _$setConnectionStatusEnabledAsyncAction
        .run(() => super.setConnectionStatusEnabled(enabled));
  }

  late final _$setNotificationsEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setNotificationsEnabled',
      context: context);

  @override
  Future<void> setNotificationsEnabled(bool enabled) {
    return _$setNotificationsEnabledAsyncAction
        .run(() => super.setNotificationsEnabled(enabled));
  }

  late final _$setChannelEnabledAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setChannelEnabled',
      context: context);

  @override
  Future<void> setChannelEnabled(String channelId, bool enabled) {
    return _$setChannelEnabledAsyncAction
        .run(() => super.setChannelEnabled(channelId, enabled));
  }

  late final _$setChannelPriorityAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.setChannelPriority',
      context: context);

  @override
  Future<void> setChannelPriority(
      String channelId, NotificationPriority priority) {
    return _$setChannelPriorityAsyncAction
        .run(() => super.setChannelPriority(channelId, priority));
  }

  late final _$resetToDefaultsAsyncAction = AsyncAction(
      '_WebSocketPreferencesStore.resetToDefaults',
      context: context);

  @override
  Future<void> resetToDefaults() {
    return _$resetToDefaultsAsyncAction.run(() => super.resetToDefaults());
  }

  @override
  String toString() {
    return '''
activeSubscribedChannels: ${activeSubscribedChannels}
    ''';
  }
}
