//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OilTemperatureData {
  /// Returns a new [OilTemperatureData] instance.
  OilTemperatureData({
    required this.deviceId,
    required this.temperature,
    required this.timestamp,
  });

  /// Unique identifier of the device
  String deviceId;

  /// Temperature value in Celsius
  ///
  /// Minimum value: -50
  /// Maximum value: 500
  num temperature;

  /// Timestamp of the event
  DateTime timestamp;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OilTemperatureData &&
    other.deviceId == deviceId &&
    other.temperature == temperature &&
    other.timestamp == timestamp;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deviceId.hashCode) +
    (temperature.hashCode) +
    (timestamp.hashCode);

  @override
  String toString() => 'OilTemperatureData[deviceId=$deviceId, temperature=$temperature, timestamp=$timestamp]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'deviceId'] = this.deviceId;
      json[r'temperature'] = this.temperature;
      json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
    return json;
  }

  /// Returns a new [OilTemperatureData] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OilTemperatureData? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "OilTemperatureData[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "OilTemperatureData[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OilTemperatureData(
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
        temperature: num.parse('${json[r'temperature']}'),
        timestamp: mapDateTime(json, r'timestamp', r'')!,
      );
    }
    return null;
  }

  static List<OilTemperatureData> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OilTemperatureData>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OilTemperatureData.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OilTemperatureData> mapFromJson(dynamic json) {
    final map = <String, OilTemperatureData>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OilTemperatureData.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OilTemperatureData-objects as value to a dart map
  static Map<String, List<OilTemperatureData>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OilTemperatureData>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OilTemperatureData.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deviceId',
    'temperature',
    'timestamp',
  };
}

