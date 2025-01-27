//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class LiquorKilnCommandActionDto {
  /// Returns a new [LiquorKilnCommandActionDto] instance.
  LiquorKilnCommandActionDto({
    required this.action,
  });

  /// Available command actions for liquor kiln
  LiquorKilnCommandActionDtoActionEnum action;

  @override
  bool operator ==(Object other) => identical(this, other) || other is LiquorKilnCommandActionDto &&
    other.action == action;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (action.hashCode);

  @override
  String toString() => 'LiquorKilnCommandActionDto[action=$action]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'action'] = this.action;
    return json;
  }

  /// Returns a new [LiquorKilnCommandActionDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static LiquorKilnCommandActionDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "LiquorKilnCommandActionDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "LiquorKilnCommandActionDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return LiquorKilnCommandActionDto(
        action: LiquorKilnCommandActionDtoActionEnum.fromJson(json[r'action'])!,
      );
    }
    return null;
  }

  static List<LiquorKilnCommandActionDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LiquorKilnCommandActionDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LiquorKilnCommandActionDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, LiquorKilnCommandActionDto> mapFromJson(dynamic json) {
    final map = <String, LiquorKilnCommandActionDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = LiquorKilnCommandActionDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of LiquorKilnCommandActionDto-objects as value to a dart map
  static Map<String, List<LiquorKilnCommandActionDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<LiquorKilnCommandActionDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = LiquorKilnCommandActionDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'action',
  };
}

/// Available command actions for liquor kiln
class LiquorKilnCommandActionDtoActionEnum {
  /// Instantiate a new enum with the provided [value].
  const LiquorKilnCommandActionDtoActionEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const hEATER1 = LiquorKilnCommandActionDtoActionEnum._(r'HEATER_1');
  static const hEATER2 = LiquorKilnCommandActionDtoActionEnum._(r'HEATER_2');
  static const hEATER3 = LiquorKilnCommandActionDtoActionEnum._(r'HEATER_3');
  static const SET_OVERHEAT_TEMP = LiquorKilnCommandActionDtoActionEnum._(r'SET_OVERHEAT_TEMP');
  static const SET_COOLING_TEMP = LiquorKilnCommandActionDtoActionEnum._(r'SET_COOLING_TEMP');
  static const SET_DISTILLATION_TIME = LiquorKilnCommandActionDtoActionEnum._(r'SET_DISTILLATION_TIME');
  static const RESET_WIFI = LiquorKilnCommandActionDtoActionEnum._(r'RESET_WIFI');
  static const SET_DISTILLATION_DAY_TEMP_MIN = LiquorKilnCommandActionDtoActionEnum._(r'SET_DISTILLATION_DAY_TEMP_MIN');
  static const SET_DISTILLATION_DAY_TEMP_MAX = LiquorKilnCommandActionDtoActionEnum._(r'SET_DISTILLATION_DAY_TEMP_MAX');
  static const SET_DISTILLATION_NIGHT_TEMP_MIN = LiquorKilnCommandActionDtoActionEnum._(r'SET_DISTILLATION_NIGHT_TEMP_MIN');
  static const SET_DISTILLATION_NIGHT_TEMP_MAX = LiquorKilnCommandActionDtoActionEnum._(r'SET_DISTILLATION_NIGHT_TEMP_MAX');
  static const UPDATE_TIME_NTP = LiquorKilnCommandActionDtoActionEnum._(r'UPDATE_TIME_NTP');
  static const SET_TOTAL_DAY_DISTILLATION_TIME = LiquorKilnCommandActionDtoActionEnum._(r'SET_TOTAL_DAY_DISTILLATION_TIME');
  static const SET_TOTAL_NIGHT_DISTILLATION_TIME = LiquorKilnCommandActionDtoActionEnum._(r'SET_TOTAL_NIGHT_DISTILLATION_TIME');
  static const cMDHEATER1 = LiquorKilnCommandActionDtoActionEnum._(r'CMD_HEATER_1');
  static const cMDHEATER2 = LiquorKilnCommandActionDtoActionEnum._(r'CMD_HEATER_2');
  static const CMD_HEATER_SYS = LiquorKilnCommandActionDtoActionEnum._(r'CMD_HEATER_SYS');
  static const TURN_ON_DAY_DISTILLATION = LiquorKilnCommandActionDtoActionEnum._(r'TURN_ON_DAY_DISTILLATION');
  static const TURN_ON_NIGHT_DISTILLATION = LiquorKilnCommandActionDtoActionEnum._(r'TURN_ON_NIGHT_DISTILLATION');
  static const TURN_OFF_DISTILLATION = LiquorKilnCommandActionDtoActionEnum._(r'TURN_OFF_DISTILLATION');
  static const CMD_POWER_PUMP_WATER = LiquorKilnCommandActionDtoActionEnum._(r'CMD_POWER_PUMP_WATER');

