//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// Available command actions for liquor kiln
class DeviceCommandEnum {
  /// Instantiate a new enum with the provided [value].
  const DeviceCommandEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const POWER_PUMP_WATER = DeviceCommandEnum._(r'CMD_POWER_PUMP_WATER');
  static const SET_TEMPERATURE = DeviceCommandEnum._(r'CMD_SET_TEMPERATURE');

  /// List of all possible values in this [enum][DeviceCommandEnum].
  static const values = <DeviceCommandEnum>[
    POWER_PUMP_WATER,
    SET_TEMPERATURE,
  ];

  static DeviceCommandEnum? fromJson(dynamic value) => DeviceCommandEnumTypeTransformer().decode(value);

  static List<DeviceCommandEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceCommandEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceCommandEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceCommandEnum] to String,
/// and [decode] dynamic data back to [DeviceCommandEnum].
class DeviceCommandEnumTypeTransformer {
  factory DeviceCommandEnumTypeTransformer() => _instance ??= const DeviceCommandEnumTypeTransformer._();

  const DeviceCommandEnumTypeTransformer._();

  String encode(DeviceCommandEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DeviceCommandEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceCommandEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'CMD_POWER_PUMP_WATER': return DeviceCommandEnum.POWER_PUMP_WATER;
        case r'CMD_SET_TEMPERATURE': return DeviceCommandEnum.SET_TEMPERATURE;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DeviceCommandEnumTypeTransformer] instance.
  static DeviceCommandEnumTypeTransformer? _instance;
}

