import 'dart:async';

import '../../../constants/iot_param.dart';

abstract class UseCase<T, P> {
  FutureOr<T> call({ required P params});
}
// No params class for use cases that don't need parameters
class NoParams {}
class LiquorKilnTempParams {
  final String deviceId;
  final double temperature;

  LiquorKilnTempParams({
    required this.deviceId,
    required this.temperature,
  });
}

class IoTParams implements IIotParam {
  final String deviceId;
  IoTParams({
    required this.deviceId,
  });
}
