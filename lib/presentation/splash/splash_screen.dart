import 'package:flutter/material.dart';

import '../../core/managers/connection_manager.dart';
import '../../di/service_locator.dart';
import '../home/home.dart';
import '../login/login.dart';
import '../login/store/login_store.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  final UserStore _userStore = getIt<UserStore>();
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    final ConnectionManager connectionManager = getIt<ConnectionManager>();
    connectionManager.initialize();
    await Future.delayed(Duration(seconds: 2));

    if (_userStore.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/ic_appicon.png'),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
