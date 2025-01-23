//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// IoT event type
class IoTEvents {
  /// Instantiate a new enum with the provided [value].
  const IoTEvents._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const sensorData = IoTEvents._(r'sensor_data');
  static const sensorStatus = IoTEvents._(r'sensor_status');
  static const sensorAlert = IoTEvents._(r'sensor_alert');
  static const sensorDataMonitoring = IoTEvents._(r'sensor_data_monitoring');
  static const controlCommand = IoTEvents._(r'control_command');
  static const controlStatus = IoTEvents._(r'control_status');
  static const deviceConnected = IoTEvents._(r'device_connected');
  static const deviceDisconnected = IoTEvents._(r'device_disconnected');
  static const deviceStatus = IoTEvents._(r'device_status');

  /// List of all possible values in this [enum][IoTEvents].
  static const values = <IoTEvents>[
    sensorData,
    sensorStatus,
    sensorAlert,
    sensorDataMonitoring,
    controlCommand,
    controlStatus,
    deviceConnected,
    deviceDisconnected,
    deviceStatus,
  ];

  static IoTEvents? fromJson(dynamic value) => IoTEventsTypeTransformer().decode(value);

  static List<IoTEvents> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <IoTEvents>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = IoTEvents.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [IoTEvents] to String,
/// and [decode] dynamic data back to [IoTEvents].
class IoTEventsTypeTransformer {
  factory IoTEventsTypeTransformer() => _instance ??= const IoTEventsTypeTransformer._();

  const IoTEventsTypeTransformer._();

  String encode(IoTEvents data) => data.value;

  /// Decodes a [dynamic value][data] to a IoTEvents.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  IoTEvents? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'sensor_data': return IoTEvents.sensorData;
        case r'sensor_status': return IoTEvents.sensorStatus;
        case r'sensor_alert': return IoTEvents.sensorAlert;
        case r'sensor_data_monitoring': return IoTEvents.sensorDataMonitoring;
        case r'control_command': return IoTEvents.controlCommand;
        case r'control_status': return IoTEvents.controlStatus;
        case r'device_connected': return IoTEvents.deviceConnected;
        case r'device_disconnected': return IoTEvents.deviceDisconnected;
        case r'device_status': return IoTEvents.deviceStatus;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [IoTEventsTypeTransformer] instance.
  static IoTEventsTypeTransformer? _instance;
}

