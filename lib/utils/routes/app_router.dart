import 'package:app_drawer/app_drawer.dart';
import 'package:auth/domain/usecase/is_logged_in_usecase.dart';
import 'package:core/domain/usecase/use_case.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:constants/app_routes.dart';
import 'package:home_screen/presentation/home/home.dart';
import 'package:setting/theme_store.dart';
import 'package:logging/logging.dart';

import '../../presentation/error/error_screen.dart';
import '../../presentation/login/login.dart';
import '../../presentation/register/register_screen.dart';
import '../../presentation/settings/setting_screen.dart';
import '../../presentation/splash/splash_screen.dart';
import 'module_manager.dart';

class AppRouter {
  static final IsLoggedInUseCase _isLoggedInUseCase =
      GetIt.instance<IsLoggedInUseCase>();

  // Shell route cho layout chung (drawer, bottom nav...)
  static final shellRoute = ShellRoute(
    builder: (context, state, child) {
      return Scaffold(
        drawer: AppDrawer(
          themeStore: GetIt.instance<ThemeStore>(),
        ),
        body: child,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomeScreen(),
      ),
      ...ModuleManager.instance.getModuleRoutes(),
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

      final isPublicPage = isLoggingIn ||
          isRegistering ||
          state.matchedLocation == AppRoutes.splash;

      if (!isLoggedIn && !isPublicPage) {
        return AppRoutes.login;
      }

      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return AppRoutes.home;
      }

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

      // Protected routes trong shell (has drawer)
      shellRoute,
    ],

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
