// register_store.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mobx/mobx.dart';

import '../../../core/stores/error/error_store.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  // error store for handling errors
  final ErrorStore errorStore;

  _RegisterStore(this.errorStore);

  @observable
  String username = '';

  @observable
  String email = '';

  @observable
  String password = '';

  @observable
  String fullName = '';

  @observable
  String phone = '';

  @observable
  File? avatar;

  @observable
  bool isLoading = false;

  @observable
  bool passwordVisible = false;

  @computed
  bool get canRegister =>
      username.isNotEmpty &&
      email.isNotEmpty &&
      password.isNotEmpty &&
      fullName.isNotEmpty &&
      phone.isNotEmpty;

  @action
  void setUsername(String value) {
    username = value;
  }

  @action
  void setEmail(String value) {
    email = value;
  }

  @action
  void setPassword(String value) {
    password = value;
  }

  @action
  void setFullName(String value) {
    fullName = value;
  }

  @action
  void setPhone(String value) {
    phone = value;
  }

  @action
  void setAvatar(File value) {
    avatar = value;
  }

  @action
  void togglePasswordVisibility() {
    passwordVisible = !passwordVisible;
  }

  @action
  Future<bool> register() async {
    isLoading = true;
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        if (avatar != null)
          'avatar': await MultipartFile.fromFile(avatar!.path),
      });

      final response = await dio.post(
        'http://localhost:3000/auth/register',
        data: formData,
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      errorStore.setErrorMessage(e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }
}