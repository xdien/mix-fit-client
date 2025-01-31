//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class DeviceTypeDto {
  /// Returns a new [DeviceTypeDto] instance.
  DeviceTypeDto({
    required this.type,
  });

  /// Available device types
  DeviceTypeDtoTypeEnum type;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DeviceTypeDto &&
    other.type == type;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode);

  @override
  String toString() => 'DeviceTypeDto[type=$type]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
    return json;
  }

  /// Returns a new [DeviceTypeDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static DeviceTypeDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "DeviceTypeDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "DeviceTypeDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return DeviceTypeDto(
        type: DeviceTypeDtoTypeEnum.fromJson(json[r'type'])!,
      );
    }
    return null;
  }

  static List<DeviceTypeDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceTypeDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceTypeDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, DeviceTypeDto> mapFromJson(dynamic json) {
    final map = <String, DeviceTypeDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = DeviceTypeDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of DeviceTypeDto-objects as value to a dart map
  static Map<String, List<DeviceTypeDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<DeviceTypeDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = DeviceTypeDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
  };
}

/// Available device types
class DeviceTypeDtoTypeEnum {
  /// Instantiate a new enum with the provided [value].
  const DeviceTypeDtoTypeEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const lIQUORKILNV1 = DeviceTypeDtoTypeEnum._(r'LIQUOR_KILN_V1');
  static const LIQUOR_KILN = DeviceTypeDtoTypeEnum._(r'LIQUOR-KILN');

  /// List of all possible values in this [enum][DeviceTypeDtoTypeEnum].
  static const values = <DeviceTypeDtoTypeEnum>[
    lIQUORKILNV1,
    LIQUOR_KILN,
  ];

  static DeviceTypeDtoTypeEnum? fromJson(dynamic value) => DeviceTypeDtoTypeEnumTypeTransformer().decode(value);

  static List<DeviceTypeDtoTypeEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <DeviceTypeDtoTypeEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = DeviceTypeDtoTypeEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [DeviceTypeDtoTypeEnum] to String,
/// and [decode] dynamic data back to [DeviceTypeDtoTypeEnum].
class DeviceTypeDtoTypeEnumTypeTransformer {
  factory DeviceTypeDtoTypeEnumTypeTransformer() => _instance ??= const DeviceTypeDtoTypeEnumTypeTransformer._();

  const DeviceTypeDtoTypeEnumTypeTransformer._();

  String encode(DeviceTypeDtoTypeEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a DeviceTypeDtoTypeEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  DeviceTypeDtoTypeEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'LIQUOR_KILN_V1': return DeviceTypeDtoTypeEnum.lIQUORKILNV1;
        case r'LIQUOR-KILN': return DeviceTypeDtoTypeEnum.LIQUOR_KILN;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [DeviceTypeDtoTypeEnumTypeTransformer] instance.
  static DeviceTypeDtoTypeEnumTypeTransformer? _instance;
}


