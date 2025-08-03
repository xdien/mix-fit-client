// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_websocket_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$OrderWebSocketStore on _OrderWebSocketStore, Store {
  Computed<List<Order>>? _$recentOrdersComputed;

  @override
  List<Order> get recentOrders => (_$recentOrdersComputed ??=
          Computed<List<Order>>(() => super.recentOrders,
              name: '_OrderWebSocketStore.recentOrders'))
      .value;
  Computed<List<Order>>? _$urgentOrdersComputed;

  @override
  List<Order> get urgentOrders => (_$urgentOrdersComputed ??=
          Computed<List<Order>>(() => super.urgentOrders,
              name: '_OrderWebSocketStore.urgentOrders'))
      .value;
  Computed<List<Order>>? _$delayedOrdersComputed;

  @override
  List<Order> get delayedOrders => (_$delayedOrdersComputed ??=
          Computed<List<Order>>(() => super.delayedOrders,
              name: '_OrderWebSocketStore.delayedOrders'))
      .value;
  Computed<int>? _$urgentOrderCountComputed;

  @override
  int get urgentOrderCount => (_$urgentOrderCountComputed ??= Computed<int>(
          () => super.urgentOrderCount,
          name: '_OrderWebSocketStore.urgentOrderCount'))
      .value;
  Computed<int>? _$delayedOrderCountComputed;

  @override
  int get delayedOrderCount => (_$delayedOrderCountComputed ??= Computed<int>(
          () => super.delayedOrderCount,
          name: '_OrderWebSocketStore.delayedOrderCount'))
      .value;

  late final _$ordersAtom =
      Atom(name: '_OrderWebSocketStore.orders', context: context);

  @override
  ObservableMap<String, Order> get orders {
    _$ordersAtom.reportRead();
    return super.orders;
  }

  @override
  set orders(ObservableMap<String, Order> value) {
    _$ordersAtom.reportWrite(value, super.orders, () {
      super.orders = value;
    });
  }

  late final _$lastUpdateTimeAtom =
      Atom(name: '_OrderWebSocketStore.lastUpdateTime', context: context);

  @override
  DateTime? get lastUpdateTime {
    _$lastUpdateTimeAtom.reportRead();
    return super.lastUpdateTime;
  }

  @override
  set lastUpdateTime(DateTime? value) {
    _$lastUpdateTimeAtom.reportWrite(value, super.lastUpdateTime, () {
      super.lastUpdateTime = value;
    });
  }

  late final _$isReceivingUpdatesAtom =
      Atom(name: '_OrderWebSocketStore.isReceivingUpdates', context: context);

  @override
  bool get isReceivingUpdates {
    _$isReceivingUpdatesAtom.reportRead();
    return super.isReceivingUpdates;
  }

  @override
  set isReceivingUpdates(bool value) {
    _$isReceivingUpdatesAtom.reportWrite(value, super.isReceivingUpdates, () {
      super.isReceivingUpdates = value;
    });
  }

  late final _$totalOrdersAtom =
      Atom(name: '_OrderWebSocketStore.totalOrders', context: context);

  @override
  int get totalOrders {
    _$totalOrdersAtom.reportRead();
    return super.totalOrders;
  }

  @override
  set totalOrders(int value) {
    _$totalOrdersAtom.reportWrite(value, super.totalOrders, () {
      super.totalOrders = value;
    });
  }

  late final _$pendingOrdersAtom =
      Atom(name: '_OrderWebSocketStore.pendingOrders', context: context);

  @override
  int get pendingOrders {
    _$pendingOrdersAtom.reportRead();
    return super.pendingOrders;
  }

  @override
  set pendingOrders(int value) {
    _$pendingOrdersAtom.reportWrite(value, super.pendingOrders, () {
      super.pendingOrders = value;
    });
  }

  late final _$completedOrdersAtom =
      Atom(name: '_OrderWebSocketStore.completedOrders', context: context);

  @override
  int get completedOrders {
    _$completedOrdersAtom.reportRead();
    return super.completedOrders;
  }

  @override
  set completedOrders(int value) {
    _$completedOrdersAtom.reportWrite(value, super.completedOrders, () {
      super.completedOrders = value;
    });
  }

  late final _$totalOrderValueAtom =
      Atom(name: '_OrderWebSocketStore.totalOrderValue', context: context);

  @override
  double get totalOrderValue {
    _$totalOrderValueAtom.reportRead();
    return super.totalOrderValue;
  }

  @override
  set totalOrderValue(double value) {
    _$totalOrderValueAtom.reportWrite(value, super.totalOrderValue, () {
      super.totalOrderValue = value;
    });
  }

  late final _$criticalAlertsAtom =
      Atom(name: '_OrderWebSocketStore.criticalAlerts', context: context);

  @override
  ObservableList<String> get criticalAlerts {
    _$criticalAlertsAtom.reportRead();
    return super.criticalAlerts;
  }

  @override
  set criticalAlerts(ObservableList<String> value) {
    _$criticalAlertsAtom.reportWrite(value, super.criticalAlerts, () {
      super.criticalAlerts = value;
    });
  }

  late final _$_OrderWebSocketStoreActionController =
      ActionController(name: '_OrderWebSocketStore', context: context);

  @override
  void _handleOrderCreated(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleOrderCreated');
    try {
      return super._handleOrderCreated(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleOrderUpdated(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleOrderUpdated');
    try {
      return super._handleOrderUpdated(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleOrderStatusChanged(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleOrderStatusChanged');
    try {
      return super._handleOrderStatusChanged(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleOrderCancelled(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleOrderCancelled');
    try {
      return super._handleOrderCancelled(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleOrderPriorityChanged(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleOrderPriorityChanged');
    try {
      return super._handleOrderPriorityChanged(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleCriticalAlert(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleCriticalAlert');
    try {
      return super._handleCriticalAlert(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleBulkOrderUpdate(Map<String, dynamic> data) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._handleBulkOrderUpdate');
    try {
      return super._handleBulkOrderUpdate(data);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateLastUpdateTime() {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._updateLastUpdateTime');
    try {
      return super._updateLastUpdateTime();
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _recalculateTotals() {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore._recalculateTotals');
    try {
      return super._recalculateTotals();
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addOrder(Order order) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore.addOrder');
    try {
      return super.addOrder(order);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateOrders(List<Order> orderList) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore.updateOrders');
    try {
      return super.updateOrders(orderList);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearCriticalAlert(int index) {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore.clearCriticalAlert');
    try {
      return super.clearCriticalAlert(index);
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearAllCriticalAlerts() {
    final _$actionInfo = _$_OrderWebSocketStoreActionController.startAction(
        name: '_OrderWebSocketStore.clearAllCriticalAlerts');
    try {
      return super.clearAllCriticalAlerts();
    } finally {
      _$_OrderWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
orders: ${orders},
lastUpdateTime: ${lastUpdateTime},
isReceivingUpdates: ${isReceivingUpdates},
totalOrders: ${totalOrders},
pendingOrders: ${pendingOrders},
completedOrders: ${completedOrders},
totalOrderValue: ${totalOrderValue},
criticalAlerts: ${criticalAlerts},
recentOrders: ${recentOrders},
urgentOrders: ${urgentOrders},
delayedOrders: ${delayedOrders},
urgentOrderCount: ${urgentOrderCount},
delayedOrderCount: ${delayedOrderCount}
    ''';
  }
}
