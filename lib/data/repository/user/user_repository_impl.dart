import 'dart:async';
import 'package:api_client/api.dart';
import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:data/sharedpref/shared_preference_helper.dart';

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

  @override
  Future<String?> get accessToken => _sharedPrefsHelper.authToken;

  @override
  Future<void> saveAuthToken(String authToken) =>
      _sharedPrefsHelper.saveAuthToken(authToken);
  
  @override
  Future<bool> removeAuthToken() => _sharedPrefsHelper.removeAuthToken();
  
  @override
  Stream<bool> get authStateChanges => _sharedPrefsHelper.authStateChanges;
  
  @override
  Future<UserDto?> register(params) async {
    return _userApi.authControllerUserRegister(params.username, params.email, params.password);

  }
}
