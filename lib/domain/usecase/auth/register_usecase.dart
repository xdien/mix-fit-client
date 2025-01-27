import '../../../core/domain/usecase/use_case.dart';
import '../../../data/network/apis/lib/api.dart';
import '../../repository/auth/auth_repository.dart';

class RegisterUsecase implements UseCase<LoginPayloadDto?, UserLoginDto> {
  final AuthRepository _userRepository;

  RegisterUsecase(this._userRepository);

  @override
  Future<LoginPayloadDto?> call({required UserLoginDto params}) async {
    return _userRepository.login(params);
  }
}