import 'package:api_client/api.dart';
import 'package:core/domain/usecase/use_case.dart';

import '../../repository/auth/auth_repository.dart';
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
  final AuthRepository _userRepository;

  LoginUseCase(this._userRepository);

  @override
  Future<LoginPayloadDto?> call({required UserLoginDto params}) async {
    return _userRepository.login(params);
  }
}