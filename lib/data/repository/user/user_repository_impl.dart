import 'dart:async';

import 'package:mix_fit/domain/repository/user/user_repository.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';

import 'package:api_client/api.dart';

class UserRepositoryImpl extends UserRepository {
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
      return await _userApi.authControllerUserLogin(params);
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
