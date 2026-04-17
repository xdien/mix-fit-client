import '../models/route_info.dart';
import '../models/navigation_result.dart';
import '../models/navigation_context.dart';

/// Interface for handling navigation to specific screens or features
/// Provides platform-specific navigation implementation
abstract class INavigationHandler {
  /// Navigate to the target screen specified in the route
  /// Returns NavigationResult indicating success or failure
  Future<NavigationResult> navigate(RouteInfo route);
  
  /// Set the navigation context for the handler
  /// Context provides access to navigation stack and application state
  void setNavigationContext(NavigationContext? context);
  
  /// Register a screen handler for a specific screen identifier
  /// Handler function will be called when navigating to the screen
  void registerScreenHandler(String screenId, Function(RouteInfo) handler);
  
  /// Check if navigation to a specific screen is currently possible
  /// Returns true if navigation can proceed, false otherwise
  bool canNavigateToScreen(String screenId);
}