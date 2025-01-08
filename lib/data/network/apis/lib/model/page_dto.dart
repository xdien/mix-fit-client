//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PageDto {
  /// Returns a new [PageDto] instance.
  PageDto({
    this.data = const [],
    required this.meta,
  });

  List<List<Object>> data;

  PageMetaDto meta;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PageDto &&
    _deepEquality.equals(other.data, data) &&
    other.meta == meta;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (data.hashCode) +
    (meta.hashCode);

  @override
  String toString() => 'PageDto[data=$data, meta=$meta]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'data'] = this.data;
      json[r'meta'] = this.meta;
    return json;
  }

  /// Returns a new [PageDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PageDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PageDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PageDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PageDto(
        data: json[r'data'] is List
          ? (json[r'data'] as List).map((e) =>
              Object.listFromJson(json[r'data'])
            ).toList()
          :  const [],
        meta: PageMetaDto.fromJson(json[r'meta'])!,
      );
    }
    return null;
  }

  static List<PageDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PageDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PageDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PageDto> mapFromJson(dynamic json) {
    final map = <String, PageDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PageDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PageDto-objects as value to a dart map
  static Map<String, List<PageDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PageDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PageDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'data',
    'meta',
  };
}

