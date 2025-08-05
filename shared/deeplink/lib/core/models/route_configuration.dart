/// Configuration model for deeplink routes
/// Represents the structure of route configuration files
class RouteConfiguration {
  /// Map of modules to their route definitions
  final Map<String, ModuleConfiguration> routes;
  
  /// Fallback routes for different scenarios
  final FallbackConfiguration fallbacks;
  
  /// Configuration metadata
  final Map<String, dynamic> metadata;

  const RouteConfiguration({
    required this.routes,
    required this.fallbacks,
    this.metadata = const {},
  });

  /// Get a specific module configuration
  ModuleConfiguration? getModule(String module) {
    return routes[module];
  }

  /// Get a specific route configuration
  RouteDefinition? getRoute(String module, String feature) {
    return routes[module]?.features[feature];
  }

  /// Check if a route exists
  bool hasRoute(String module, String feature) {
    return routes[module]?.features.containsKey(feature) ?? false;
  }

  /// Get all available modules
  List<String> getAvailableModules() {
    return routes.keys.toList();
  }

  /// Get all features for a module
  List<String> getAvailableFeatures(String module) {
    return routes[module]?.features.keys.toList() ?? [];
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'routes': routes.map((key, value) => MapEntry(key, value.toJson())),
      'fallbacks': fallbacks.toJson(),
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory RouteConfiguration.fromJson(Map<String, dynamic> json) {
    final routesJson = json['routes'] as Map<String, dynamic>;
    final routes = routesJson.map(
      (key, value) => MapEntry(
        key,
        ModuleConfiguration.fromJson(value as Map<String, dynamic>),
      ),
    );

    return RouteConfiguration(
      routes: routes,
      fallbacks: FallbackConfiguration.fromJson(
        json['fallbacks'] as Map<String, dynamic>,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'RouteConfiguration(modules: ${routes.keys.toList()})';
  }
}

/// Configuration for a specific module
class ModuleConfiguration {
  /// Map of feature names to their route definitions
  final Map<String, RouteDefinition> features;
  
  /// Module-level metadata
  final Map<String, dynamic> metadata;

  const ModuleConfiguration({
    required this.features,
    this.metadata = const {},
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'features': features.map((key, value) => MapEntry(key, value.toJson())),
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory ModuleConfiguration.fromJson(Map<String, dynamic> json) {
    final featuresJson = json['features'] as Map<String, dynamic>? ?? json;
    final features = featuresJson.map(
      (key, value) => MapEntry(
        key,
        RouteDefinition.fromJson(value as Map<String, dynamic>),
      ),
    );

    return ModuleConfiguration(
      features: features,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Definition for a specific route
class RouteDefinition {
  /// Target screen or component to navigate to
  final String screen;
  
  /// List of permissions required to access this route
  final List<String> permissions;
  
  /// Parameter definitions for this route
  final Map<String, ParameterDefinition> parameters;
  
  /// Fallback route if navigation fails
  final String? fallbackRoute;
  
  /// Whether this route requires authentication
  final bool requiresAuth;
  
  /// Route-specific metadata
  final Map<String, dynamic> metadata;

  const RouteDefinition({
    required this.screen,
    this.permissions = const [],
    this.parameters = const {},
    this.fallbackRoute,
    this.requiresAuth = true,
    this.metadata = const {},
  });

  /// Check if a parameter is required
  bool isParameterRequired(String paramName) {
    return parameters[paramName]?.required ?? false;
  }

  /// Get all required parameters
  List<String> getRequiredParameters() {
    return parameters.entries
        .where((entry) => entry.value.required)
        .map((entry) => entry.key)
        .toList();
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'screen': screen,
      'permissions': permissions,
      'parameters': parameters.map((key, value) => MapEntry(key, value.toJson())),
      'fallbackRoute': fallbackRoute,
      'requiresAuth': requiresAuth,
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory RouteDefinition.fromJson(Map<String, dynamic> json) {
    final parametersJson = json['parameters'] as Map<String, dynamic>? ?? {};
    final parameters = parametersJson.map(
      (key, value) => MapEntry(
        key,
        value is String
            ? ParameterDefinition(required: value == 'required')
            : ParameterDefinition.fromJson(value as Map<String, dynamic>),
      ),
    );

    return RouteDefinition(
      screen: json['screen'] as String,
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      parameters: parameters,
      fallbackRoute: json['fallbackRoute'] as String?,
      requiresAuth: json['requiresAuth'] as bool? ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Definition for a route parameter
class ParameterDefinition {
  /// Whether this parameter is required
  final bool required;
  
  /// Parameter type (string, int, bool, etc.)
  final String type;
  
  /// Default value if parameter is not provided
  final String? defaultValue;
  
  /// Validation pattern for the parameter
  final String? pattern;
  
  /// Description of the parameter
  final String? description;

  const ParameterDefinition({
    this.required = false,
    this.type = 'string',
    this.defaultValue,
    this.pattern,
    this.description,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'required': required,
      'type': type,
      'defaultValue': defaultValue,
      'pattern': pattern,
      'description': description,
    };
  }

  /// Create from JSON deserialization
  factory ParameterDefinition.fromJson(Map<String, dynamic> json) {
    return ParameterDefinition(
      required: json['required'] as bool? ?? false,
      type: json['type'] as String? ?? 'string',
      defaultValue: json['defaultValue'] as String?,
      pattern: json['pattern'] as String?,
      description: json['description'] as String?,
    );
  }
}

/// Configuration for fallback routes
class FallbackConfiguration {
  /// Default route when no specific route is matched
  final String defaultRoute;
  
  /// Route to use when permission is denied
  final String permissionDeniedRoute;
  
  /// Route to use when a route is not found
  final String notFoundRoute;
  
  /// Route to use when an error occurs
  final String errorRoute;

  const FallbackConfiguration({
    required this.defaultRoute,
    required this.permissionDeniedRoute,
    required this.notFoundRoute,
    required this.errorRoute,
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'default': defaultRoute,
      'permission_denied': permissionDeniedRoute,
      'not_found': notFoundRoute,
      'error': errorRoute,
    };
  }

  /// Create from JSON deserialization
  factory FallbackConfiguration.fromJson(Map<String, dynamic> json) {
    return FallbackConfiguration(
      defaultRoute: json['default'] as String,
      permissionDeniedRoute: json['permission_denied'] as String,
      notFoundRoute: json['not_found'] as String,
      errorRoute: json['error'] as String,
    );
  }
}