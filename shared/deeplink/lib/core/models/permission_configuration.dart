/// Configuration model for deeplink permissions
/// Represents the structure of permission configuration files
class PermissionConfiguration {
  /// Map of permission names to their definitions
  final Map<String, PermissionDefinition> permissions;
  
  /// Map of role names to their definitions
  final Map<String, RoleDefinition> roles;
  
  /// Configuration metadata
  final Map<String, dynamic> metadata;

  const PermissionConfiguration({
    required this.permissions,
    required this.roles,
    this.metadata = const {},
  });

  /// Get a specific permission definition
  PermissionDefinition? getPermission(String permission) {
    return permissions[permission];
  }

  /// Get a specific role definition
  RoleDefinition? getRole(String role) {
    return roles[role];
  }

  /// Check if a permission exists
  bool hasPermission(String permission) {
    return permissions.containsKey(permission);
  }

  /// Check if a role exists
  bool hasRole(String role) {
    return roles.containsKey(role);
  }

  /// Get all permissions for a specific role
  List<String> getPermissionsForRole(String role) {
    final roleDefinition = roles[role];
    if (roleDefinition == null) return [];
    
    final directPermissions = roleDefinition.permissions;
    final expandedPermissions = <String>[];
    
    for (final permission in directPermissions) {
      if (permission.endsWith('*')) {
        // Wildcard permission - expand to all matching permissions
        final prefix = permission.substring(0, permission.length - 1);
        expandedPermissions.addAll(
          permissions.keys.where((p) => p.startsWith(prefix)),
        );
      } else if (permission == '*') {
        // Global wildcard - all permissions
        expandedPermissions.addAll(permissions.keys);
      } else {
        // Direct permission
        expandedPermissions.add(permission);
      }
    }
    
    return expandedPermissions.toSet().toList();
  }

  /// Check if a role has a specific permission
  bool roleHasPermission(String role, String permission) {
    return getPermissionsForRole(role).contains(permission);
  }

  /// Get all available permissions
  List<String> getAvailablePermissions() {
    return permissions.keys.toList();
  }

  /// Get all available roles
  List<String> getAvailableRoles() {
    return roles.keys.toList();
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'permissions': permissions.map((key, value) => MapEntry(key, value.toJson())),
      'roles': roles.map((key, value) => MapEntry(key, value.toJson())),
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory PermissionConfiguration.fromJson(Map<String, dynamic> json) {
    final permissionsJson = json['permissions'] as Map<String, dynamic>? ?? {};
    final permissions = permissionsJson.map(
      (key, value) => MapEntry(
        key,
        PermissionDefinition.fromJson(value as Map<String, dynamic>),
      ),
    );

    final rolesJson = json['roles'] as Map<String, dynamic>? ?? {};
    final roles = rolesJson.map(
      (key, value) => MapEntry(
        key,
        RoleDefinition.fromJson(value as Map<String, dynamic>),
      ),
    );

    return PermissionConfiguration(
      permissions: permissions,
      roles: roles,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'PermissionConfiguration(permissions: ${permissions.keys.length}, roles: ${roles.keys.length})';
  }
}

/// Definition for a specific permission
class PermissionDefinition {
  /// Human-readable description of the permission
  final String description;
  
  /// List of roles that have this permission by default
  final List<String> roles;
  
  /// Permission category or group
  final String? category;
  
  /// Whether this is a system-level permission
  final bool isSystem;
  
  /// Permission-specific metadata
  final Map<String, dynamic> metadata;

  const PermissionDefinition({
    required this.description,
    this.roles = const [],
    this.category,
    this.isSystem = false,
    this.metadata = const {},
  });

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'roles': roles,
      'category': category,
      'isSystem': isSystem,
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory PermissionDefinition.fromJson(Map<String, dynamic> json) {
    return PermissionDefinition(
      description: json['description'] as String,
      roles: List<String>.from(json['roles'] as List? ?? []),
      category: json['category'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}

/// Definition for a specific role
class RoleDefinition {
  /// List of permissions granted to this role
  final List<String> permissions;
  
  /// Human-readable description of the role
  final String? description;
  
  /// Parent roles that this role inherits from
  final List<String> inherits;
  
  /// Whether this is a system-level role
  final bool isSystem;
  
  /// Role-specific metadata
  final Map<String, dynamic> metadata;

  const RoleDefinition({
    required this.permissions,
    this.description,
    this.inherits = const [],
    this.isSystem = false,
    this.metadata = const {},
  });

  /// Get all permissions including inherited ones
  List<String> getAllPermissions(PermissionConfiguration config) {
    final allPermissions = <String>[];
    
    // Add direct permissions
    allPermissions.addAll(permissions);
    
    // Add inherited permissions
    for (final parentRole in inherits) {
      final parentRoleDefinition = config.getRole(parentRole);
      if (parentRoleDefinition != null) {
        allPermissions.addAll(parentRoleDefinition.getAllPermissions(config));
      }
    }
    
    return allPermissions.toSet().toList();
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'permissions': permissions,
      'description': description,
      'inherits': inherits,
      'isSystem': isSystem,
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory RoleDefinition.fromJson(Map<String, dynamic> json) {
    return RoleDefinition(
      permissions: List<String>.from(json['permissions'] as List? ?? []),
      description: json['description'] as String?,
      inherits: List<String>.from(json['inherits'] as List? ?? []),
      isSystem: json['isSystem'] as bool? ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }
}