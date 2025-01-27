//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class UserRegisterDto {
  /// Returns a new [UserRegisterDto] instance.
  UserRegisterDto({
    required this.username,
    required this.email,
    required this.password,
    this.fullName,
    this.phone,
  });

  String username;

  String email;

  String password;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? fullName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? phone;

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserRegisterDto &&
    other.username == username &&
    other.email == email &&
    other.password == password &&
    other.fullName == fullName &&
    other.phone == phone;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (username.hashCode) +
    (email.hashCode) +
    (password.hashCode) +
    (fullName == null ? 0 : fullName!.hashCode) +
    (phone == null ? 0 : phone!.hashCode);

  @override
  String toString() => 'UserRegisterDto[username=$username, email=$email, password=$password, fullName=$fullName, phone=$phone]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'username'] = this.username;
      json[r'email'] = this.email;
      json[r'password'] = this.password;
    if (this.fullName != null) {
      json[r'fullName'] = this.fullName;
    } else {
      json[r'fullName'] = null;
    }
    if (this.phone != null) {
      json[r'phone'] = this.phone;
    } else {
      json[r'phone'] = null;
    }
    return json;
  }

  /// Returns a new [UserRegisterDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static UserRegisterDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "UserRegisterDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "UserRegisterDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return UserRegisterDto(
        username: mapValueOfType<String>(json, r'username')!,
        email: mapValueOfType<String>(json, r'email')!,
        password: mapValueOfType<String>(json, r'password')!,
        fullName: mapValueOfType<String>(json, r'fullName'),
        phone: mapValueOfType<String>(json, r'phone'),
      );
    }
    return null;
  }

  static List<UserRegisterDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <UserRegisterDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = UserRegisterDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, UserRegisterDto> mapFromJson(dynamic json) {
    final map = <String, UserRegisterDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = UserRegisterDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of UserRegisterDto-objects as value to a dart map
  static Map<String, List<UserRegisterDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<UserRegisterDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = UserRegisterDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'username',
    'email',
    'password',
  };
}

