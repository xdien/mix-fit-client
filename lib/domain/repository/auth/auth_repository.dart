import 'dart:async';

import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class AuthRepository {
  Future<bool> get isLoggedIn;

  Future<String?> get accessToken;
  Stream<bool> get authStateChanges;
  Future<LoginPayloadDto?> login(UserLoginDto params);

  Future<void> saveIsLoggedIn(bool value);

  Future<void> saveAuthToken(String authToken);
  Future<bool> removeAuthToken();
  Future<UserDto?> register(UserRegisterDto params);
}
