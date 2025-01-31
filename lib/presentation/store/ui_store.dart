import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

import '../post/post_list.dart';
part 'ui_store.g.dart';

class UIStore = _UIStore with _$UIStore;

abstract class _UIStore with Store {
  @observable
  Widget currentScreen = PostListScreen();

  @action
  void changeScreen(Widget screen) {
    currentScreen = screen;
  }
}