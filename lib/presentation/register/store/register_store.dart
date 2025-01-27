// register_store.dart
import 'dart:io';

import 'package:mix_fit/data/network/apis/lib/api.dart';
import 'package:mobx/mobx.dart';

import '../../../core/stores/error/error_store.dart';

part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  // error store for handling errors
  final ErrorStore errorStore;

  // disposers:-----------------------------------------------------------------
  late List<ReactionDisposer> _disposers;

  @observable
  bool success = false;
  _RegisterStore(this.errorStore) {
    _setupDisposers();
  }

  void _setupDisposers() {
    _disposers = [
      reaction((_) => success, (_) => success = false, delay: 200),
    ];
  }

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
  Future<UserDto> register() async {
    isLoading = true;
    try {
    } catch (e) {
      errorStore.setErrorMessage(e.toString());
      return false;
    } finally {
      isLoading = false;
    }
  }
  // general methods:-----------------------------------------------------------
  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }
}