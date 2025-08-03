// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_websocket_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$CustomerWebSocketStore on _CustomerWebSocketStore, Store {
  Computed<List<Customer>>? _$recentlyUpdatedCustomersComputed;

  @override
  List<Customer> get recentlyUpdatedCustomers =>
      (_$recentlyUpdatedCustomersComputed ??= Computed<List<Customer>>(
              () => super.recentlyUpdatedCustomers,
              name: '_CustomerWebSocketStore.recentlyUpdatedCustomers'))
          .value;
  Computed<List<Customer>>? _$vipCustomersComputed;

  @override
  List<Customer> get vipCustomers => (_$vipCustomersComputed ??=
          Computed<List<Customer>>(() => super.vipCustomers,
              name: '_CustomerWebSocketStore.vipCustomers'))
      .value;
  Computed<int>? _$vipCustomerCountComputed;

  @override
  int get vipCustomerCount => (_$vipCustomerCountComputed ??= Computed<int>(
          () => super.vipCustomerCount,
          name: '_CustomerWebSocketStore.vipCustomerCount'))
      .value;

  late final _$customersAtom =
      Atom(name: '_CustomerWebSocketStore.customers', context: context);

  @override
  ObservableMap<String, Customer> get customers {
    _$customersAtom.reportRead();
    return super.customers;
  }

  @override
  set customers(ObservableMap<String, Customer> value) {
    _$customersAtom.reportWrite(value, super.customers, () {
      super.customers = value;
    });
  }

  late final _$lastUpdateTimeAtom =
      Atom(name: '_CustomerWebSocketStore.lastUpdateTime', context: context);

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
      name: '_CustomerWebSocketStore.isReceivingUpdates', context: context);

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

  late final _$totalCustomersAtom =
      Atom(name: '_CustomerWebSocketStore.totalCustomers', context: context);

  @override
  int get totalCustomers {
    _$totalCustomersAtom.reportRead();
    return super.totalCustomers;
  }

  @override
  set totalCustomers(int value) {
    _$totalCustomersAtom.reportWrite(value, super.totalCustomers, () {
      super.totalCustomers = value;
    });
  }

  late final _$activeCustomersAtom =
      Atom(name: '_CustomerWebSocketStore.activeCustomers', context: context);

  @override
  int get activeCustomers {
    _$activeCustomersAtom.reportRead();
    return super.activeCustomers;
  }

  @override
  set activeCustomers(int value) {
    _$activeCustomersAtom.reportWrite(value, super.activeCustomers, () {
      super.activeCustomers = value;
    });
  }

  late final _$conflictResolutionMessageAtom = Atom(
      name: '_CustomerWebSocketStore.conflictResolutionMessage',
      context: context);

  @override
  String? get conflictResolutionMessage {
    _$conflictResolutionMessageAtom.reportRead();
    return super.conflictResolutionMessage;
  }

  @override
  set conflictResolutionMessage(String? value) {
    _$conflictResolutionMessageAtom
        .reportWrite(value, super.conflictResolutionMessage, () {
      super.conflictResolutionMessage = value;
    });
  }

  late final _$_CustomerWebSocketStoreActionController =
      ActionController(name: '_CustomerWebSocketStore', context: context);

  @override
  void _handleCustomerUpdate(Map<String, dynamic> data) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._handleCustomerUpdate');
    try {
      return super._handleCustomerUpdate(data);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleCustomerCreated(Map<String, dynamic> data) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._handleCustomerCreated');
    try {
      return super._handleCustomerCreated(data);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleCustomerDeleted(Map<String, dynamic> data) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._handleCustomerDeleted');
    try {
      return super._handleCustomerDeleted(data);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleCustomerStatusChanged(Map<String, dynamic> data) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._handleCustomerStatusChanged');
    try {
      return super._handleCustomerStatusChanged(data);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _handleCustomerConflict(Map<String, dynamic> data) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._handleCustomerConflict');
    try {
      return super._handleCustomerConflict(data);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateLastUpdateTime() {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._updateLastUpdateTime');
    try {
      return super._updateLastUpdateTime();
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _recalculateTotals() {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore._recalculateTotals');
    try {
      return super._recalculateTotals();
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void addCustomer(Customer customer) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore.addCustomer');
    try {
      return super.addCustomer(customer);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCustomers(List<Customer> customerList) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore.updateCustomers');
    try {
      return super.updateCustomers(customerList);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearConflictMessage() {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore.clearConflictMessage');
    try {
      return super.clearConflictMessage();
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void acceptServerVersion(String customerId) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore.acceptServerVersion');
    try {
      return super.acceptServerVersion(customerId);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void keepLocalVersion(String customerId) {
    final _$actionInfo = _$_CustomerWebSocketStoreActionController.startAction(
        name: '_CustomerWebSocketStore.keepLocalVersion');
    try {
      return super.keepLocalVersion(customerId);
    } finally {
      _$_CustomerWebSocketStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
customers: ${customers},
lastUpdateTime: ${lastUpdateTime},
isReceivingUpdates: ${isReceivingUpdates},
totalCustomers: ${totalCustomers},
activeCustomers: ${activeCustomers},
conflictResolutionMessage: ${conflictResolutionMessage},
recentlyUpdatedCustomers: ${recentlyUpdatedCustomers},
vipCustomers: ${vipCustomers},
vipCustomerCount: ${vipCustomerCount}
    ''';
  }
}
