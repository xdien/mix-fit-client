import 'package:core/local/models/device.dart';
import 'package:mobx/mobx.dart';

part 'device_store.g.dart';

class DeviceStore = _DeviceStore with _$DeviceStore;

abstract class _DeviceStore with Store {
  @observable
  ObservableList<Device> devices = ObservableList<Device>();

  @action
  void addDevice(Device device) {
    devices.add(device);
  }

  @action
  void updateDeviceStatus(String id, bool isOnline) {
    final deviceIndex = devices.indexWhere((device) => device.id == id);
    if (deviceIndex != -1) {
      devices[deviceIndex] = devices[deviceIndex].copyWith(isOnline: isOnline);
    }
  }

  @computed
  int get totalOnlineDevices => devices.where((device) => device.isOnline).length;

  // Method để load devices từ API (mock data cho ví dụ)
  @action
  Future<void> loadDevices() async {
    devices.addAll([
      // DeviceEntity(id: '1', name: 'Living Room Light', isOnline: true),
      // DeviceEntity(id: '2', name: 'Kitchen Sensor', isOnline: false),
      // DeviceEntity(id: '3', name: 'Bedroom AC', isOnline: true),
    ]);
  }
}