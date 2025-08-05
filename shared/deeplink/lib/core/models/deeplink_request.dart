/// Represents a parsed deeplink request with all components
/// Contains scheme, module, feature, and parameters extracted from URL
class DeeplinkRequest {
  /// URL scheme (e.g., "iot")
  final String scheme;
  
  /// Application module (e.g., "iot", "settings")
  final String module;
  
  /// Specific feature within the module (e.g., "device-list", "device-detail")
  final String feature;
  
  /// Key-value parameters from the URL query string
  final Map<String, String> parameters;
  
  /// Original URL string that was parsed
  final String originalUrl;
  
  /// Timestamp when the deeplink was created
  final DateTime timestamp;

  const DeeplinkRequest({
    required this.scheme,
    required this.module,
    required this.feature,
    required this.parameters,
    required this.originalUrl,
    required this.timestamp,
  });

  /// Check if the deeplink request contains all required components
  bool isValid() {
    return scheme.isNotEmpty && 
           module.isNotEmpty && 
           feature.isNotEmpty &&
           originalUrl.isNotEmpty;
  }

  /// Convert the deeplink request back to URL string format
  String toString() {
    final buffer = StringBuffer('$scheme://$module/$feature');
    
    if (parameters.isNotEmpty) {
      buffer.write('?');
      final paramPairs = parameters.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('&');
      buffer.write(paramPairs);
    }
    
    return buffer.toString();
  }

  /// Create a copy of the request with modified parameters
  DeeplinkRequest copyWith({
    String? scheme,
    String? module,
    String? feature,
    Map<String, String>? parameters,
    String? originalUrl,
    DateTime? timestamp,
  }) {
    return DeeplinkRequest(
      scheme: scheme ?? this.scheme,
      module: module ?? this.module,
      feature: feature ?? this.feature,
      parameters: parameters ?? this.parameters,
      originalUrl: originalUrl ?? this.originalUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'scheme': scheme,
      'module': module,
      'feature': feature,
      'parameters': parameters,
      'originalUrl': originalUrl,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON deserialization
  factory DeeplinkRequest.fromJson(Map<String, dynamic> json) {
    return DeeplinkRequest(
      scheme: json['scheme'] as String,
      module: json['module'] as String,
      feature: json['feature'] as String,
      parameters: Map<String, String>.from(json['parameters'] as Map),
      originalUrl: json['originalUrl'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is DeeplinkRequest &&
        other.scheme == scheme &&
        other.module == module &&
        other.feature == feature &&
        other.originalUrl == originalUrl &&
        other.timestamp == timestamp &&
        _mapEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    var hash = scheme.hashCode ^
        module.hashCode ^
        feature.hashCode ^
        originalUrl.hashCode ^
        timestamp.hashCode;
    
    // Include parameters in hash calculation
    for (final entry in parameters.entries) {
      hash ^= entry.key.hashCode ^ entry.value.hashCode;
    }
    
    return hash;
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