import 'package:auth/domain/repository/auth/auth_repository.dart';
import 'package:core/domain/usecase/use_case.dart';

class RemoveAuthTokenUsecase implements UseCase<void, void> {
  final AuthRepository _userRepository;

  RemoveAuthTokenUsecase(this._userRepository);

  @override
  Future<void> call({required void params}) async {
    _userRepository.removeAuthToken();
  }
}