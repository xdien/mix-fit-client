//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// User roles array
class RoleType {
  /// Instantiate a new enum with the provided [value].
  const RoleType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const SUPER_ADMIN = RoleType._(r'SUPER_ADMIN');
  static const ADMIN = RoleType._(r'ADMIN');
  static const IOT_ADMIN = RoleType._(r'IOT_ADMIN');
  static const USER = RoleType._(r'USER');
  static const GUEST = RoleType._(r'GUEST');

  /// List of all possible values in this [enum][RoleType].
  static const values = <RoleType>[
    SUPER_ADMIN,
    ADMIN,
    IOT_ADMIN,
    USER,
    GUEST,
  ];

  static RoleType? fromJson(dynamic value) => RoleTypeTypeTransformer().decode(value);

  static List<RoleType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RoleType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RoleType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RoleType] to String,
/// and [decode] dynamic data back to [RoleType].
class RoleTypeTypeTransformer {
  factory RoleTypeTypeTransformer() => _instance ??= const RoleTypeTypeTransformer._();

  const RoleTypeTypeTransformer._();

  String encode(RoleType data) => data.value;

  /// Decodes a [dynamic value][data] to a RoleType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RoleType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'SUPER_ADMIN': return RoleType.SUPER_ADMIN;
        case r'ADMIN': return RoleType.ADMIN;
        case r'IOT_ADMIN': return RoleType.IOT_ADMIN;
        case r'USER': return RoleType.USER;
        case r'GUEST': return RoleType.GUEST;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RoleTypeTypeTransformer] instance.
  static RoleTypeTypeTransformer? _instance;
}

