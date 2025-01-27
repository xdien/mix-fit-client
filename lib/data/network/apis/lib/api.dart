//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/auth_api.dart';
part 'api/cms_api.dart';
part 'api/default_api.dart';
part 'api/io_t_api.dart';
part 'api/io_t_commands_api.dart';
part 'api/telemetry_api.dart';
part 'api/users_api.dart';

part 'model/cms_login_dto.dart';
part 'model/cms_login_payload_dto.dart';
part 'model/command_parameters_dto.dart';
part 'model/command_payload_dto.dart';
part 'model/command_status_dto.dart';
part 'model/device_status_event_dto.dart';
part 'model/device_type_dto.dart';
part 'model/health_checker_controller_check200_response.dart';
part 'model/health_checker_controller_check200_response_info_value.dart';
part 'model/health_checker_controller_check503_response.dart';
part 'model/io_t_events.dart';
part 'model/liquor_kiln_command_action_dto.dart';
part 'model/login_payload_dto.dart';
part 'model/metric_dto.dart';
part 'model/oil_temperature_data.dart';
part 'model/oil_temperature_event.dart';
part 'model/order.dart';
part 'model/page_dto.dart';
part 'model/page_meta_dto.dart';
part 'model/page_response_of_user_dto.dart';
part 'model/role_type.dart';
part 'model/sensor_data_event_dto.dart';
part 'model/telemetry_payload_dto.dart';
part 'model/token_payload_dto.dart';
part 'model/user_dto.dart';
part 'model/user_login_dto.dart';
part 'model/user_register_dto.dart';


/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) => pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