  /// List of all possible values in this [enum][LiquorKilnCommandActionDtoActionEnum].
  static const values = <LiquorKilnCommandActionDtoActionEnum>[
    hEATER1,
    hEATER2,
    hEATER3,
    SET_OVERHEAT_TEMP,
    SET_COOLING_TEMP,
    SET_DISTILLATION_TIME,
    RESET_WIFI,
    SET_DISTILLATION_DAY_TEMP_MIN,
    SET_DISTILLATION_DAY_TEMP_MAX,
    SET_DISTILLATION_NIGHT_TEMP_MIN,
    SET_DISTILLATION_NIGHT_TEMP_MAX,
    UPDATE_TIME_NTP,
    SET_TOTAL_DAY_DISTILLATION_TIME,
    SET_TOTAL_NIGHT_DISTILLATION_TIME,
    cMDHEATER1,
    cMDHEATER2,
    CMD_HEATER_SYS,
    TURN_ON_DAY_DISTILLATION,
    TURN_ON_NIGHT_DISTILLATION,
    TURN_OFF_DISTILLATION,
    CMD_POWER_PUMP_WATER,
  ];

  static LiquorKilnCommandActionDtoActionEnum? fromJson(dynamic value) => LiquorKilnCommandActionDtoActionEnumTypeTransformer().decode(value);

  static List<LiquorKilnCommandActionDtoActionEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <LiquorKilnCommandActionDtoActionEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = LiquorKilnCommandActionDtoActionEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [LiquorKilnCommandActionDtoActionEnum] to String,
/// and [decode] dynamic data back to [LiquorKilnCommandActionDtoActionEnum].
class LiquorKilnCommandActionDtoActionEnumTypeTransformer {
  factory LiquorKilnCommandActionDtoActionEnumTypeTransformer() => _instance ??= const LiquorKilnCommandActionDtoActionEnumTypeTransformer._();

  const LiquorKilnCommandActionDtoActionEnumTypeTransformer._();

  String encode(LiquorKilnCommandActionDtoActionEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a LiquorKilnCommandActionDtoActionEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  LiquorKilnCommandActionDtoActionEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'HEATER_1': return LiquorKilnCommandActionDtoActionEnum.hEATER1;
        case r'HEATER_2': return LiquorKilnCommandActionDtoActionEnum.hEATER2;
        case r'HEATER_3': return LiquorKilnCommandActionDtoActionEnum.hEATER3;
        case r'SET_OVERHEAT_TEMP': return LiquorKilnCommandActionDtoActionEnum.SET_OVERHEAT_TEMP;
        case r'SET_COOLING_TEMP': return LiquorKilnCommandActionDtoActionEnum.SET_COOLING_TEMP;
        case r'SET_DISTILLATION_TIME': return LiquorKilnCommandActionDtoActionEnum.SET_DISTILLATION_TIME;
        case r'RESET_WIFI': return LiquorKilnCommandActionDtoActionEnum.RESET_WIFI;
        case r'SET_DISTILLATION_DAY_TEMP_MIN': return LiquorKilnCommandActionDtoActionEnum.SET_DISTILLATION_DAY_TEMP_MIN;
        case r'SET_DISTILLATION_DAY_TEMP_MAX': return LiquorKilnCommandActionDtoActionEnum.SET_DISTILLATION_DAY_TEMP_MAX;
        case r'SET_DISTILLATION_NIGHT_TEMP_MIN': return LiquorKilnCommandActionDtoActionEnum.SET_DISTILLATION_NIGHT_TEMP_MIN;
        case r'SET_DISTILLATION_NIGHT_TEMP_MAX': return LiquorKilnCommandActionDtoActionEnum.SET_DISTILLATION_NIGHT_TEMP_MAX;
        case r'UPDATE_TIME_NTP': return LiquorKilnCommandActionDtoActionEnum.UPDATE_TIME_NTP;
        case r'SET_TOTAL_DAY_DISTILLATION_TIME': return LiquorKilnCommandActionDtoActionEnum.SET_TOTAL_DAY_DISTILLATION_TIME;
        case r'SET_TOTAL_NIGHT_DISTILLATION_TIME': return LiquorKilnCommandActionDtoActionEnum.SET_TOTAL_NIGHT_DISTILLATION_TIME;
        case r'CMD_HEATER_1': return LiquorKilnCommandActionDtoActionEnum.cMDHEATER1;
        case r'CMD_HEATER_2': return LiquorKilnCommandActionDtoActionEnum.cMDHEATER2;
        case r'CMD_HEATER_SYS': return LiquorKilnCommandActionDtoActionEnum.CMD_HEATER_SYS;
        case r'TURN_ON_DAY_DISTILLATION': return LiquorKilnCommandActionDtoActionEnum.TURN_ON_DAY_DISTILLATION;
        case r'TURN_ON_NIGHT_DISTILLATION': return LiquorKilnCommandActionDtoActionEnum.TURN_ON_NIGHT_DISTILLATION;
        case r'TURN_OFF_DISTILLATION': return LiquorKilnCommandActionDtoActionEnum.TURN_OFF_DISTILLATION;
        case r'CMD_POWER_PUMP_WATER': return LiquorKilnCommandActionDtoActionEnum.CMD_POWER_PUMP_WATER;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [LiquorKilnCommandActionDtoActionEnumTypeTransformer] instance.
  static LiquorKilnCommandActionDtoActionEnumTypeTransformer? _instance;
}


