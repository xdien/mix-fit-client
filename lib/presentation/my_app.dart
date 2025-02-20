import 'package:constants/app_theme.dart';
import 'package:constants/strings.dart';
import 'package:mix_fit/presentation/home/store/language/language_store.dart';
import 'package:mix_fit/presentation/home/store/theme/theme_store.dart';
import 'package:mix_fit/utils/locale/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../di/service_locator.dart';
import '../utils/routes/app_router.dart';

class MyApp extends StatelessWidget {
 final ThemeStore _themeStore = getIt<ThemeStore>();
 final LanguageStore _languageStore = getIt<LanguageStore>();

 @override
 Widget build(BuildContext context) {
   return Observer(
     builder: (context) {
       return MaterialApp.router(
         debugShowCheckedModeBanner: false,
         title: Strings.appName,
         theme: _themeStore.darkMode
             ? AppThemeData.darkThemeData
             : AppThemeData.lightThemeData,
         routerConfig: AppRouter.router,
         locale: Locale(_languageStore.locale),
         supportedLocales: _languageStore.supportedLanguages
             .map((language) => Locale(language.locale, language.code))
             .toList(),
         localizationsDelegates: [
           AppLocalizations.delegate,
           GlobalMaterialLocalizations.delegate,
           GlobalWidgetsLocalizations.delegate,
           GlobalCupertinoLocalizations.delegate,
         ],
       );
     },
   );
 }
}