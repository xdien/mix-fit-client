//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthCheckerControllerCheck503Response {
  /// Returns a new [HealthCheckerControllerCheck503Response] instance.
  HealthCheckerControllerCheck503Response({
    this.status,
    this.info = const {},
    this.error = const {},
    this.details = const {},
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? status;

  Map<String, HealthCheckerControllerCheck200ResponseInfoValue>? info;

  Map<String, HealthCheckerControllerCheck200ResponseInfoValue>? error;

  Map<String, HealthCheckerControllerCheck200ResponseInfoValue> details;

  @override
  bool operator ==(Object other) => identical(this, other) || other is HealthCheckerControllerCheck503Response &&
    other.status == status &&
    _deepEquality.equals(other.info, info) &&
    _deepEquality.equals(other.error, error) &&
    _deepEquality.equals(other.details, details);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (status == null ? 0 : status!.hashCode) +
    (info == null ? 0 : info!.hashCode) +
    (error == null ? 0 : error!.hashCode) +
    (details.hashCode);

  @override
  String toString() => 'HealthCheckerControllerCheck503Response[status=$status, info=$info, error=$error, details=$details]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.info != null) {
      json[r'info'] = this.info;
    } else {
      json[r'info'] = null;
    }
    if (this.error != null) {
      json[r'error'] = this.error;
    } else {
      json[r'error'] = null;
    }
      json[r'details'] = this.details;
    return json;
  }

  /// Returns a new [HealthCheckerControllerCheck503Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthCheckerControllerCheck503Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "HealthCheckerControllerCheck503Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "HealthCheckerControllerCheck503Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return HealthCheckerControllerCheck503Response(
        status: mapValueOfType<String>(json, r'status'),
        info: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'info']),
        error: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'error']),
        details: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'details']),
      );
    }
    return null;
  }

  static List<HealthCheckerControllerCheck503Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HealthCheckerControllerCheck503Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthCheckerControllerCheck503Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthCheckerControllerCheck503Response> mapFromJson(dynamic json) {
    final map = <String, HealthCheckerControllerCheck503Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthCheckerControllerCheck503Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthCheckerControllerCheck503Response-objects as value to a dart map
  static Map<String, List<HealthCheckerControllerCheck503Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HealthCheckerControllerCheck503Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthCheckerControllerCheck503Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

