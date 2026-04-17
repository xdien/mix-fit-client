import '../models/deeplink_request.dart';
import '../models/route_info.dart';

/// Interface for resolving deeplink routes to application navigation targets
/// Handles route configuration loading and route matching
abstract class IRouteResolver {
  /// Resolve a deeplink request to a specific route configuration
  /// Returns RouteInfo containing navigation details and parameters
  Future<RouteInfo> resolveRoute(DeeplinkRequest request);
  
  /// Check if a specific module and feature combination is supported
  /// Returns true if the route exists in configuration
  bool isRouteSupported(String module, String feature);
  
  /// Load route configuration from the specified path
  /// Throws exception if configuration is invalid or cannot be loaded
  Future<void> loadRouteConfiguration(String configPath);
  
  /// Get all available routes for a specific module
  /// Returns list of supported features for the module
  List<String> getAvailableRoutes(String module);
}