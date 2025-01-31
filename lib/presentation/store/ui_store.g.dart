// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ui_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$UIStore on _UIStore, Store {
  late final _$currentScreenAtom =
      Atom(name: '_UIStore.currentScreen', context: context);

  @override
  Widget get currentScreen {
    _$currentScreenAtom.reportRead();
    return super.currentScreen;
  }

  @override
  set currentScreen(Widget value) {
    _$currentScreenAtom.reportWrite(value, super.currentScreen, () {
      super.currentScreen = value;
    });
  }

  late final _$_UIStoreActionController =
      ActionController(name: '_UIStore', context: context);

  @override
  void changeScreen(Widget screen) {
    final _$actionInfo =
        _$_UIStoreActionController.startAction(name: '_UIStore.changeScreen');
    try {
      return super.changeScreen(screen);
    } finally {
      _$_UIStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
currentScreen: ${currentScreen}
    ''';
  }
}
