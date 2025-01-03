import 'dart:async';

import 'package:mix_fit/domain/repository/user/user_repository.dart';
import 'package:mix_fit/data/sharedpref/shared_preference_helper.dart';

import '../../../domain/entity/user/user.dart';
import '../../../domain/usecase/user/login_usecase.dart';
import 'package:api_client/api.dart';

class UserRepositoryImpl extends UserRepository {
  // shared pref object
  final SharedPreferenceHelper _sharedPrefsHelper;
  final DefaultApi _userApi;

  // constructor
   UserRepositoryImpl(this._sharedPrefsHelper, ApiClient apiClient)
      : _userApi = DefaultApi(apiClient);

  // Login:---------------------------------------------------------------------
  @override
  Future<User?> login(LoginParams params) async {
    try {
      final response = await _userApi.test11Get();
      print(response?.foo);
    } catch (e) {
      print(e);
      throw e;
    }
    return await Future.delayed(Duration(seconds: 2), () => User());
  }

  @override
  Future<void> saveIsLoggedIn(bool value) =>
      _sharedPrefsHelper.saveIsLoggedIn(value);

  @override
  Future<bool> get isLoggedIn => _sharedPrefsHelper.isLoggedIn;
}
