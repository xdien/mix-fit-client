import 'package:mix_fit/data/network/apis/lib/api.dart';

import '../../../core/domain/usecase/use_case.dart';
import '../../repository/user/user_repository.dart';
import 'package:json_annotation/json_annotation.dart';

part 'login_usecase.g.dart';

@JsonSerializable()
class LoginParams {
  final String username;
  final String password;

  LoginParams({required this.username, required this.password});

  factory LoginParams.fromJson(Map<String, dynamic> json) =>
      _$LoginParamsFromJson(json);

  Map<String, dynamic> toJson() => _$LoginParamsToJson(this);
}

class LoginUseCase implements UseCase<LoginPayloadDto?, UserLoginDto> {
  final UserRepository _userRepository;

  LoginUseCase(this._userRepository);

  @override
  Future<LoginPayloadDto?> call({required UserLoginDto params}) async {
    return _userRepository.login(params);
  }
}