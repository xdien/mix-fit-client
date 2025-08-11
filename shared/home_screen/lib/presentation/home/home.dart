
import 'package:app_drawer/app_drawer.dart';
import 'package:constants/app_routes.dart';
import 'package:data/sharedpref/constants/preferences.dart';
import 'package:setting/locale/app_localization.dart';
import 'package:setting/theme_store.dart';
import 'store/language/language_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:core/module_management.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //stores:---------------------------------------------------------------------
  final ThemeStore _themeStore = GetIt.instance<ThemeStore>();
  final LanguageStore _languageStore = GetIt.instance<LanguageStore>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(themeStore: _themeStore),
      body: _bodyBuilder(),
    );
  }

  // app bar methods:-----------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context).translate('home_tv_posts')),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return <Widget>[
      _buildLanguageButton(),
      _buildThemeButton(),
      _buildLogoutButton(),
    ];
  }

  Widget _buildThemeButton() {
    return Observer(
      builder: (context) {
        return IconButton(
          onPressed: () {
            _themeStore.changeBrightnessToDark(!_themeStore.darkMode);
          },
          icon: Icon(
            _themeStore.darkMode ? Icons.brightness_5 : Icons.brightness_3,
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return IconButton(
      onPressed: () {
        SharedPreferences.getInstance().then((preference) {
          preference.setBool(Preferences.is_logged_in, false);
          context.go(AppRoutes.login);
        });
      },
      icon: Icon(
        Icons.power_settings_new,
      ),
    );
  }

  Widget _buildLanguageButton() {
    return IconButton(
      onPressed: () {
        _buildLanguageDialog();
      },
      icon: Icon(
        Icons.language,
      ),
    );
  }

  _buildLanguageDialog() {
    _showDialog<String>(
      context: context,
      child: AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('home_tv_choose_language'),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: _languageStore.supportedLanguages
            .map(
              (object) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.all(0.0),
                title: Text(
                  object.language,
                  style: TextStyle(
                    color: _languageStore.locale == object.locale
                        ? Theme.of(context).primaryColor
                        : _themeStore.darkMode
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _languageStore.changeLanguage(object.locale);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  _showDialog<T>({required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
    });
  }

  _bodyBuilder() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Welcome section
          _buildWelcomeSection(),
          SizedBox(height: 32.0),
          
          // Module Overview
          _buildModuleOverview(),
          SizedBox(height: 32.0),
          
          // Quick Actions
          _buildQuickActions(),
          SizedBox(height: 32.0),
          
          // System Overview
          _buildSystemOverview(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.dashboard,
            size: 64,
            color: Colors.blue[600],
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('home_tv_welcome'),
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue[600],
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            'System Management Dashboard',
            style: TextStyle(
              fontSize: 16.0,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleOverview() {
    final moduleManagement = ModuleManagement.instance;
    final hasCustomerManagement = moduleManagement.hasModule('customer_management');
    final hasSalesDashboard = moduleManagement.hasModule('sales_dashboard');
    
    // Build list of available modules
    final List<Widget> moduleCards = [
      _buildModuleCard(
        title: 'IoT Dashboard',
        subtitle: 'Device monitoring and control',
        icon: Icons.sensors,
        color: Colors.blue,
        onTap: () => context.go('/iot-dashboard'),
      ),
    ];

    // Add CMS modules only if they exist
    if (hasCustomerManagement) {
      moduleCards.add(
        _buildModuleCard(
          title: 'Customer Management',
          subtitle: 'Manage customer data',
          icon: Icons.people,
          color: Colors.green,
          onTap: () => context.push(AppRoutes.customers),
        ),
      );
    }

    if (hasSalesDashboard) {
      moduleCards.add(
        _buildModuleCard(
          title: 'Sales Dashboard',
          subtitle: 'Business analytics',
          icon: Icons.analytics,
          color: Colors.orange,
          onTap: () => context.go('/sales_dashboard'),
        ),
      );
    }

    // Always add settings
    moduleCards.add(
      _buildModuleCard(
        title: 'System Settings',
        subtitle: 'Configure application',
        icon: Icons.settings,
        color: Colors.purple,
        onTap: () => context.push(AppRoutes.settings),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Modules',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.2,
          children: moduleCards,
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final moduleManagement = ModuleManagement.instance;
    final hasCustomerManagement = moduleManagement.hasModule('customer_management');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'IoT Dashboard',
                icon: Icons.sensors,
                onTap: () => context.go('/iot-dashboard'),
              ),
            ),
            if (hasCustomerManagement) ...[
              SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  title: 'Customers',
                  icon: Icons.people,
                  onTap: () => context.push(AppRoutes.customers),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    final moduleManagement = ModuleManagement.instance;
    final hasCustomerManagement = moduleManagement.hasModule('customer_management');
    final hasSalesDashboard = moduleManagement.hasModule('sales_dashboard');
    
    // Count active modules
    int activeModules = 1; // IoT module is always available
    if (hasCustomerManagement) activeModules++;
    if (hasSalesDashboard) activeModules++;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Overview',
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildOverviewRow('Active Modules', '$activeModules', Colors.green),
                Divider(),
                _buildOverviewRow('Total Users', '12', Colors.blue),
                Divider(),
                _buildOverviewRow('System Status', 'Online', Colors.green),
                Divider(),
                _buildOverviewRow('Last Update', 'Just now', Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
