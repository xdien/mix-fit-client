//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class CommandStatusDto {
  /// Returns a new [CommandStatusDto] instance.
  CommandStatusDto({
    required this.commandId,
    this.status,
    this.executedAt,
  });

  /// ID của lệnh
  Object commandId;

  /// Trạng thái của lệnh
  CommandStatusDtoStatusEnum? status;

  /// Thời gian thực thi
  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  Object? executedAt;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommandStatusDto &&
    other.commandId == commandId &&
    other.status == status &&
    other.executedAt == executedAt;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (commandId.hashCode) +
    (status == null ? 0 : status!.hashCode) +
    (executedAt == null ? 0 : executedAt!.hashCode);

  @override
  String toString() => 'CommandStatusDto[commandId=$commandId, status=$status, executedAt=$executedAt]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'commandId'] = this.commandId;
    if (this.status != null) {
      json[r'status'] = this.status;
    } else {
      json[r'status'] = null;
    }
    if (this.executedAt != null) {
      json[r'executedAt'] = this.executedAt;
    } else {
      json[r'executedAt'] = null;
    }
    return json;
  }

  /// Returns a new [CommandStatusDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static CommandStatusDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "CommandStatusDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "CommandStatusDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return CommandStatusDto(
        commandId: mapValueOfType<Object>(json, r'commandId')!,
        status: CommandStatusDtoStatusEnum.fromJson(json[r'status']),
        executedAt: mapValueOfType<Object>(json, r'executedAt'),
      );
    }
    return null;
  }

  static List<CommandStatusDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommandStatusDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommandStatusDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, CommandStatusDto> mapFromJson(dynamic json) {
    final map = <String, CommandStatusDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = CommandStatusDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of CommandStatusDto-objects as value to a dart map
  static Map<String, List<CommandStatusDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<CommandStatusDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = CommandStatusDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'commandId',
  };
}

/// Trạng thái của lệnh
class CommandStatusDtoStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const CommandStatusDtoStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const PENDING = CommandStatusDtoStatusEnum._(r'PENDING');
  static const EXECUTING = CommandStatusDtoStatusEnum._(r'EXECUTING');
  static const COMPLETED = CommandStatusDtoStatusEnum._(r'COMPLETED');
  static const FAILED = CommandStatusDtoStatusEnum._(r'FAILED');

  /// List of all possible values in this [enum][CommandStatusDtoStatusEnum].
  static const values = <CommandStatusDtoStatusEnum>[
    PENDING,
    EXECUTING,
    COMPLETED,
    FAILED,
  ];

  static CommandStatusDtoStatusEnum? fromJson(dynamic value) => CommandStatusDtoStatusEnumTypeTransformer().decode(value);

  static List<CommandStatusDtoStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <CommandStatusDtoStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = CommandStatusDtoStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [CommandStatusDtoStatusEnum] to String,
/// and [decode] dynamic data back to [CommandStatusDtoStatusEnum].
class CommandStatusDtoStatusEnumTypeTransformer {
  factory CommandStatusDtoStatusEnumTypeTransformer() => _instance ??= const CommandStatusDtoStatusEnumTypeTransformer._();

  const CommandStatusDtoStatusEnumTypeTransformer._();

  String encode(CommandStatusDtoStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a CommandStatusDtoStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  CommandStatusDtoStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'PENDING': return CommandStatusDtoStatusEnum.PENDING;
        case r'EXECUTING': return CommandStatusDtoStatusEnum.EXECUTING;
        case r'COMPLETED': return CommandStatusDtoStatusEnum.COMPLETED;
        case r'FAILED': return CommandStatusDtoStatusEnum.FAILED;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [CommandStatusDtoStatusEnumTypeTransformer] instance.
  static CommandStatusDtoStatusEnumTypeTransformer? _instance;
}


