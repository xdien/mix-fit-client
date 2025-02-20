import 'package:core/domain/usecase/use_case.dart';

import '../../repository/auth/auth_repository.dart';

class SaveLoginStatusUseCase implements UseCase<void, bool> {
  final AuthRepository _userRepository;

  SaveLoginStatusUseCase(this._userRepository);

  @override
  Future<void> call({required bool params}) async {
    return _userRepository.saveIsLoggedIn(params);
  }
}