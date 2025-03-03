import 'package:core/domain/usecase/use_case.dart';

class HeatingParams implements IIotParam {
  final String deviceId;
  final bool isOn;

  HeatingParams({
    required this.deviceId,
    required this.isOn,
  });
}
