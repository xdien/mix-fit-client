import 'dart:async';

import 'package:api_client/api.dart';

abstract class UserRepository {
  Future<LoginPayloadDto?> login(UserLoginDto params);

  Future<void> saveIsLoggedIn(bool value);

  Future<bool> get isLoggedIn;
}
