// register_store.dart
import 'dart:io';
import 'package:api_client/api.dart';
import 'package:core/stores/error/error_store.dart';
import 'package:mix_fit/domain/usecase/auth/register_usecase.dart';
import 'package:mobx/mobx.dart';
part 'register_store.g.dart';

class RegisterStore = _RegisterStore with _$RegisterStore;

abstract class _RegisterStore with Store {
  // error store for handling errors
  final ErrorStore errorStore;

  // disposers:-----------------------------------------------------------------
  late List<ReactionDisposer> _disposers;
  final RegisterUsecase _registerUsecase;

  @observable
  bool success = false;
  _RegisterStore(this.errorStore, this._registerUsecase) {
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
  Future<UserDto?> register() async {
    isLoading = true;
    try {
      final user = this._registerUsecase.call(params: this.toDto());
      return user;
    } catch (e) {
      errorStore.setErrorMessage(e.toString());
      return null;
    } finally {
      isLoading = false;
    }
  }

  UserRegisterDto toDto() {
    return UserRegisterDto(
      username: username,
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }
  // general methods:-----------------------------------------------------------
  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }
}