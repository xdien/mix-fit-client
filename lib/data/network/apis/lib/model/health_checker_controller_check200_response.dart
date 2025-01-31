//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class HealthCheckerControllerCheck200Response {
  /// Returns a new [HealthCheckerControllerCheck200Response] instance.
  HealthCheckerControllerCheck200Response({
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
  bool operator ==(Object other) => identical(this, other) || other is HealthCheckerControllerCheck200Response &&
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
  String toString() => 'HealthCheckerControllerCheck200Response[status=$status, info=$info, error=$error, details=$details]';

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

  /// Returns a new [HealthCheckerControllerCheck200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static HealthCheckerControllerCheck200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "HealthCheckerControllerCheck200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "HealthCheckerControllerCheck200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return HealthCheckerControllerCheck200Response(
        status: mapValueOfType<String>(json, r'status'),
        info: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'info']),
        error: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'error']),
        details: HealthCheckerControllerCheck200ResponseInfoValue.mapFromJson(json[r'details']),
      );
    }
    return null;
  }

  static List<HealthCheckerControllerCheck200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <HealthCheckerControllerCheck200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = HealthCheckerControllerCheck200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, HealthCheckerControllerCheck200Response> mapFromJson(dynamic json) {
    final map = <String, HealthCheckerControllerCheck200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = HealthCheckerControllerCheck200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of HealthCheckerControllerCheck200Response-objects as value to a dart map
  static Map<String, List<HealthCheckerControllerCheck200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<HealthCheckerControllerCheck200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = HealthCheckerControllerCheck200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

