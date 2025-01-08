//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PageMetaDto {
  /// Returns a new [PageMetaDto] instance.
  PageMetaDto({
    required this.page,
    required this.take,
    required this.itemCount,
    required this.pageCount,
    required this.hasPreviousPage,
    required this.hasNextPage,
  });

  num page;

  num take;

  num itemCount;

  num pageCount;

  bool hasPreviousPage;

  bool hasNextPage;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PageMetaDto &&
    other.page == page &&
    other.take == take &&
    other.itemCount == itemCount &&
    other.pageCount == pageCount &&
    other.hasPreviousPage == hasPreviousPage &&
    other.hasNextPage == hasNextPage;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (page.hashCode) +
    (take.hashCode) +
    (itemCount.hashCode) +
    (pageCount.hashCode) +
    (hasPreviousPage.hashCode) +
    (hasNextPage.hashCode);

  @override
  String toString() => 'PageMetaDto[page=$page, take=$take, itemCount=$itemCount, pageCount=$pageCount, hasPreviousPage=$hasPreviousPage, hasNextPage=$hasNextPage]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'page'] = this.page;
      json[r'take'] = this.take;
      json[r'itemCount'] = this.itemCount;
      json[r'pageCount'] = this.pageCount;
      json[r'hasPreviousPage'] = this.hasPreviousPage;
      json[r'hasNextPage'] = this.hasNextPage;
    return json;
  }

  /// Returns a new [PageMetaDto] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PageMetaDto? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PageMetaDto[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PageMetaDto[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PageMetaDto(
        page: num.parse('${json[r'page']}'),
        take: num.parse('${json[r'take']}'),
        itemCount: num.parse('${json[r'itemCount']}'),
        pageCount: num.parse('${json[r'pageCount']}'),
        hasPreviousPage: mapValueOfType<bool>(json, r'hasPreviousPage')!,
        hasNextPage: mapValueOfType<bool>(json, r'hasNextPage')!,
      );
    }
    return null;
  }

  static List<PageMetaDto> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PageMetaDto>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PageMetaDto.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PageMetaDto> mapFromJson(dynamic json) {
    final map = <String, PageMetaDto>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PageMetaDto.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PageMetaDto-objects as value to a dart map
  static Map<String, List<PageMetaDto>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PageMetaDto>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PageMetaDto.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'page',
    'take',
    'itemCount',
    'pageCount',
    'hasPreviousPage',
    'hasNextPage',
  };
}

