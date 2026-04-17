// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_status_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WebSocketStatusStore on _WebSocketStatusStore, Store {
  Computed<bool>? _$isConnectedComputed;

  @override
  bool get isConnected =>
      (_$isConnectedComputed ??= Computed<bool>(() => super.isConnected,
              name: '_WebSocketStatusStore.isConnected'))
          .value;
  Computed<bool>? _$isConnectingComputed;

  @override
  bool get isConnecting =>
      (_$isConnectingComputed ??= Computed<bool>(() => super.isConnecting,
              name: '_WebSocketStatusStore.isConnecting'))
          .value;
  Computed<bool>? _$isOfflineComputed;

  @override
  bool get isOffline =>
      (_$isOfflineComputed ??= Computed<bool>(() => super.isOffline,
              name: '_WebSocketStatusStore.isOffline'))
          .value;
  Computed<bool>? _$hasErrorComputed;

  @override
  bool get hasError =>
      (_$hasErrorComputed ??= Computed<bool>(() => super.hasError,
              name: '_WebSocketStatusStore.hasError'))
          .value;
  Computed<bool>? _$canRetryComputed;

  @override
  bool get canRetry =>
      (_$canRetryComputed ??= Computed<bool>(() => super.canRetry,
              name: '_WebSocketStatusStore.canRetry'))
          .value;
  Computed<String>? _$statusTextComputed;

  @override
  String get statusText =>
      (_$statusTextComputed ??= Computed<String>(() => super.statusText,
              name: '_WebSocketStatusStore.statusText'))
          .value;
  Computed<bool>? _$shouldShowOfflineModeComputed;

  @override
  bool get shouldShowOfflineMode => (_$shouldShowOfflineModeComputed ??=
          Computed<bool>(() => super.shouldShowOfflineMode,
              name: '_WebSocketStatusStore.shouldShowOfflineMode'))
      .value;
  Computed<bool>? _$showConnectionDetailsComputed;

  @override
  bool get showConnectionDetails => (_$showConnectionDetailsComputed ??=
          Computed<bool>(() => super.showConnectionDetails,
              name: '_WebSocketStatusStore.showConnectionDetails'))
      .value;

  late final _$connectionStateAtom =
      Atom(name: '_WebSocketStatusStore.connectionState', context: context);

  @override
  WebSocketConnectionState get connectionState {
    _$connectionStateAtom.reportRead();
    return super.connectionState;
  }

  @override
  set connectionState(WebSocketConnectionState value) {
    _$connectionStateAtom.reportWrite(value, super.connectionState, () {
      super.connectionState = value;
    });
  }

  late final _$lastErrorAtom =
      Atom(name: '_WebSocketStatusStore.lastError', context: context);

  @override
  WebSocketError? get lastError {
    _$lastErrorAtom.reportRead();
    return super.lastError;
  }

  @override
  set lastError(WebSocketError? value) {
    _$lastErrorAtom.reportWrite(value, super.lastError, () {
      super.lastError = value;
    });
  }

  late final _$reconnectAttemptsAtom =
      Atom(name: '_WebSocketStatusStore.reconnectAttempts', context: context);

  @override
  int get reconnectAttempts {
    _$reconnectAttemptsAtom.reportRead();
    return super.reconnectAttempts;
  }

  @override
  set reconnectAttempts(int value) {
    _$reconnectAttemptsAtom.reportWrite(value, super.reconnectAttempts, () {
      super.reconnectAttempts = value;
    });
  }

  late final _$lastResponseTimeAtom =
      Atom(name: '_WebSocketStatusStore.lastResponseTime', context: context);

  @override
  Duration? get lastResponseTime {
    _$lastResponseTimeAtom.reportRead();
    return super.lastResponseTime;
  }

  @override
  set lastResponseTime(Duration? value) {
    _$lastResponseTimeAtom.reportWrite(value, super.lastResponseTime, () {
      super.lastResponseTime = value;
    });
  }

  late final _$lastConnectedTimeAtom =
      Atom(name: '_WebSocketStatusStore.lastConnectedTime', context: context);

  @override
  DateTime? get lastConnectedTime {
    _$lastConnectedTimeAtom.reportRead();
    return super.lastConnectedTime;
  }

  @override
  set lastConnectedTime(DateTime? value) {
    _$lastConnectedTimeAtom.reportWrite(value, super.lastConnectedTime, () {
      super.lastConnectedTime = value;
    });
  }

  late final _$queuedUpdatesCountAtom =
      Atom(name: '_WebSocketStatusStore.queuedUpdatesCount', context: context);

  @override
  int get queuedUpdatesCount {
    _$queuedUpdatesCountAtom.reportRead();
    return super.queuedUpdatesCount;
  }

  @override
  set queuedUpdatesCount(int value) {
    _$queuedUpdatesCountAtom.reportWrite(value, super.queuedUpdatesCount, () {
      super.queuedUpdatesCount = value;
    });
  }

  late final _$isStatusBarVisibleAtom =
      Atom(name: '_WebSocketStatusStore.isStatusBarVisible', context: context);

  @override
  bool get isStatusBarVisible {
    _$isStatusBarVisibleAtom.reportRead();
    return super.isStatusBarVisible;
  }

  @override
  set isStatusBarVisible(bool value) {
    _$isStatusBarVisibleAtom.reportWrite(value, super.isStatusBarVisible, () {
      super.isStatusBarVisible = value;
    });
  }

  late final _$isStatusBarMinimizedAtom = Atom(
      name: '_WebSocketStatusStore.isStatusBarMinimized', context: context);

  @override
  bool get isStatusBarMinimized {
    _$isStatusBarMinimizedAtom.reportRead();
    return super.isStatusBarMinimized;
  }

  @override
  set isStatusBarMinimized(bool value) {
    _$isStatusBarMinimizedAtom.reportWrite(value, super.isStatusBarMinimized,
        () {
      super.isStatusBarMinimized = value;
    });
  }

  late final _$showConnectionDetailsFlagAtom = Atom(
      name: '_WebSocketStatusStore.showConnectionDetailsFlag',
      context: context);

  @override
  bool get showConnectionDetailsFlag {
    _$showConnectionDetailsFlagAtom.reportRead();
    return super.showConnectionDetailsFlag;
  }

  @override
  set showConnectionDetailsFlag(bool value) {
    _$showConnectionDetailsFlagAtom
        .reportWrite(value, super.showConnectionDetailsFlag, () {
      super.showConnectionDetailsFlag = value;
    });
  }

  late final _$retryConnectionAsyncAction =
      AsyncAction('_WebSocketStatusStore.retryConnection', context: context);

  @override
  Future<void> retryConnection() {
    return _$retryConnectionAsyncAction.run(() => super.retryConnection());
  }

  late final _$_WebSocketStatusStoreActionController =
      ActionController(name: '_WebSocketStatusStore', context: context);

  @override
  void _updateConnectionState(WebSocketConnectionState newState) {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore._updateConnectionState');
    try {
      return super._updateConnectionState(newState);
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateError(WebSocketError error) {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore._updateError');
    try {
      return super._updateError(error);
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateLastResponseTime(Duration responseTime) {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.updateLastResponseTime');
    try {
      return super.updateLastResponseTime(responseTime);
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateQueuedUpdatesCount(int count) {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.updateQueuedUpdatesCount');
    try {
      return super.updateQueuedUpdatesCount(count);
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showStatusBar() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.showStatusBar');
    try {
      return super.showStatusBar();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideStatusBar() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.hideStatusBar');
    try {
      return super.hideStatusBar();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void minimizeStatusBar() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.minimizeStatusBar');
    try {
      return super.minimizeStatusBar();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void expandStatusBar() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.expandStatusBar');
    try {
      return super.expandStatusBar();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleStatusBarMinimized() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.toggleStatusBarMinimized');
    try {
      return super.toggleStatusBarMinimized();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleConnectionDetails() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.toggleConnectionDetails');
    try {
      return super.toggleConnectionDetails();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showConnectionDetailsAction() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.showConnectionDetailsAction');
    try {
      return super.showConnectionDetailsAction();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideConnectionDetails() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.hideConnectionDetails');
    try {
      return super.hideConnectionDetails();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearError() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.clearError');
    try {
      return super.clearError();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearQueuedUpdates() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.clearQueuedUpdates');
    try {
      return super.clearQueuedUpdates();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void resetReconnectAttempts() {
    final _$actionInfo = _$_WebSocketStatusStoreActionController.startAction(
        name: '_WebSocketStatusStore.resetReconnectAttempts');
    try {
      return super.resetReconnectAttempts();
    } finally {
      _$_WebSocketStatusStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
connectionState: ${connectionState},
lastError: ${lastError},
reconnectAttempts: ${reconnectAttempts},
lastResponseTime: ${lastResponseTime},
lastConnectedTime: ${lastConnectedTime},
queuedUpdatesCount: ${queuedUpdatesCount},
isStatusBarVisible: ${isStatusBarVisible},
isStatusBarMinimized: ${isStatusBarMinimized},
showConnectionDetailsFlag: ${showConnectionDetailsFlag},
isConnected: ${isConnected},
isConnecting: ${isConnecting},
isOffline: ${isOffline},
hasError: ${hasError},
canRetry: ${canRetry},
statusText: ${statusText},
shouldShowOfflineMode: ${shouldShowOfflineMode},
showConnectionDetails: ${showConnectionDetails}
    ''';
  }
}
