import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mix_fit/core/domain/usecase/use_case.dart';
import 'package:mix_fit/presentation/home/home.dart';
import 'package:logging/logging.dart';
import 'package:mix_fit/presentation/liquorkiln-control/liquor_kiln_control_screen.dart';
import 'package:mix_fit/presentation/widgets/app_drawer.dart';

import '../../constants/app_routes.dart';
import '../../di/service_locator.dart';
import '../../domain/usecase/auth/is_logged_in_usecase.dart';
import '../../presentation/error/error_screen.dart';
import '../../presentation/home/store/theme/theme_store.dart';
import '../../presentation/liquorkiln/view/liquor_kiln_screen.dart';
import '../../presentation/login/login.dart';
import '../../presentation/register/register_screen.dart';
import '../../presentation/settings/setting_screen.dart';
import '../../presentation/splash/splash_screen.dart';

class AppRouter {
  final _logger = Logger('AppRouter');
  static final IsLoggedInUseCase _isLoggedInUseCase =
      getIt<IsLoggedInUseCase>();

  // Shell route cho layout chung (drawer, bottom nav...)
  static final shellRoute = ShellRoute(
    builder: (context, state, child) {
      return Scaffold(
        drawer: AppDrawer(
          themeStore: getIt<ThemeStore>(),
        ),
        body: child,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (context, state) {
          UnimplementedError('Not implemented yet');
          return Container();
        },
      ),
      GoRoute(
        path: AppRoutes.liquorKiln,
        builder: (context, state) => LiquorKilnScreen(),
      ),
      GoRoute(path: AppRoutes.liquorKilnControl, builder: (context, state) {
        final deviceId = state.pathParameters['deviceId']!;
        return LiquorKilnControlScreen(deviceId: deviceId);
      }),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) {
          return SettingsScreen();
        },
      ),
    ],
  );

  static final router = GoRouter(
    initialLocation: AppRoutes.splash,

    // Redirect logic
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await _isLoggedInUseCase.call(params: NoParams());
      final isLoggingIn = state.matchedLocation == AppRoutes.login;
      final isRegistering = state.matchedLocation == AppRoutes.register;

      // Cho phép truy cập một số routes public nếu cần
      final isPublicPage = isLoggingIn ||
          isRegistering ||
          state.matchedLocation == AppRoutes.splash;

      // Nếu chưa login và không ở trang public -> login
      if (!isLoggedIn && !isPublicPage) {
        return AppRoutes.login;
      }

      // Nếu đã login mà vào trang login/register -> home
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return AppRoutes.home;
      }

      // Cho phép truy cập route hiện tại
      return null;
    },

    // Error handling
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error,
    ),

    // Route configuration
    routes: [
      // Public routes
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => RegisterScreen(),
      ),

      // Protected routes trong shell (có drawer)
      shellRoute,
    ],

    // Router observers cho analytics/logging
    observers: [
      GoRouterObserver(),
    ],

    // Debug logging
    debugLogDiagnostics: true,
  );
}

class GoRouterObserver extends NavigatorObserver {
  final _logger = Logger('AppRouter');
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.log(Level.INFO, 'New route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logger.log(Level.INFO, 'Route popped: ${route.settings.name}');
  }
}
