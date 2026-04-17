// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'websocket_store_manager.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$WebSocketStoreManager on _WebSocketStoreManager, Store {
  Computed<bool>? _$hasActiveStoresComputed;

  @override
  bool get hasActiveStores =>
      (_$hasActiveStoresComputed ??= Computed<bool>(() => super.hasActiveStores,
              name: '_WebSocketStoreManager.hasActiveStores'))
          .value;
  Computed<String>? _$connectionStatusTextComputed;

  @override
  String get connectionStatusText => (_$connectionStatusTextComputed ??=
          Computed<String>(() => super.connectionStatusText,
              name: '_WebSocketStoreManager.connectionStatusText'))
      .value;
  Computed<bool>? _$shouldShowConnectionIndicatorComputed;

  @override
  bool get shouldShowConnectionIndicator =>
      (_$shouldShowConnectionIndicatorComputed ??= Computed<bool>(
              () => super.shouldShowConnectionIndicator,
              name: '_WebSocketStoreManager.shouldShowConnectionIndicator'))
          .value;
  Computed<Map<String, dynamic>>? _$dataSummaryComputed;

  @override
  Map<String, dynamic> get dataSummary => (_$dataSummaryComputed ??=
          Computed<Map<String, dynamic>>(() => super.dataSummary,
              name: '_WebSocketStoreManager.dataSummary'))
      .value;
  Computed<List<String>>? _$allCriticalAlertsComputed;

  @override
  List<String> get allCriticalAlerts => (_$allCriticalAlertsComputed ??=
          Computed<List<String>>(() => super.allCriticalAlerts,
              name: '_WebSocketStoreManager.allCriticalAlerts'))
      .value;
  Computed<Map<String, dynamic>>? _$connectionHealthComputed;

  @override
  Map<String, dynamic> get connectionHealth => (_$connectionHealthComputed ??=
          Computed<Map<String, dynamic>>(() => super.connectionHealth,
              name: '_WebSocketStoreManager.connectionHealth'))
      .value;

  late final _$connectionStateAtom =
      Atom(name: '_WebSocketStoreManager.connectionState', context: context);

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

  late final _$isConnectedAtom =
      Atom(name: '_WebSocketStoreManager.isConnected', context: context);

  @override
  bool get isConnected {
    _$isConnectedAtom.reportRead();
    return super.isConnected;
  }

  @override
  set isConnected(bool value) {
    _$isConnectedAtom.reportWrite(value, super.isConnected, () {
      super.isConnected = value;
    });
  }

  late final _$lastConnectionTimeAtom =
      Atom(name: '_WebSocketStoreManager.lastConnectionTime', context: context);

  @override
  DateTime? get lastConnectionTime {
    _$lastConnectionTimeAtom.reportRead();
    return super.lastConnectionTime;
  }

  @override
  set lastConnectionTime(DateTime? value) {
    _$lastConnectionTimeAtom.reportWrite(value, super.lastConnectionTime, () {
      super.lastConnectionTime = value;
    });
  }

  late final _$reconnectAttemptsAtom =
      Atom(name: '_WebSocketStoreManager.reconnectAttempts', context: context);

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

  late final _$lastErrorAtom =
      Atom(name: '_WebSocketStoreManager.lastError', context: context);

  @override
  String? get lastError {
    _$lastErrorAtom.reportRead();
    return super.lastError;
  }

  @override
  set lastError(String? value) {
    _$lastErrorAtom.reportWrite(value, super.lastError, () {
      super.lastError = value;
    });
  }

  late final _$connectAsyncAction =
      AsyncAction('_WebSocketStoreManager.connect', context: context);

  @override
  Future<void> connect() {
    return _$connectAsyncAction.run(() => super.connect());
  }

  late final _$disconnectAsyncAction =
      AsyncAction('_WebSocketStoreManager.disconnect', context: context);

  @override
  Future<void> disconnect() {
    return _$disconnectAsyncAction.run(() => super.disconnect());
  }

  late final _$refreshAllStoresAsyncAction =
      AsyncAction('_WebSocketStoreManager.refreshAllStores', context: context);

  @override
  Future<void> refreshAllStores() {
    return _$refreshAllStoresAsyncAction.run(() => super.refreshAllStores());
  }

  late final _$handleAppLifecycleChangeAsyncAction = AsyncAction(
      '_WebSocketStoreManager.handleAppLifecycleChange',
      context: context);

  @override
  Future<void> handleAppLifecycleChange(AppLifecycleState state) {
    return _$handleAppLifecycleChangeAsyncAction
        .run(() => super.handleAppLifecycleChange(state));
  }

  late final _$_WebSocketStoreManagerActionController =
      ActionController(name: '_WebSocketStoreManager', context: context);

  @override
  void clearAllAlerts() {
    final _$actionInfo = _$_WebSocketStoreManagerActionController.startAction(
        name: '_WebSocketStoreManager.clearAllAlerts');
    try {
      return super.clearAllAlerts();
    } finally {
      _$_WebSocketStoreManagerActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
connectionState: ${connectionState},
isConnected: ${isConnected},
lastConnectionTime: ${lastConnectionTime},
reconnectAttempts: ${reconnectAttempts},
lastError: ${lastError},
hasActiveStores: ${hasActiveStores},
connectionStatusText: ${connectionStatusText},
shouldShowConnectionIndicator: ${shouldShowConnectionIndicator},
dataSummary: ${dataSummary},
allCriticalAlerts: ${allCriticalAlerts},
connectionHealth: ${connectionHealth}
    ''';
  }
}
