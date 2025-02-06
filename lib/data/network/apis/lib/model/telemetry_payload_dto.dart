//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class TelemetryPayloadDto {
  /// Returns a new [TelemetryPayloadDto] instance.
  TelemetryPayloadDto({
    required this.deviceId,
    this.deviceType,
    required this.timestamp,
    this.metrics = const [],
  });

  /// Unique identifier of the device
  String deviceId;

  /// Type of the device to which the telemetry data belongs
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? deviceType;

  /// Timestamp when the telemetry data was collected
  DateTime timestamp;

  /// Array of metrics with their values
  List<MetricDto> metrics;

  @override
  bool operator ==(Object other) => identical(this, other) || other is TelemetryPayloadDto &&
    other.deviceId == deviceId &&
    other.deviceType == deviceType &&
    other.timestamp == timestamp &&
    _deepEquality.equals(other.metrics, metrics);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deviceId.hashCode) +
    (deviceType == null ? 0 : deviceType!.hashCode) +
    (timestamp.hashCode) +
    (metrics.hashCode);

  @override
  String toString() => 'TelemetryPayloadDto[deviceId=$deviceId, deviceType=$deviceType, timestamp=$timestamp, metrics=$metrics]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'deviceId'] = this.deviceId;
    if (this.deviceType != null) {
      json[r'deviceType'] = this.deviceType;
    } else {
      json[r'deviceType'] = null;
    }
      json[r'timestamp'] = this.timestamp.toUtc().toIso8601String();
      json[r'metrics'] = this.metrics;
    return json;
  }

  /// Returns a new [TelemetryPayloadDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static TelemetryPayloadDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "TelemetryPayloadDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "TelemetryPayloadDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return TelemetryPayloadDto(
        deviceId: mapValueOfType<String>(json, r'deviceId')!,
        deviceType: mapValueOfType<String>(json, r'deviceType'),
        timestamp: mapDateTime(json, r'timestamp', r'')!,
        metrics: MetricDto.listFromJson(json[r'metrics']),
      );
    }
    return null;
  }

  static List<TelemetryPayloadDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <TelemetryPayloadDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = TelemetryPayloadDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, TelemetryPayloadDto> mapFromJson(dynamic json) {
    final map = <String, TelemetryPayloadDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = TelemetryPayloadDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of TelemetryPayloadDto-objects as value to a dart map
  static Map<String, List<TelemetryPayloadDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<TelemetryPayloadDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = TelemetryPayloadDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deviceId',
    'timestamp',
    'metrics',
  };
}

