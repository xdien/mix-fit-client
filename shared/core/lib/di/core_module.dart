import 'package:get_it/get_it.dart';
import 'error_module.dart';

/// Main module for registering all shared core dependencies
class CoreModule {
  /// Configures all shared core dependencies in the GetIt container
  static Future<void> configureCoreModuleInjection(GetIt getIt) async {
    // Register error system dependencies
    await ErrorModule.configureErrorModuleInjection(getIt);
    
    // Future modules can be added here
    // await OtherModule.configureOtherModuleInjection(getIt);
  }

  /// Disposes of all shared core dependencies
  static Future<void> disposeCoreModule(GetIt getIt) async {
    // Dispose modules in reverse order of registration
    await ErrorModule.disposeErrorModule(getIt);
    
    // Future module disposals can be added here
    // await OtherModule.disposeOtherModule(getIt);
  }
}