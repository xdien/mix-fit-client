//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class OilTemperatureEvent {
  /// Returns a new [OilTemperatureEvent] instance.
  OilTemperatureEvent({
    required this.type,
    required this.source_,
    required this.id,
    required this.time,
    required this.data,
  });

  /// The type of event
  String type;

  /// The source of the event
  String source_;

  /// The unique identifier of the event
  String id;

  /// The time the event occurred
  String time;

  /// Data for oil temperature event
  OilTemperatureData data;

  @override
  bool operator ==(Object other) => identical(this, other) || other is OilTemperatureEvent &&
    other.type == type &&
    other.source_ == source_ &&
    other.id == id &&
    other.time == time &&
    other.data == data;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (type.hashCode) +
    (source_.hashCode) +
    (id.hashCode) +
    (time.hashCode) +
    (data.hashCode);

  @override
  String toString() => 'OilTemperatureEvent[type=$type, source_=$source_, id=$id, time=$time, data=$data]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'type'] = this.type;
      json[r'source'] = this.source_;
      json[r'id'] = this.id;
      json[r'time'] = this.time;
      json[r'data'] = this.data;
    return json;
  }

  /// Returns a new [OilTemperatureEvent] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static OilTemperatureEvent? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "OilTemperatureEvent[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "OilTemperatureEvent[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return OilTemperatureEvent(
        type: mapValueOfType<String>(json, r'type')!,
        source_: mapValueOfType<String>(json, r'source')!,
        id: mapValueOfType<String>(json, r'id')!,
        time: mapValueOfType<String>(json, r'time')!,
        data: OilTemperatureData.fromJson(json[r'data'])!,
      );
    }
    return null;
  }

  static List<OilTemperatureEvent> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <OilTemperatureEvent>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = OilTemperatureEvent.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, OilTemperatureEvent> mapFromJson(dynamic json) {
    final map = <String, OilTemperatureEvent>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = OilTemperatureEvent.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of OilTemperatureEvent-objects as value to a dart map
  static Map<String, List<OilTemperatureEvent>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<OilTemperatureEvent>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = OilTemperatureEvent.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'type',
    'source',
    'id',
    'time',
    'data',
  };
}

