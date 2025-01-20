import 'dart:async';

import 'package:api_client/api.dart';

abstract class AuthRepository {
  Future<LoginPayloadDto?> login(UserLoginDto params);

  Future<void> saveIsLoggedIn(bool value);

  Future<void> saveAuthToken(String authToken);
  Future<bool> removeAuthToken();
  
  Future<bool> get isLoggedIn;

  Future<String?> get accessToken;
}
