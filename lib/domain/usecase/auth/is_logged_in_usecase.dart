import 'package:core/domain/usecase/use_case.dart';
import '../../repository/auth/auth_repository.dart';

class IsLoggedInUseCase implements UseCase<bool, void> {
  final AuthRepository _userRepository;

  IsLoggedInUseCase(this._userRepository);

  @override
  Future<bool> call({required void params}) async {
    return await _userRepository.isLoggedIn;
  }
}
