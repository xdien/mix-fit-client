import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';
import '../../repository/auth/auth_repository.dart';

class RegisterUsecase implements UseCase<UserDto?, UserRegisterDto> {
  final AuthRepository _userRepository;

  RegisterUsecase(this._userRepository);

  @override
  Future<UserDto?> call({required UserRegisterDto params}) async {
    return _userRepository.register(params);
  }
}