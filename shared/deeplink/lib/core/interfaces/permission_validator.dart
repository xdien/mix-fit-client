import '../models/route_info.dart';

/// Interface for validating user permissions for deeplink routes
/// Handles role-based access control for navigation
abstract class IPermissionValidator {
  /// Check if the user has permission to access the specified route
  /// Returns true if user has required permissions, false otherwise
  Future<bool> hasPermission(String userId, RouteInfo route);
  
  /// Get the default fallback route for a user when permission is denied
  /// Returns route path that the user can safely access
  String getDefaultFallbackRoute(String userId);
  
  /// Load permission configuration from the specified path
  /// Throws exception if configuration is invalid or cannot be loaded
  Future<void> loadPermissionConfiguration(String configPath);
  
  /// Get all permissions for a specific user
  /// Returns list of permission strings the user has
  Future<List<String>> getUserPermissions(String userId);
  
  /// Check if a user has a specific role
  /// Returns true if user has the role, false otherwise
  Future<bool> hasRole(String userId, String role);
}