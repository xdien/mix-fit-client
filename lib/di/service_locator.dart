import 'package:mix_fit/domain/di/domain_layer_injection.dart';
import 'package:mix_fit/presentation/di/presentation_layer_injection.dart';
import 'package:get_it/get_it.dart';
import 'package:core/di/core_module.dart';
import '../data/di/data_layer_injection.dart';


final getIt = GetIt.instance;

class ServiceLocator {
  static Future<void> configureDependencies() async {
    // Initialize core shared modules first
    await CoreModule.configureCoreModuleInjection(getIt);
    
    // Initialize application layers
    await DataLayerInjection.configureDataLayerInjection();
    await DomainLayerInjection.configureDomainLayerInjection();
    await PresentationLayerInjection.configurePresentationLayerInjection();
  }

  /// Disposes all registered dependencies
  static Future<void> disposeDependencies() async {
    // Dispose in reverse order of registration
    await CoreModule.disposeCoreModule(getIt);
    
    // Reset the GetIt instance
    await getIt.reset();
  }
}
