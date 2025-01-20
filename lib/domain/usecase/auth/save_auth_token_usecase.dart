import '../../../core/domain/usecase/use_case.dart';
import '../../repository/auth/auth_repository.dart';

class SaveAuthTokenUseCase implements UseCase<void, String> {
  final AuthRepository _userRepository;

  SaveAuthTokenUseCase(this._userRepository);

  @override
  Future<void> call({required String params}) async {
    return _userRepository.saveAuthToken(params);
  }
}