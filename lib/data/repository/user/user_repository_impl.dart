import 'dart:async';

import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';

import 'package:api_client/api.dart';

import '../../../domain/repository/auth/auth_repository.dart';

class UserRepositoryImpl extends AuthRepository {
  // shared pref object
  final SharedPreferenceHelper _sharedPrefsHelper;
  final ApiClient _apiClient;
  late final AuthApi _userApi;

   UserRepositoryImpl(this._sharedPrefsHelper, this._apiClient) {
      _userApi = AuthApi(_apiClient);
   }

  // Login:---------------------------------------------------------------------
  @override
  Future<LoginPayloadDto?> login(UserLoginDto params) async {
    try {
      final result = await _userApi.authControllerUserLogin(params);
      return result;
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<void> saveIsLoggedIn(bool value) =>
      _sharedPrefsHelper.saveIsLoggedIn(value);

  @override
  Future<bool> get isLoggedIn => _sharedPrefsHelper.isLoggedIn;
}
