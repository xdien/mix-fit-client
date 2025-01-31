//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class CmsApi {
  CmsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Performs an HTTP 'POST /cms-auth/login' operation and returns the [Response].
  /// Parameters:
  ///
  /// * [CmsLoginDto] cmsLoginDto (required):
  Future<Response> cmsAuthControllerLoginWithHttpInfo(CmsLoginDto cmsLoginDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/cms-auth/login';

    // ignore: prefer_final_locals
    Object? postBody = cmsLoginDto;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Parameters:
  ///
  /// * [CmsLoginDto] cmsLoginDto (required):
  Future<CmsLoginPayloadDto?> cmsAuthControllerLogin(CmsLoginDto cmsLoginDto,) async {
    final response = await cmsAuthControllerLoginWithHttpInfo(cmsLoginDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CmsLoginPayloadDto',) as CmsLoginPayloadDto;
    
    }
    return null;
  }
}
