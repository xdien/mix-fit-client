//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CmsLoginPayloadDto {
  /// Returns a new [CmsLoginPayloadDto] instance.
  CmsLoginPayloadDto({
    required this.user,
    required this.token,
  });

  Object user;

  TokenPayloadDto token;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CmsLoginPayloadDto &&
    other.user == user &&
    other.token == token;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (user.hashCode) +
    (token.hashCode);

  @override
  String toString() => 'CmsLoginPayloadDto[user=$user, token=$token]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'user'] = this.user;
      json[r'token'] = this.token;
    return json;
  }

  /// Returns a new [CmsLoginPayloadDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CmsLoginPayloadDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CmsLoginPayloadDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CmsLoginPayloadDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CmsLoginPayloadDto(
        user: mapValueOfType<Object>(json, r'user')!,
        token: TokenPayloadDto.fromJson(json[r'token'])!,
      );
    }
    return null;
  }

  static List<CmsLoginPayloadDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CmsLoginPayloadDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CmsLoginPayloadDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CmsLoginPayloadDto> mapFromJson(dynamic json) {
    final map = <String, CmsLoginPayloadDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CmsLoginPayloadDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CmsLoginPayloadDto-objects as value to a dart map
  static Map<String, List<CmsLoginPayloadDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CmsLoginPayloadDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CmsLoginPayloadDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'user',
    'token',
  };
}

