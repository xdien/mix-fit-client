import 'package:constants/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class ErrorScreen extends StatelessWidget {
  final dynamic error;

  const ErrorScreen({Key? key, this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Đã có lỗi xảy ra'),
            if (error != null) 
              Text(error.toString()),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}