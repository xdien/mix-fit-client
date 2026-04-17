
import 'package:constants/app_routes.dart';
import 'package:data/sharedpref/constants/preferences.dart';
import 'package:flutter/material.dart';
import 'package:setting/locale/app_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:go_router/go_router.dart';
import 'package:setting/theme_store.dart';
import 'package:core/module_management.dart';

class AppDrawer extends StatelessWidget {
  final ThemeStore themeStore;
  
  AppDrawer({
    Key? key,
    required this.themeStore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final moduleManagement = ModuleManagement.instance;
    final hasCustomerManagement = moduleManagement.hasModule('customer_management');
    final hasSalesDashboard = moduleManagement.hasModule('sales_dashboard');
    final hasVehicleRepairEntry = moduleManagement.hasModule('vehicle_repair_entry');
    final hasRepairQuoteEntry = moduleManagement.hasModule('repair_quote_entry');
    
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
          Divider(),
          _buildSectionHeader('IoT Management'),
          _buildMenuItem(
            context: context,
            icon: Icons.sensors,
            title: 'IoT Dashboard',
            onTap: () {
              context.go('/iot-dashboard');
              context.canPop();
            },
          ),
          _buildMenuItem(
            context: context,
            icon: Icons.attractions_sharp,
            title: localizations.translate('app_drawer_liquor_kiln'),
            onTap: () {
              context.go('/liquor-kiln');
              context.canPop();
            },
          ),
          // Only show Business Management section if CMS modules exist
          if (hasCustomerManagement || hasSalesDashboard || hasVehicleRepairEntry || hasRepairQuoteEntry) ...[
            Divider(),
            _buildSectionHeader('Business Management'),
            if (hasCustomerManagement)
              _buildMenuItem(
                context: context,
                icon: Icons.people,
                title: 'Customer Management',
                onTap: () {
                  context.go(AppRoutes.customers);
                  context.canPop();
                },
              ),
            if (hasSalesDashboard)
              _buildMenuItem(
                context: context,
                icon: Icons.dashboard,
                title: "Sales Dashboard",
                onTap: () {
                  context.go("/sales_dashboard");
                  context.canPop();
                },
              ),
            if (hasVehicleRepairEntry)
              _buildMenuItem(
                context: context,
                icon: Icons.car_repair,
                title: 'Vehicle Repair Entry',
                onTap: () {
                  context.go(AppRoutes.vehicleEntries);
                  context.canPop();
                },
              ),
            if (hasRepairQuoteEntry)
              _buildMenuItem(
                context: context,
                icon: Icons.build_circle,
                title: 'Repair & Quote Management',
                onTap: () {
                  context.go(AppRoutes.repairQuotes);
                  context.canPop();
                },
              ),
          ],
          Divider(),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
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