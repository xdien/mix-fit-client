import 'package:constants/app_routes.dart';
import 'package:core/managers/connection_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../di/service_locator.dart';
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
    await Future.delayed(Duration(seconds: 2));

    if (_userStore.isLoggedIn) {
      connectionManager.initialize();
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.login);
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
