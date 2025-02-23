import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:constants/app_routes.dart';
import 'package:core/domain/usecase/use_case.dart';
import 'package:core/managers/connection_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../di/service_locator.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final IsLoggedInUseCase isLoggedInUseCase = getIt<IsLoggedInUseCase>();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    final ConnectionManager connectionManager = getIt<ConnectionManager>();
    await Future.delayed(Duration(seconds: 2));

    if (await isLoggedInUseCase.call(params: NoParams())) {
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
