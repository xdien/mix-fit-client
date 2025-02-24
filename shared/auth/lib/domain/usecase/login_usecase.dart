import 'package:api_client/api.dart';
import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:core/domain/usecase/use_case.dart';

class LoginUseCase implements UseCase<LoginPayloadDto?, UserLoginDto> {
  final AuthRepository _userRepository;

  LoginUseCase(this._userRepository);

  @override
  Future<LoginPayloadDto?> call({required UserLoginDto params}) async {
    return _userRepository.login(params);
  }
}