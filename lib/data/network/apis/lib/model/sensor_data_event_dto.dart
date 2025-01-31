//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class SensorDataEventDto {
  /// Returns a new [SensorDataEventDto] instance.
  SensorDataEventDto({
    required this.eventType,
    required this.telemetryData,
  });

  IoTEvents eventType;

  /// Telemetry data
  TelemetryPayloadDto telemetryData;

  @override
  bool operator ==(Object other) => identical(this, other) || other is SensorDataEventDto &&
    other.eventType == eventType &&
    other.telemetryData == telemetryData;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (eventType.hashCode) +
    (telemetryData.hashCode);

  @override
  String toString() => 'SensorDataEventDto[eventType=$eventType, telemetryData=$telemetryData]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'eventType'] = this.eventType;
      json[r'telemetryData'] = this.telemetryData;
    return json;
  }

  /// Returns a new [SensorDataEventDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static SensorDataEventDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "SensorDataEventDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "SensorDataEventDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return SensorDataEventDto(
        eventType: IoTEvents.fromJson(json[r'eventType'])!,
        telemetryData: TelemetryPayloadDto.fromJson(json[r'telemetryData'])!,
      );
    }
    return null;
  }

  static List<SensorDataEventDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <SensorDataEventDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = SensorDataEventDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, SensorDataEventDto> mapFromJson(dynamic json) {
    final map = <String, SensorDataEventDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = SensorDataEventDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of SensorDataEventDto-objects as value to a dart map
  static Map<String, List<SensorDataEventDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<SensorDataEventDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = SensorDataEventDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'eventType',
    'telemetryData',
  };
}

