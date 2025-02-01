import 'package:flutter/material.dart';
import 'package:mix_fit/constants/app_routes.dart';
import 'package:mix_fit/data/sharedpref/constants/preferences.dart';
import 'package:mix_fit/presentation/home/store/theme/theme_store.dart';
import 'package:mix_fit/utils/locale/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../di/service_locator.dart';
import '../store/navigation_store.dart';
import '../store/ui_store.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  final ThemeStore themeStore;
  final UIStore _uiStore = getIt<UIStore>();
  final NavigationStore navigationStore = getIt<NavigationStore>();
  
  AppDrawer({
    Key? key,
    required this.themeStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),
          _buildMenuItem(
            context: context,
            icon: Icons.home,
            title: localizations.translate('home_title'),
            onTap: () => context.canPop(),
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.attractions_sharp,
            title: localizations.translate('app_drawer_liquor_kiln'),
            onTap: () {
              context.go(AppRoutes.liquorKiln);
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.settings,
            title: localizations.translate('home_settings') ,
            onTap: () {
              context.go(AppRoutes.settings);
              context.canPop();
            },
          ),
          Divider(),
          _buildMenuItem(
            context: context,
            icon: Icons.logout,
            title: localizations.translate('home_logout') ,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35),
          ),
          SizedBox(height: 10),
          Text(
            'Mix Fit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Preferences.is_logged_in, false);
    context.go(AppRoutes.login);
  }
}