import 'package:api_client/api.dart';
import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:constants/stores/error/error_store.dart';
import 'package:core/stores/form/form_store.dart';
import 'package:mix_fit/domain/usecase/auth/login_usecase.dart';
import 'package:mix_fit/domain/usecase/auth/save_auth_token_usecase.dart';
import 'package:mix_fit/domain/usecase/auth/save_login_in_status_usecase.dart';
import 'package:mobx/mobx.dart';
import '../../../domain/usecase/auth/remove_auth_token_usecase.dart';

part 'login_store.g.dart';

class UserStore = _UserStore with _$UserStore;

abstract class _UserStore with Store {
  // constructor:---------------------------------------------------------------
  _UserStore(
    this._isLoggedInUseCase,
    this._saveLoginStatusUseCase,
    this._saveAuthTokenUseCase,
    this._removeAuthTokenUseCase,
    this._loginUseCase,
    this.formErrorStore,
    this.errorStore,
  ) {
    // setting up disposers
    _setupDisposers();

    // checking if user is logged in
    _isLoggedInUseCase.call(params: null).then((value) async {
      isLoggedIn = value;
    });
  }

  // use cases:-----------------------------------------------------------------
  final IsLoggedInUseCase _isLoggedInUseCase;
  final SaveLoginStatusUseCase _saveLoginStatusUseCase;
  final SaveAuthTokenUseCase _saveAuthTokenUseCase;
  final RemoveAuthTokenUsecase _removeAuthTokenUseCase;
  final LoginUseCase _loginUseCase;

  // stores:--------------------------------------------------------------------
  // for handling form errors
  final FormErrorStore formErrorStore;

  // store for handling error messages
  final ErrorStore errorStore;

  // disposers:-----------------------------------------------------------------
  late List<ReactionDisposer> _disposers;

  void _setupDisposers() {
    _disposers = [
      reaction((_) => success, (_) => success = false, delay: 200),
    ];
  }

  // empty responses:-----------------------------------------------------------
  static ObservableFuture<LoginPayloadDto?> emptyLoginResponse =
      ObservableFuture.value(null);

  // store variables:-----------------------------------------------------------
  bool isLoggedIn = false;

  @observable
  bool success = false;

  @observable
  ObservableFuture<LoginPayloadDto?> loginFuture = emptyLoginResponse;

  @computed
  bool get isLoading => loginFuture.status == FutureStatus.pending;

  // actions:-------------------------------------------------------------------
  @action
  Future login(String email, String password) async {
    final UserLoginDto loginParams =
        UserLoginDto(email: email, password: password);
    final future = _loginUseCase.call(params: loginParams);
    loginFuture = ObservableFuture(future);

    await future.then((value) async {
      if (value != null) {
        await _saveLoginStatusUseCase.call(params: true);
        await _saveAuthTokenUseCase.call(params: value.token.accessToken);
        this.isLoggedIn = true;
        this.success = true;
      }
    }).catchError((e) {
      this.isLoggedIn = false;
      this.success = false;
      errorStore.setErrorMessage(e.toString());
      throw e;
    });
  }

  logout() async {
    this.isLoggedIn = false;
    await _saveLoginStatusUseCase.call(params: false);
    await _removeAuthTokenUseCase.call(params: null);
  }

  // general methods:-----------------------------------------------------------
  void dispose() {
    for (final d in _disposers) {
      d();
    }
  }
}
