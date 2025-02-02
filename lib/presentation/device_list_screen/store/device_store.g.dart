// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$DeviceStore on _DeviceStore, Store {
  Computed<int>? _$totalOnlineDevicesComputed;

  @override
  int get totalOnlineDevices => (_$totalOnlineDevicesComputed ??= Computed<int>(
          () => super.totalOnlineDevices,
          name: '_DeviceStore.totalOnlineDevices'))
      .value;

  late final _$devicesAtom =
      Atom(name: '_DeviceStore.devices', context: context);

  @override
  ObservableList<DeviceEntity> get devices {
    _$devicesAtom.reportRead();
    return super.devices;
  }

  @override
  set devices(ObservableList<DeviceEntity> value) {
    _$devicesAtom.reportWrite(value, super.devices, () {
      super.devices = value;
    });
  }

  late final _$loadDevicesAsyncAction =
      AsyncAction('_DeviceStore.loadDevices', context: context);

  @override
  Future<void> loadDevices() {
    return _$loadDevicesAsyncAction.run(() => super.loadDevices());
  }

  late final _$_DeviceStoreActionController =
      ActionController(name: '_DeviceStore', context: context);

  @override
  void addDevice(DeviceEntity device) {
    final _$actionInfo = _$_DeviceStoreActionController.startAction(
        name: '_DeviceStore.addDevice');
    try {
      return super.addDevice(device);
    } finally {
      _$_DeviceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateDeviceStatus(String id, bool isOnline) {
    final _$actionInfo = _$_DeviceStoreActionController.startAction(
        name: '_DeviceStore.updateDeviceStatus');
    try {
      return super.updateDeviceStatus(id, isOnline);
    } finally {
      _$_DeviceStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
devices: ${devices},
totalOnlineDevices: ${totalOnlineDevices}
    ''';
  }
}
