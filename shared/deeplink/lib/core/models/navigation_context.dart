/// Provides context information for navigation operations
/// Contains application state and navigation stack information
class NavigationContext {
  /// Current user identifier
  final String? userId;
  
  /// Current application state
  final Map<String, dynamic> applicationState;
  
  /// Navigation stack history
  final List<String> navigationHistory;
  
  /// Current screen identifier
  final String? currentScreen;
  
  /// Whether the application is in authenticated state
  final bool isAuthenticated;
  
  /// User roles and permissions
  final List<String> userRoles;
  
  /// Additional context metadata
  final Map<String, dynamic> metadata;

  const NavigationContext({
    this.userId,
    this.applicationState = const {},
    this.navigationHistory = const [],
    this.currentScreen,
    this.isAuthenticated = false,
    this.userRoles = const [],
    this.metadata = const {},
  });

  /// Check if the user has a specific role
  bool hasRole(String role) {
    return userRoles.contains(role);
  }

  /// Check if the user has any of the specified roles
  bool hasAnyRole(List<String> roles) {
    return roles.any((role) => userRoles.contains(role));
  }

  /// Get the previous screen from navigation history
  String? get previousScreen {
    if (navigationHistory.length > 1) {
      return navigationHistory[navigationHistory.length - 2];
    }
    return null;
  }

  /// Check if we can navigate back
  bool get canNavigateBack {
    return navigationHistory.length > 1;
  }

  /// Create a copy with updated navigation history
  NavigationContext withNavigationTo(String screen) {
    final newHistory = List<String>.from(navigationHistory);
    newHistory.add(screen);
    
    return copyWith(
      navigationHistory: newHistory,
      currentScreen: screen,
    );
  }

  /// Create a copy with navigation back
  NavigationContext withNavigationBack() {
    if (!canNavigateBack) return this;
    
    final newHistory = List<String>.from(navigationHistory);
    newHistory.removeLast();
    
    return copyWith(
      navigationHistory: newHistory,
      currentScreen: newHistory.isNotEmpty ? newHistory.last : null,
    );
  }

  /// Create a copy of the context with modified properties
  NavigationContext copyWith({
    String? userId,
    Map<String, dynamic>? applicationState,
    List<String>? navigationHistory,
    String? currentScreen,
    bool? isAuthenticated,
    List<String>? userRoles,
    Map<String, dynamic>? metadata,
  }) {
    return NavigationContext(
      userId: userId ?? this.userId,
      applicationState: applicationState ?? this.applicationState,
      navigationHistory: navigationHistory ?? this.navigationHistory,
      currentScreen: currentScreen ?? this.currentScreen,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userRoles: userRoles ?? this.userRoles,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'applicationState': applicationState,
      'navigationHistory': navigationHistory,
      'currentScreen': currentScreen,
      'isAuthenticated': isAuthenticated,
      'userRoles': userRoles,
      'metadata': metadata,
    };
  }

  /// Create from JSON deserialization
  factory NavigationContext.fromJson(Map<String, dynamic> json) {
    return NavigationContext(
      userId: json['userId'] as String?,
      applicationState: Map<String, dynamic>.from(json['applicationState'] as Map? ?? {}),
      navigationHistory: List<String>.from(json['navigationHistory'] as List? ?? []),
      currentScreen: json['currentScreen'] as String?,
      isAuthenticated: json['isAuthenticated'] as bool? ?? false,
      userRoles: List<String>.from(json['userRoles'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  String toString() {
    return 'NavigationContext(userId: $userId, currentScreen: $currentScreen, '
           'isAuthenticated: $isAuthenticated, historyLength: ${navigationHistory.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is NavigationContext &&
        other.userId == userId &&
        other.currentScreen == currentScreen &&
        other.isAuthenticated == isAuthenticated &&
        _listEquals(other.navigationHistory, navigationHistory) &&
        _listEquals(other.userRoles, userRoles);
  }

  @override
  int get hashCode {
    return userId.hashCode ^
        currentScreen.hashCode ^
        isAuthenticated.hashCode ^
        navigationHistory.hashCode ^
        userRoles.hashCode;
  }

  /// Helper method to compare lists for equality
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    
    return true;
  }
}