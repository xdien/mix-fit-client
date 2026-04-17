import 'package:drift/drift.dart';

import '../database/database.dart';
import '../models/device.dart';

class DeviceTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceId => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isOnline => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastSeen => dateTime().nullable()();
}

extension DeviceTableMapping on DeviceTable {
  Device toModel(DeviceTableData data) => Device(
    id: data.id,
    deviceId: data.deviceId,
    name: data.name,
    isOnline: data.isOnline,
    lastSeen: data.lastSeen,
  );
}


extension DeviceCompanionMapping on Device {
  DeviceTableCompanion toCompanion() => DeviceTableCompanion.insert(
    deviceId: deviceId,
    name: name,
    isOnline: Value(isOnline),
    lastSeen: Value(lastSeen),
  );
}