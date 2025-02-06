import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mix_fit/utils/locale/app_localization.dart';
import 'package:mix_fit/presentation/home/store/theme/theme_store.dart';
import 'package:mix_fit/presentation/home/store/language/language_store.dart';
import 'package:mix_fit/di/service_locator.dart';

import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // stores
  final ThemeStore _themeStore = getIt<ThemeStore>();
  final LanguageStore _languageStore = getIt<LanguageStore>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        themeStore: this._themeStore,
      ),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(AppLocalizations.of(context).translate('settings_title')),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('settings_theme'),
          const SizedBox(height: 16.0),
          _buildThemeSettings(),
          const SizedBox(height: 24.0),
          _buildSectionTitle('settings_language'),
          const SizedBox(height: 16.0),
          _buildLanguageSettings(),
          // Add more settings sections here
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titleKey) {
    return Text(
      AppLocalizations.of(context).translate(titleKey).toUpperCase(),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildThemeSettings() {
    return Observer(
      builder: (_) => Card(
        child: ListTile(
          title: Text(
            AppLocalizations.of(context).translate('settings_dark_mode'),
          ),
          trailing: Switch(
            value: _themeStore.darkMode,
            onChanged: (bool value) {
              _themeStore.changeBrightnessToDark(value);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSettings() {
    return Observer(
      builder: (_) => Card(
        child: ListTile(
          title: Text(
            AppLocalizations.of(context).translate('settings_current_language'),
          ),
          subtitle: Text(
            _languageStore.getLanguage() ?? 'English',
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: _showLanguageDialog,
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('settings_choose_language'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languageStore.supportedLanguages
                .map(
                  (language) => ListTile(
                    title: Text(language.language),
                    selected: _languageStore.locale == language.locale,
                    onTap: () {
                      _languageStore.changeLanguage(language.locale);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
