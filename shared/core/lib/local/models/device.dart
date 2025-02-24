
import 'package:freezed_annotation/freezed_annotation.dart';
part 'device.freezed.dart';
part 'device.g.dart';

@freezed
class Device with _$Device {
  const factory Device({
    required int id,
    required String deviceId,
    required String name,
    @Default(false) bool isOnline,
    DateTime? lastSeen,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

