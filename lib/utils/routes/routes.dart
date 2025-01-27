import 'package:mix_fit/presentation/home/home.dart';
import 'package:mix_fit/presentation/login/login.dart';
import 'package:flutter/material.dart';
import 'package:mix_fit/presentation/register/register_screen.dart';

class Routes {
  Routes._();

  //static variables
  static const String splash = '/splash';
  static const String login = '/login';
  static const String home = '/post';
  static const String register = "/register";

  static final routes = <String, WidgetBuilder>{
    login: (BuildContext context) => LoginScreen(),
    home: (BuildContext context) => HomeScreen(),
    register: (BuildContext context) => RegisterScreen(),
  };
}
