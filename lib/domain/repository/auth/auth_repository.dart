import 'dart:async';
import 'dart:ffi';

import 'package:api_client/api.dart';

abstract class AuthRepository {
  Future<bool> get isLoggedIn;

  Future<String?> get accessToken;
  Stream<bool> get authStateChanges;
  Future<LoginPayloadDto?> login(UserLoginDto params);

  Future<void> saveIsLoggedIn(bool value);

  Future<void> saveAuthToken(String authToken);
  Future<bool> removeAuthToken();
  Future<bool> register(UserRegisterDto params);
}
