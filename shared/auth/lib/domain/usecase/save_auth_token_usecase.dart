import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:core/domain/usecase/use_case.dart';

class SaveAuthTokenUseCase implements UseCase<void, String> {
  final AuthRepository _userRepository;

  SaveAuthTokenUseCase(this._userRepository);

  @override
  Future<void> call({required String params}) async {
    return _userRepository.saveAuthToken(params);
  }
}