//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommandPayloadDto {
  /// Returns a new [CommandPayloadDto] instance.
  CommandPayloadDto({
    required this.deviceType,
    this.parameters = const {},
    this.metadata = const {},
    this.repositoryType,
  });

  /// Loại thiết bị
  String deviceType;

  /// Parameters control device
  Map<String, Object> parameters;

  /// Metadata bổ sung
  Map<String, Object> metadata;

  /// Loại repository
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? repositoryType;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommandPayloadDto &&
    other.deviceType == deviceType &&
    _deepEquality.equals(other.parameters, parameters) &&
    _deepEquality.equals(other.metadata, metadata) &&
    other.repositoryType == repositoryType;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (deviceType.hashCode) +
    (parameters.hashCode) +
    (metadata.hashCode) +
    (repositoryType == null ? 0 : repositoryType!.hashCode);

  @override
  String toString() => 'CommandPayloadDto[deviceType=$deviceType, parameters=$parameters, metadata=$metadata, repositoryType=$repositoryType]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'deviceType'] = this.deviceType;
      json[r'parameters'] = this.parameters;
      json[r'metadata'] = this.metadata;
    if (this.repositoryType != null) {
      json[r'repositoryType'] = this.repositoryType;
    } else {
      json[r'repositoryType'] = null;
    }
    return json;
  }

  /// Returns a new [CommandPayloadDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommandPayloadDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommandPayloadDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommandPayloadDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommandPayloadDto(
        deviceType: mapValueOfType<String>(json, r'deviceType')!,
        parameters: mapCastOfType<String, Object>(json, r'parameters') ?? const {},
        metadata: mapCastOfType<String, Object>(json, r'metadata') ?? const {},
        repositoryType: mapValueOfType<String>(json, r'repositoryType'),
      );
    }
    return null;
  }

  static List<CommandPayloadDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommandPayloadDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommandPayloadDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommandPayloadDto> mapFromJson(dynamic json) {
    final map = <String, CommandPayloadDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommandPayloadDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommandPayloadDto-objects as value to a dart map
  static Map<String, List<CommandPayloadDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommandPayloadDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommandPayloadDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'deviceType',
  };
}

