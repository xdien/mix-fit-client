//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceStatusEventDto {
  /// Returns a new [DeviceStatusEventDto] instance.
  DeviceStatusEventDto({
    required this.eventType,
    required this.deviceId,
    required this.status,
    required this.lastHeartbeat,
    this.batteryLevel,
    this.firmwareVersion,
    this.ipAddress,
    this.signalStrength,
  });

  IoTEvents eventType;

  /// Unique identifier of the device
  String deviceId;

  /// Device status
  DeviceStatusEventDtoStatusEnum status;

  /// Last heartbeat timestamp
  String lastHeartbeat;

  /// Battery level percentage
  ///
  /// Minimum value: 0
  /// Maximum value: 100
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? batteryLevel;

  /// Firmware version
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? firmwareVersion;

  /// Device IP address
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? ipAddress;

  /// Signal strength in dBm
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? signalStrength;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceStatusEventDto &&
    other.eventType == eventType &&
    other.deviceId == deviceId &&
    other.status == status &&
    other.lastHeartbeat == lastHeartbeat &&
    other.batteryLevel == batteryLevel &&
    other.firmwareVersion == firmwareVersion &&
    other.ipAddress == ipAddress &&
    other.signalStrength == signalStrength;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eventType.hashCode) +
    (deviceId.hashCode) +
    (status.hashCode) +
    (lastHeartbeat.hashCode) +
    (batteryLevel == null ? 0 : batteryLevel!.hashCode) +
    (firmwareVersion == null ? 0 : firmwareVersion!.hashCode) +
    (ipAddress == null ? 0 : ipAddress!.hashCode) +
    (signalStrength == null ? 0 : signalStrength!.hashCode);

  @override
  String toString() => 'DeviceStatusEventDto[eventType=$eventType, deviceId=$deviceId, status=$status, lastHeartbeat=$lastHeartbeat, batteryLevel=$batteryLevel, firmwareVersion=$firmwareVersion, ipAddress=$ipAddress, signalStrength=$signalStrength]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eventType'] = this.eventType;
      json[r'deviceId'] = this.deviceId;
      json[r'status'] = this.status;
      json[r'lastHeartbeat'] = this.lastHeartbeat;
    if (this.batteryLevel != null) {
      json[r'batteryLevel'] = this.batteryLevel;
    } else {
      json[r'batteryLevel'] = null;
    }
    if (this.firmwareVersion != null) {
      json[r'firmwareVersion'] = this.firmwareVersion;
    } else {
      json[r'firmwareVersion'] = null;
    }
    if (this.ipAddress != null) {
      json[r'ipAddress'] = this.ipAddress;
    } else {
      json[r'ipAddress'] = null;
    }
    if (this.signalStrength != null) {
      json[r'signalStrength'] = this.signalStrength;
    } else {
      json[r'signalStrength'] = null;
    }
    return json;
  }

  /// Returns a new [DeviceStatusEventDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceStatusEventDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DeviceStatusEventDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DeviceStatusEventDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DeviceStatusEventDto(
        eventType: IoTEvents.fromJson(json[r'eventType'])!,
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
        status: DeviceStatusEventDtoStatusEnum.fromJson(json[r'status'])!,
        lastHeartbeat: mapValueOfType<String>(json, r'lastHeartbeat')!,
        batteryLevel: num.parse('${json[r'batteryLevel']}'),
        firmwareVersion: mapValueOfType<String>(json, r'firmwareVersion'),
        ipAddress: mapValueOfType<String>(json, r'ipAddress'),
        signalStrength: num.parse('${json[r'signalStrength']}'),
      );
    }
    return null;
  }

  static List<DeviceStatusEventDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceStatusEventDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceStatusEventDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceStatusEventDto> mapFromJson(dynamic json) {
    final map = <String, DeviceStatusEventDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceStatusEventDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceStatusEventDto-objects as value to a dart map
  static Map<String, List<DeviceStatusEventDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceStatusEventDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceStatusEventDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eventType',
    'deviceId',
    'status',
    'lastHeartbeat',
  };
}

/// Device status
class DeviceStatusEventDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const DeviceStatusEventDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const ONLINE = DeviceStatusEventDtoStatusEnum._(r'ONLINE');
  static const OFFLINE = DeviceStatusEventDtoStatusEnum._(r'OFFLINE');
  static const MAINTENANCE = DeviceStatusEventDtoStatusEnum._(r'MAINTENANCE');
  static const ERROR = DeviceStatusEventDtoStatusEnum._(r'ERROR');

  /// List of all possible values in this [enum][DeviceStatusEventDtoStatusEnum].
  static const values = <DeviceStatusEventDtoStatusEnum>[
    ONLINE,
    OFFLINE,
    MAINTENANCE,
    ERROR,
  ];

  static DeviceStatusEventDtoStatusEnum? fromJson(dynamic value) => DeviceStatusEventDtoStatusEnumTypeTransformer().decode(value);

  static List<DeviceStatusEventDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceStatusEventDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceStatusEventDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceStatusEventDtoStatusEnum] to String,
/// and [decode] dynamic data back to [DeviceStatusEventDtoStatusEnum].
class DeviceStatusEventDtoStatusEnumTypeTransformer {
  factory DeviceStatusEventDtoStatusEnumTypeTransformer() => _instance ??= const DeviceStatusEventDtoStatusEnumTypeTransformer._();

  const DeviceStatusEventDtoStatusEnumTypeTransformer._();

  String encode(DeviceStatusEventDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DeviceStatusEventDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceStatusEventDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'ONLINE': return DeviceStatusEventDtoStatusEnum.ONLINE;
        case r'OFFLINE': return DeviceStatusEventDtoStatusEnum.OFFLINE;
        case r'MAINTENANCE': return DeviceStatusEventDtoStatusEnum.MAINTENANCE;
        case r'ERROR': return DeviceStatusEventDtoStatusEnum.ERROR;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DeviceStatusEventDtoStatusEnumTypeTransformer] instance.
  static DeviceStatusEventDtoStatusEnumTypeTransformer? _instance;
}


