//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommandParametersDto {
  /// Returns a new [CommandParametersDto] instance.
  CommandParametersDto({
    this.hEATER1,
    this.hEATER2,
    this.hEATER3,
    this.SET_OVERHEAT_TEMP,
    this.SET_COOLING_TEMP,
    this.SET_DISTILLATION_TIME,
    this.RESET_WIFI,
    this.SET_DISTILLATION_DAY_TEMP_MIN,
    this.SET_DISTILLATION_DAY_TEMP_MAX,
    this.SET_DISTILLATION_NIGHT_TEMP_MIN,
    this.SET_DISTILLATION_NIGHT_TEMP_MAX,
    this.UPDATE_TIME_NTP,
    this.SET_TOTAL_DAY_DISTILLATION_TIME,
    this.SET_TOTAL_NIGHT_DISTILLATION_TIME,
    this.cMDHEATER1,
    this.cMDHEATER2,
    this.CMD_HEATER_SYS,
    this.TURN_ON_DAY_DISTILLATION,
    this.TURN_ON_NIGHT_DISTILLATION,
    this.TURN_OFF_DISTILLATION,
    this.CMD_POWER_PUMP_WATER,
  });

  /// Control heater 1
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hEATER1;

  /// Control heater 2
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hEATER2;

  /// Control heater 3
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? hEATER3;

  /// Set overheat temperature threshold
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_OVERHEAT_TEMP;

  /// Set cooling temperature threshold
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_COOLING_TEMP;

  /// Set distillation time in minutes
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_DISTILLATION_TIME;

  /// Reset WiFi configuration
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? RESET_WIFI;

  /// Set minimum temperature for day distillation
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_DISTILLATION_DAY_TEMP_MIN;

  /// Set maximum temperature for day distillation
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_DISTILLATION_DAY_TEMP_MAX;

  /// Set minimum temperature for night distillation
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_DISTILLATION_NIGHT_TEMP_MIN;

  /// Set maximum temperature for night distillation
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_DISTILLATION_NIGHT_TEMP_MAX;

  /// Update system time using NTP
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? UPDATE_TIME_NTP;

  /// Set total distillation time for day operation in minutes
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_TOTAL_DAY_DISTILLATION_TIME;

  /// Set total distillation time for night operation in minutes
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  num? SET_TOTAL_NIGHT_DISTILLATION_TIME;

  /// Control heater 1 power
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? cMDHEATER1;

  /// Control heater 2 power
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? cMDHEATER2;

  /// Control heater system power
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? CMD_HEATER_SYS;

  /// Enable day distillation mode
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? TURN_ON_DAY_DISTILLATION;

  /// Enable night distillation mode
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? TURN_ON_NIGHT_DISTILLATION;

  /// Disable distillation process
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? TURN_OFF_DISTILLATION;

  /// Control water pump power
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  bool? CMD_POWER_PUMP_WATER;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommandParametersDto &&
    other.hEATER1 == hEATER1 &&
    other.hEATER2 == hEATER2 &&
    other.hEATER3 == hEATER3 &&
    other.SET_OVERHEAT_TEMP == SET_OVERHEAT_TEMP &&
    other.SET_COOLING_TEMP == SET_COOLING_TEMP &&
    other.SET_DISTILLATION_TIME == SET_DISTILLATION_TIME &&
    other.RESET_WIFI == RESET_WIFI &&
    other.SET_DISTILLATION_DAY_TEMP_MIN == SET_DISTILLATION_DAY_TEMP_MIN &&
    other.SET_DISTILLATION_DAY_TEMP_MAX == SET_DISTILLATION_DAY_TEMP_MAX &&
    other.SET_DISTILLATION_NIGHT_TEMP_MIN == SET_DISTILLATION_NIGHT_TEMP_MIN &&
    other.SET_DISTILLATION_NIGHT_TEMP_MAX == SET_DISTILLATION_NIGHT_TEMP_MAX &&
    other.UPDATE_TIME_NTP == UPDATE_TIME_NTP &&
    other.SET_TOTAL_DAY_DISTILLATION_TIME == SET_TOTAL_DAY_DISTILLATION_TIME &&
    other.SET_TOTAL_NIGHT_DISTILLATION_TIME == SET_TOTAL_NIGHT_DISTILLATION_TIME &&
    other.cMDHEATER1 == cMDHEATER1 &&
    other.cMDHEATER2 == cMDHEATER2 &&
    other.CMD_HEATER_SYS == CMD_HEATER_SYS &&
    other.TURN_ON_DAY_DISTILLATION == TURN_ON_DAY_DISTILLATION &&
    other.TURN_ON_NIGHT_DISTILLATION == TURN_ON_NIGHT_DISTILLATION &&
    other.TURN_OFF_DISTILLATION == TURN_OFF_DISTILLATION &&
    other.CMD_POWER_PUMP_WATER == CMD_POWER_PUMP_WATER;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (hEATER1 == null ? 0 : hEATER1!.hashCode) +
    (hEATER2 == null ? 0 : hEATER2!.hashCode) +
    (hEATER3 == null ? 0 : hEATER3!.hashCode) +
    (SET_OVERHEAT_TEMP == null ? 0 : SET_OVERHEAT_TEMP!.hashCode) +
    (SET_COOLING_TEMP == null ? 0 : SET_COOLING_TEMP!.hashCode) +
    (SET_DISTILLATION_TIME == null ? 0 : SET_DISTILLATION_TIME!.hashCode) +
    (RESET_WIFI == null ? 0 : RESET_WIFI!.hashCode) +
    (SET_DISTILLATION_DAY_TEMP_MIN == null ? 0 : SET_DISTILLATION_DAY_TEMP_MIN!.hashCode) +
    (SET_DISTILLATION_DAY_TEMP_MAX == null ? 0 : SET_DISTILLATION_DAY_TEMP_MAX!.hashCode) +
    (SET_DISTILLATION_NIGHT_TEMP_MIN == null ? 0 : SET_DISTILLATION_NIGHT_TEMP_MIN!.hashCode) +
    (SET_DISTILLATION_NIGHT_TEMP_MAX == null ? 0 : SET_DISTILLATION_NIGHT_TEMP_MAX!.hashCode) +
    (UPDATE_TIME_NTP == null ? 0 : UPDATE_TIME_NTP!.hashCode) +
    (SET_TOTAL_DAY_DISTILLATION_TIME == null ? 0 : SET_TOTAL_DAY_DISTILLATION_TIME!.hashCode) +
    (SET_TOTAL_NIGHT_DISTILLATION_TIME == null ? 0 : SET_TOTAL_NIGHT_DISTILLATION_TIME!.hashCode) +
    (cMDHEATER1 == null ? 0 : cMDHEATER1!.hashCode) +
    (cMDHEATER2 == null ? 0 : cMDHEATER2!.hashCode) +
    (CMD_HEATER_SYS == null ? 0 : CMD_HEATER_SYS!.hashCode) +
    (TURN_ON_DAY_DISTILLATION == null ? 0 : TURN_ON_DAY_DISTILLATION!.hashCode) +
    (TURN_ON_NIGHT_DISTILLATION == null ? 0 : TURN_ON_NIGHT_DISTILLATION!.hashCode) +
    (TURN_OFF_DISTILLATION == null ? 0 : TURN_OFF_DISTILLATION!.hashCode) +
    (CMD_POWER_PUMP_WATER == null ? 0 : CMD_POWER_PUMP_WATER!.hashCode);

  @override
  String toString() => 'CommandParametersDto[hEATER1=$hEATER1, hEATER2=$hEATER2, hEATER3=$hEATER3, SET_OVERHEAT_TEMP=$SET_OVERHEAT_TEMP, SET_COOLING_TEMP=$SET_COOLING_TEMP, SET_DISTILLATION_TIME=$SET_DISTILLATION_TIME, RESET_WIFI=$RESET_WIFI, SET_DISTILLATION_DAY_TEMP_MIN=$SET_DISTILLATION_DAY_TEMP_MIN, SET_DISTILLATION_DAY_TEMP_MAX=$SET_DISTILLATION_DAY_TEMP_MAX, SET_DISTILLATION_NIGHT_TEMP_MIN=$SET_DISTILLATION_NIGHT_TEMP_MIN, SET_DISTILLATION_NIGHT_TEMP_MAX=$SET_DISTILLATION_NIGHT_TEMP_MAX, UPDATE_TIME_NTP=$UPDATE_TIME_NTP, SET_TOTAL_DAY_DISTILLATION_TIME=$SET_TOTAL_DAY_DISTILLATION_TIME, SET_TOTAL_NIGHT_DISTILLATION_TIME=$SET_TOTAL_NIGHT_DISTILLATION_TIME, cMDHEATER1=$cMDHEATER1, cMDHEATER2=$cMDHEATER2, CMD_HEATER_SYS=$CMD_HEATER_SYS, TURN_ON_DAY_DISTILLATION=$TURN_ON_DAY_DISTILLATION, TURN_ON_NIGHT_DISTILLATION=$TURN_ON_NIGHT_DISTILLATION, TURN_OFF_DISTILLATION=$TURN_OFF_DISTILLATION, CMD_POWER_PUMP_WATER=$CMD_POWER_PUMP_WATER]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.hEATER1 != null) {
      json[r'HEATER_1'] = this.hEATER1;
    } else {
      json[r'HEATER_1'] = null;
    }
    if (this.hEATER2 != null) {
      json[r'HEATER_2'] = this.hEATER2;
    } else {
      json[r'HEATER_2'] = null;
    }
    if (this.hEATER3 != null) {
      json[r'HEATER_3'] = this.hEATER3;
    } else {
      json[r'HEATER_3'] = null;
    }
    if (this.SET_OVERHEAT_TEMP != null) {
      json[r'SET_OVERHEAT_TEMP'] = this.SET_OVERHEAT_TEMP;
    } else {
      json[r'SET_OVERHEAT_TEMP'] = null;
    }
    if (this.SET_COOLING_TEMP != null) {
      json[r'SET_COOLING_TEMP'] = this.SET_COOLING_TEMP;
    } else {
      json[r'SET_COOLING_TEMP'] = null;
    }
    if (this.SET_DISTILLATION_TIME != null) {
      json[r'SET_DISTILLATION_TIME'] = this.SET_DISTILLATION_TIME;
    } else {
      json[r'SET_DISTILLATION_TIME'] = null;
    }
    if (this.RESET_WIFI != null) {
      json[r'RESET_WIFI'] = this.RESET_WIFI;
    } else {
      json[r'RESET_WIFI'] = null;
    }
    if (this.SET_DISTILLATION_DAY_TEMP_MIN != null) {
      json[r'SET_DISTILLATION_DAY_TEMP_MIN'] = this.SET_DISTILLATION_DAY_TEMP_MIN;
    } else {
      json[r'SET_DISTILLATION_DAY_TEMP_MIN'] = null;
    }
    if (this.SET_DISTILLATION_DAY_TEMP_MAX != null) {
      json[r'SET_DISTILLATION_DAY_TEMP_MAX'] = this.SET_DISTILLATION_DAY_TEMP_MAX;
    } else {
      json[r'SET_DISTILLATION_DAY_TEMP_MAX'] = null;
    }
    if (this.SET_DISTILLATION_NIGHT_TEMP_MIN != null) {
      json[r'SET_DISTILLATION_NIGHT_TEMP_MIN'] = this.SET_DISTILLATION_NIGHT_TEMP_MIN;
    } else {
      json[r'SET_DISTILLATION_NIGHT_TEMP_MIN'] = null;
    }
    if (this.SET_DISTILLATION_NIGHT_TEMP_MAX != null) {
      json[r'SET_DISTILLATION_NIGHT_TEMP_MAX'] = this.SET_DISTILLATION_NIGHT_TEMP_MAX;
    } else {
      json[r'SET_DISTILLATION_NIGHT_TEMP_MAX'] = null;
    }
    if (this.UPDATE_TIME_NTP != null) {
      json[r'UPDATE_TIME_NTP'] = this.UPDATE_TIME_NTP;
    } else {
      json[r'UPDATE_TIME_NTP'] = null;
    }
    if (this.SET_TOTAL_DAY_DISTILLATION_TIME != null) {
      json[r'SET_TOTAL_DAY_DISTILLATION_TIME'] = this.SET_TOTAL_DAY_DISTILLATION_TIME;
    } else {
      json[r'SET_TOTAL_DAY_DISTILLATION_TIME'] = null;
    }
    if (this.SET_TOTAL_NIGHT_DISTILLATION_TIME != null) {
      json[r'SET_TOTAL_NIGHT_DISTILLATION_TIME'] = this.SET_TOTAL_NIGHT_DISTILLATION_TIME;
    } else {
      json[r'SET_TOTAL_NIGHT_DISTILLATION_TIME'] = null;
    }
    if (this.cMDHEATER1 != null) {
      json[r'CMD_HEATER_1'] = this.cMDHEATER1;
    } else {
      json[r'CMD_HEATER_1'] = null;
    }
    if (this.cMDHEATER2 != null) {
      json[r'CMD_HEATER_2'] = this.cMDHEATER2;
    } else {
      json[r'CMD_HEATER_2'] = null;
    }
    if (this.CMD_HEATER_SYS != null) {
      json[r'CMD_HEATER_SYS'] = this.CMD_HEATER_SYS;
    } else {
      json[r'CMD_HEATER_SYS'] = null;
    }
    if (this.TURN_ON_DAY_DISTILLATION != null) {
      json[r'TURN_ON_DAY_DISTILLATION'] = this.TURN_ON_DAY_DISTILLATION;
    } else {
      json[r'TURN_ON_DAY_DISTILLATION'] = null;
    }
    if (this.TURN_ON_NIGHT_DISTILLATION != null) {
      json[r'TURN_ON_NIGHT_DISTILLATION'] = this.TURN_ON_NIGHT_DISTILLATION;
    } else {
      json[r'TURN_ON_NIGHT_DISTILLATION'] = null;
    }
    if (this.TURN_OFF_DISTILLATION != null) {
      json[r'TURN_OFF_DISTILLATION'] = this.TURN_OFF_DISTILLATION;
    } else {
      json[r'TURN_OFF_DISTILLATION'] = null;
    }
    if (this.CMD_POWER_PUMP_WATER != null) {
      json[r'CMD_POWER_PUMP_WATER'] = this.CMD_POWER_PUMP_WATER;
    } else {
      json[r'CMD_POWER_PUMP_WATER'] = null;
    }
    return json;
  }

  /// Returns a new [CommandParametersDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommandParametersDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommandParametersDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommandParametersDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommandParametersDto(
        hEATER1: mapValueOfType<bool>(json, r'HEATER_1'),
        hEATER2: mapValueOfType<bool>(json, r'HEATER_2'),
        hEATER3: mapValueOfType<bool>(json, r'HEATER_3'),
        SET_OVERHEAT_TEMP: num.parse('${json[r'SET_OVERHEAT_TEMP']}'),
        SET_COOLING_TEMP: num.parse('${json[r'SET_COOLING_TEMP']}'),
        SET_DISTILLATION_TIME: num.parse('${json[r'SET_DISTILLATION_TIME']}'),
        RESET_WIFI: mapValueOfType<bool>(json, r'RESET_WIFI'),
        SET_DISTILLATION_DAY_TEMP_MIN: num.parse('${json[r'SET_DISTILLATION_DAY_TEMP_MIN']}'),
        SET_DISTILLATION_DAY_TEMP_MAX: num.parse('${json[r'SET_DISTILLATION_DAY_TEMP_MAX']}'),
        SET_DISTILLATION_NIGHT_TEMP_MIN: num.parse('${json[r'SET_DISTILLATION_NIGHT_TEMP_MIN']}'),
        SET_DISTILLATION_NIGHT_TEMP_MAX: num.parse('${json[r'SET_DISTILLATION_NIGHT_TEMP_MAX']}'),
        UPDATE_TIME_NTP: mapValueOfType<bool>(json, r'UPDATE_TIME_NTP'),
        SET_TOTAL_DAY_DISTILLATION_TIME: num.parse('${json[r'SET_TOTAL_DAY_DISTILLATION_TIME']}'),
        SET_TOTAL_NIGHT_DISTILLATION_TIME: num.parse('${json[r'SET_TOTAL_NIGHT_DISTILLATION_TIME']}'),
        cMDHEATER1: mapValueOfType<bool>(json, r'CMD_HEATER_1'),
        cMDHEATER2: mapValueOfType<bool>(json, r'CMD_HEATER_2'),
        CMD_HEATER_SYS: mapValueOfType<bool>(json, r'CMD_HEATER_SYS'),
        TURN_ON_DAY_DISTILLATION: mapValueOfType<bool>(json, r'TURN_ON_DAY_DISTILLATION'),
        TURN_ON_NIGHT_DISTILLATION: mapValueOfType<bool>(json, r'TURN_ON_NIGHT_DISTILLATION'),
        TURN_OFF_DISTILLATION: mapValueOfType<bool>(json, r'TURN_OFF_DISTILLATION'),
        CMD_POWER_PUMP_WATER: mapValueOfType<bool>(json, r'CMD_POWER_PUMP_WATER'),
      );
    }
    return null;
  }

  static List<CommandParametersDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommandParametersDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommandParametersDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommandParametersDto> mapFromJson(dynamic json) {
    final map = <String, CommandParametersDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommandParametersDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommandParametersDto-objects as value to a dart map
  static Map<String, List<CommandParametersDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommandParametersDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommandParametersDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

