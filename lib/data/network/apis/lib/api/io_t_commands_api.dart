//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class IoTCommandsApi {
  IoTCommandsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Get status of command
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] commandId (required):
  ///   ID of the command
  Future<Response> ioTCommandControllerGetStatusWithHttpInfo(String commandId,) async {
    // ignore: prefer_const_declarations
    final path = r'/iot/commands/{commandId}/status'
      .replaceAll('{commandId}', commandId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get status of command
  ///
  /// Parameters:
  ///
  /// * [String] commandId (required):
  ///   ID of the command
  Future<CommandStatusDto?> ioTCommandControllerGetStatus(String commandId,) async {
    final response = await ioTCommandControllerGetStatusWithHttpInfo(commandId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommandStatusDto',) as CommandStatusDto;
    
    }
    return null;
  }

  /// Send command to device
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///   ID of the device
  ///
  /// * [CommandPayloadDto] commandPayloadDto (required):
  Future<Response> ioTCommandControllerSendCommandWithHttpInfo(String deviceId, CommandPayloadDto commandPayloadDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/iot/commands/{deviceId}'
      .replaceAll('{deviceId}', deviceId);

    // ignore: prefer_final_locals
    Object? postBody = commandPayloadDto;

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

  /// Send command to device
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///   ID of the device
  ///
  /// * [CommandPayloadDto] commandPayloadDto (required):
  Future<CommandStatusDto?> ioTCommandControllerSendCommand(String deviceId, CommandPayloadDto commandPayloadDto,) async {
    final response = await ioTCommandControllerSendCommandWithHttpInfo(deviceId, commandPayloadDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommandStatusDto',) as CommandStatusDto;
    
    }
    return null;
  }

  /// Send command to device
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///   ID of the device
  ///
  /// * [CommandPayloadDto] commandPayloadDto (required):
  Future<Response> ioTCommandV1ControllerSendCommandWithHttpInfo(String deviceId, CommandPayloadDto commandPayloadDto,) async {
    // ignore: prefer_const_declarations
    final path = r'/v1/iot/commands/{deviceId}'
      .replaceAll('{deviceId}', deviceId);

    // ignore: prefer_final_locals
    Object? postBody = commandPayloadDto;

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

  /// Send command to device
  ///
  /// Parameters:
  ///
  /// * [String] deviceId (required):
  ///   ID of the device
  ///
  /// * [CommandPayloadDto] commandPayloadDto (required):
  Future<CommandStatusDto?> ioTCommandV1ControllerSendCommand(String deviceId, CommandPayloadDto commandPayloadDto,) async {
    final response = await ioTCommandV1ControllerSendCommandWithHttpInfo(deviceId, commandPayloadDto,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'CommandStatusDto',) as CommandStatusDto;
    
    }
    return null;
  }
}
