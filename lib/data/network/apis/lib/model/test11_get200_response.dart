//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class Test11Get200Response {
  /// Returns a new [Test11Get200Response] instance.
  Test11Get200Response({
    required this.foo,
  });

  String foo;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Test11Get200Response &&
    other.foo == foo;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (foo.hashCode);

  @override
  String toString() => 'Test11Get200Response[foo=$foo]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'foo'] = this.foo;
    return json;
  }

  /// Returns a new [Test11Get200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static Test11Get200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "Test11Get200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "Test11Get200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return Test11Get200Response(
        foo: mapValueOfType<String>(json, r'foo')!,
      );
    }
    return null;
  }

  static List<Test11Get200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <Test11Get200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = Test11Get200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, Test11Get200Response> mapFromJson(dynamic json) {
    final map = <String, Test11Get200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = Test11Get200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of Test11Get200Response-objects as value to a dart map
  static Map<String, List<Test11Get200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<Test11Get200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = Test11Get200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'foo',
  };
}

