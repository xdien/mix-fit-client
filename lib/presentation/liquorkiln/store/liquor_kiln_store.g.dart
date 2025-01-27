// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liquor_kiln_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$LiquorKilnStore on _LiquorKilnStore, Store {
  Computed<Color>? _$temperatureColorComputed;

  @override
  Color get temperatureColor => (_$temperatureColorComputed ??= Computed<Color>(
          () => super.temperatureColor,
          name: '_LiquorKilnStore.temperatureColor'))
      .value;

  late final _$temperatureDataAtom =
      Atom(name: '_LiquorKilnStore.temperatureData', context: context);

  @override
  ObservableList<FlSpot> get temperatureData {
    _$temperatureDataAtom.reportRead();
    return super.temperatureData;
  }

  @override
  set temperatureData(ObservableList<FlSpot> value) {
    _$temperatureDataAtom.reportWrite(value, super.temperatureData, () {
      super.temperatureData = value;
    });
  }

  late final _$isSocketConnectedAtom =
      Atom(name: '_LiquorKilnStore.isSocketConnected', context: context);

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

  late final _$isOnlineAtom =
      Atom(name: '_LiquorKilnStore.isOnline', context: context);

  @override
  bool get isOnline {
    _$isOnlineAtom.reportRead();
    return super.isOnline;
  }

  @override
  set isOnline(bool value) {
    _$isOnlineAtom.reportWrite(value, super.isOnline, () {
      super.isOnline = value;
    });
  }

  late final _$currentTemperatureAtom =
      Atom(name: '_LiquorKilnStore.currentTemperature', context: context);

  @override
  double get currentTemperature {
    _$currentTemperatureAtom.reportRead();
    return super.currentTemperature;
  }

  @override
  set currentTemperature(double value) {
    _$currentTemperatureAtom.reportWrite(value, super.currentTemperature, () {
      super.currentTemperature = value;
    });
  }

  late final _$isControl1OnAtom =
      Atom(name: '_LiquorKilnStore.isControl1On', context: context);

  @override
  bool get isControl1On {
    _$isControl1OnAtom.reportRead();
    return super.isControl1On;
  }

  @override
  set isControl1On(bool value) {
    _$isControl1OnAtom.reportWrite(value, super.isControl1On, () {
      super.isControl1On = value;
    });
  }

  late final _$isControl2OnAtom =
      Atom(name: '_LiquorKilnStore.isControl2On', context: context);

  @override
  bool get isControl2On {
    _$isControl2OnAtom.reportRead();
    return super.isControl2On;
  }

  @override
  set isControl2On(bool value) {
    _$isControl2OnAtom.reportWrite(value, super.isControl2On, () {
      super.isControl2On = value;
    });
  }

  late final _$isControl3OnAtom =
      Atom(name: '_LiquorKilnStore.isControl3On', context: context);

  @override
  bool get isControl3On {
    _$isControl3OnAtom.reportRead();
    return super.isControl3On;
  }

  @override
  set isControl3On(bool value) {
    _$isControl3OnAtom.reportWrite(value, super.isControl3On, () {
      super.isControl3On = value;
    });
  }

  late final _$toggleControlAsyncAction =
      AsyncAction('_LiquorKilnStore.toggleControl', context: context);

  @override
  Future<void> toggleControl(String controlType, bool currentState) {
    return _$toggleControlAsyncAction
        .run(() => super.toggleControl(controlType, currentState));
  }

  @override
  String toString() {
    return '''
temperatureData: ${temperatureData},
isSocketConnected: ${isSocketConnected},
isOnline: ${isOnline},
currentTemperature: ${currentTemperature},
isControl1On: ${isControl1On},
isControl2On: ${isControl2On},
isControl3On: ${isControl3On},
temperatureColor: ${temperatureColor}
    ''';
  }
}
