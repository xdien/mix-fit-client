// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_websocket_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$InventoryWebSocketStore on _InventoryWebSocketStore, Store {
  Computed<List<InventoryItem>>? _$lowStockItemsComputed;

  @override
  List<InventoryItem> get lowStockItems => (_$lowStockItemsComputed ??=
          Computed<List<InventoryItem>>(() => super.lowStockItems,
              name: '_InventoryWebSocketStore.lowStockItems'))
      .value;
  Computed<List<InventoryItem>>? _$outOfStockItemsComputed;

  @override
  List<InventoryItem> get outOfStockItems => (_$outOfStockItemsComputed ??=
          Computed<List<InventoryItem>>(() => super.outOfStockItems,
              name: '_InventoryWebSocketStore.outOfStockItems'))
      .value;
  Computed<int>? _$lowStockCountComputed;

  @override
  int get lowStockCount =>
      (_$lowStockCountComputed ??= Computed<int>(() => super.lowStockCount,
              name: '_InventoryWebSocketStore.lowStockCount'))
          .value;
  Computed<int>? _$outOfStockCountComputed;

  @override
  int get outOfStockCount =>
      (_$outOfStockCountComputed ??= Computed<int>(() => super.outOfStockCount,
              name: '_InventoryWebSocketStore.outOfStockCount'))
          .value;

  late final _$inventoryItemsAtom =
      Atom(name: '_InventoryWebSocketStore.inventoryItems', context: context);

  @override
  ObservableMap<String, InventoryItem> get inventoryItems {
    _$inventoryItemsAtom.reportRead();
    return super.inventoryItems;
  }

  @override
  set inventoryItems(ObservableMap<String, InventoryItem> value) {
    _$inventoryItemsAtom.reportWrite(value, super.inventoryItems, () {
      super.inventoryItems = value;
    });
  }

  late final _$lastUpdateTimeAtom =
      Atom(name: '_InventoryWebSocketStore.lastUpdateTime', context: context);

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

  late final _$isReceivingUpdatesAtom = Atom(
      name: '_InventoryWebSocketStore.isReceivingUpdates', context: context);

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

  late final _$totalItemsInStockAtom = Atom(
      name: '_InventoryWebSocketStore.totalItemsInStock', context: context);

  @override
  int get totalItemsInStock {
    _$totalItemsInStockAtom.reportRead();
    return super.totalItemsInStock;
  }

  @override
  set totalItemsInStock(int value) {
    _$totalItemsInStockAtom.reportWrite(value, super.totalItemsInStock, () {
      super.totalItemsInStock = value;
    });
  }

  late final _$totalInventoryValueAtom = Atom(
      name: '_InventoryWebSocketStore.totalInventoryValue', context: context);

  @override
  double get totalInventoryValue {
    _$totalInventoryValueAtom.reportRead();
    return super.totalInventoryValue;
  }

  @override
  set totalInventoryValue(double value) {
    _$totalInventoryValueAtom.reportWrite(value, super.totalInventoryValue, () {
      super.totalInventoryValue = value;
    });
  }

  late final _$_InventoryWebSocketStoreActionController =
      ActionController(name: '_InventoryWebSocketStore', context: context);

  @override
  void _handleInventoryItemUpdate(Map<String, dynamic> data) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._handleInventoryItemUpdate');
    try {
      return super._handleInventoryItemUpdate(data);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleInventoryItemAdded(Map<String, dynamic> data) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._handleInventoryItemAdded');
    try {
      return super._handleInventoryItemAdded(data);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleInventoryItemRemoved(Map<String, dynamic> data) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._handleInventoryItemRemoved');
    try {
      return super._handleInventoryItemRemoved(data);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleBulkInventoryUpdate(Map<String, dynamic> data) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._handleBulkInventoryUpdate');
    try {
      return super._handleBulkInventoryUpdate(data);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleLowStockAlert(Map<String, dynamic> data) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._handleLowStockAlert');
    try {
      return super._handleLowStockAlert(data);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateLastUpdateTime() {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._updateLastUpdateTime');
    try {
      return super._updateLastUpdateTime();
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _recalculateTotals() {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore._recalculateTotals');
    try {
      return super._recalculateTotals();
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addInventoryItem(InventoryItem item) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore.addInventoryItem');
    try {
      return super.addInventoryItem(item);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateInventoryItems(List<InventoryItem> items) {
    final _$actionInfo = _$_InventoryWebSocketStoreActionController.startAction(
        name: '_InventoryWebSocketStore.updateInventoryItems');
    try {
      return super.updateInventoryItems(items);
    } finally {
      _$_InventoryWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
inventoryItems: ${inventoryItems},
lastUpdateTime: ${lastUpdateTime},
isReceivingUpdates: ${isReceivingUpdates},
totalItemsInStock: ${totalItemsInStock},
totalInventoryValue: ${totalInventoryValue},
lowStockItems: ${lowStockItems},
outOfStockItems: ${outOfStockItems},
lowStockCount: ${lowStockCount},
outOfStockCount: ${outOfStockCount}
    ''';
  }
}
