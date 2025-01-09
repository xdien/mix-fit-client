import 'dart:async';

import 'package:mix_fit/data/network/apis/lib/api.dart';

abstract class UserRepository {
  Future<LoginPayloadDto?> login(UserLoginDto params);

  Future<void> saveIsLoggedIn(bool value);

  Future<bool> get isLoggedIn;
}
