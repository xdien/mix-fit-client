/// Contains information about a resolved deeplink route
/// Includes navigation target, parameters, and permission requirements
class RouteInfo {
  /// Unique identifier for the route
  final String routeId;
  
  /// Application module this route belongs to
  final String module;
  
  /// Specific feature within the module
  final String feature;
  
  /// Target screen or component to navigate to
  final String targetScreen;
  
  /// Processed parameters for the route
  final Map<String, String> parameters;
  
  /// List of permissions required to access this route
  final List<String> requiredPermissions;
  
  /// Fallback route if navigation fails or permission is denied
  final String fallbackRoute;
  
  /// Whether this route requires user authentication
  final bool requiresAuth;
  
  /// Optional metadata for the route
  final Map<String, dynamic> metadata;

  const RouteInfo({
    required this.routeId,
    required this.module,
    required this.feature,
    required this.targetScreen,
    required this.parameters,
    required this.requiredPermissions,
    required this.fallbackRoute,
    this.requiresAuth = true,
    this.metadata = const {},
  });

  /// Check if the route requires authentication
  bool requiresAuthentication() {
    return requiresAuth || requiredPermissions.isNotEmpty;
  }

  /// Check if the route has a specific parameter
  bool hasParameter(String key) {
    return parameters.containsKey(key);
  }

  /// Get a parameter value with optional default
  String? getParameter(String key, [String? defaultValue]) {
    return parameters[key] ?? defaultValue;
  }

  /// Check if the route requires a specific permission
  bool requiresPermission(String permission) {
    return requiredPermissions.contains(permission);
  }

  /// Create a copy of the route with modified properties
  RouteInfo copyWith({
    String? routeId,
    String? module,
    String? feature,
    String? targetScreen,
    Map<String, String>? parameters,
    List<String>? requiredPermissions,
    String? fallbackRoute,
    bool? requiresAuth,
    Map<String, dynamic>? metadata,
  }) {
    return RouteInfo(
      routeId: routeId ?? this.routeId,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      targetScreen: targetScreen ?? this.targetScreen,
      parameters: parameters ?? this.parameters,
      requiredPermissions: requiredPermissions ?? this.requiredPermissions,
      fallbackRoute: fallbackRoute ?? this.fallbackRoute,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'module': module,
      'feature': feature,
      'targetScreen': targetScreen,
      'parameters': parameters,
      'requiredPermissions': requiredPermissions,
      'fallbackRoute': fallbackRoute,
      'requiresAuth': requiresAuth,
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory RouteInfo.fromJson(Map<String, dynamic> json) {
    return RouteInfo(
      routeId: json['routeId'] as String,
      module: json['module'] as String,
      feature: json['feature'] as String,
      targetScreen: json['targetScreen'] as String,
      parameters: Map<String, String>.from(json['parameters'] as Map),
      requiredPermissions: List<String>.from(json['requiredPermissions'] as List),
      fallbackRoute: json['fallbackRoute'] as String,
      requiresAuth: json['requiresAuth'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'RouteInfo(routeId: $routeId, module: $module, feature: $feature, '
           'targetScreen: $targetScreen, requiresAuth: $requiresAuth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RouteInfo &&
        other.routeId == routeId &&
        other.module == module &&
        other.feature == feature &&
        other.targetScreen == targetScreen &&
        other.fallbackRoute == fallbackRoute &&
        other.requiresAuth == requiresAuth &&
        _listEquals(other.requiredPermissions, requiredPermissions) &&
        _mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    return routeId.hashCode ^
        module.hashCode ^
        feature.hashCode ^
        targetScreen.hashCode ^
        fallbackRoute.hashCode ^
        requiresAuth.hashCode;
  }

  /// Helper method to compare lists for equality
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }

  /// Helper method to compare maps for equality
  bool _mapEquals(Map<String, String> map1, Map<String, String> map2) {
    if (map1.length != map2.length) return false;
    
    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }
    
    return true;
  }
}