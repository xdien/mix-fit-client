// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liquor_kiln_control_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LiquorKilnControlStore on _LiquorKilnControlStore, Store {
  late final _$isSocketConnectedAtom =
      Atom(name: '_LiquorKilnControlStore.isSocketConnected', context: context);

  @override
  bool get isSocketConnected {
    _$isSocketConnectedAtom.reportRead();
    return super.isSocketConnected;
  }

  @override
  set isSocketConnected(bool value) {
    _$isSocketConnectedAtom.reportWrite(value, super.isSocketConnected, () {
      super.isSocketConnected = value;
    });
  }

  late final _$isHeater1OnAtom =
      Atom(name: '_LiquorKilnControlStore.isHeater1On', context: context);

  @override
  bool get isHeater1On {
    _$isHeater1OnAtom.reportRead();
    return super.isHeater1On;
  }

  @override
  set isHeater1On(bool value) {
    _$isHeater1OnAtom.reportWrite(value, super.isHeater1On, () {
      super.isHeater1On = value;
    });
  }

  late final _$isHeater2OnAtom =
      Atom(name: '_LiquorKilnControlStore.isHeater2On', context: context);

  @override
  bool get isHeater2On {
    _$isHeater2OnAtom.reportRead();
    return super.isHeater2On;
  }

  @override
  set isHeater2On(bool value) {
    _$isHeater2OnAtom.reportWrite(value, super.isHeater2On, () {
      super.isHeater2On = value;
    });
  }

  late final _$isHeater3OnAtom =
      Atom(name: '_LiquorKilnControlStore.isHeater3On', context: context);

  @override
  bool get isHeater3On {
    _$isHeater3OnAtom.reportRead();
    return super.isHeater3On;
  }

  @override
  set isHeater3On(bool value) {
    _$isHeater3OnAtom.reportWrite(value, super.isHeater3On, () {
      super.isHeater3On = value;
    });
  }

  late final _$overHeatTempAtom =
      Atom(name: '_LiquorKilnControlStore.overHeatTemp', context: context);

  @override
  double get overHeatTemp {
    _$overHeatTempAtom.reportRead();
    return super.overHeatTemp;
  }

  @override
  set overHeatTemp(double value) {
    _$overHeatTempAtom.reportWrite(value, super.overHeatTemp, () {
      super.overHeatTemp = value;
    });
  }

  late final _$coolingTempAtom =
      Atom(name: '_LiquorKilnControlStore.coolingTemp', context: context);

  @override
  double get coolingTemp {
    _$coolingTempAtom.reportRead();
    return super.coolingTemp;
  }

  @override
  set coolingTemp(double value) {
    _$coolingTempAtom.reportWrite(value, super.coolingTemp, () {
      super.coolingTemp = value;
    });
  }

  late final _$isWaterPumpOnAtom =
      Atom(name: '_LiquorKilnControlStore.isWaterPumpOn', context: context);

  @override
  bool get isWaterPumpOn {
    _$isWaterPumpOnAtom.reportRead();
    return super.isWaterPumpOn;
  }

  @override
  set isWaterPumpOn(bool value) {
    _$isWaterPumpOnAtom.reportWrite(value, super.isWaterPumpOn, () {
      super.isWaterPumpOn = value;
    });
  }

  late final _$resetWifiAsyncAction =
      AsyncAction('_LiquorKilnControlStore.resetWifi', context: context);

  @override
  Future<void> resetWifi() {
    return _$resetWifiAsyncAction.run(() => super.resetWifi());
  }

  late final _$updateSystemTimeAsyncAction =
      AsyncAction('_LiquorKilnControlStore.updateSystemTime', context: context);

  @override
  Future<void> updateSystemTime() {
    return _$updateSystemTimeAsyncAction.run(() => super.updateSystemTime());
  }

  late final _$toggleWaterPumpAsyncAction =
      AsyncAction('_LiquorKilnControlStore.toggleWaterPump', context: context);

  @override
  Future<void> toggleWaterPump() {
    return _$toggleWaterPumpAsyncAction.run(() => super.toggleWaterPump());
  }

  @override
  String toString() {
    return '''
isSocketConnected: ${isSocketConnected},
isHeater1On: ${isHeater1On},
isHeater2On: ${isHeater2On},
isHeater3On: ${isHeater3On},
overHeatTemp: ${overHeatTemp},
coolingTemp: ${coolingTemp},
isWaterPumpOn: ${isWaterPumpOn}
    ''';
  }
}
