import 'dart:async';

abstract class UseCase<T, P> {
  FutureOr<T> call({ required P params});
}
// No params class for use cases that don't need parameters
class NoParams {}
class LiquorKilnTempParams {
  final String deviceId;
  final double temperatureOverheat;

  LiquorKilnTempParams({
    required this.deviceId,
    required this.temperatureOverheat,
  });
}
