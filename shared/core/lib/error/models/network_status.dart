/// Defines the quality levels of network connectivity
enum NetworkQuality {
  /// Excellent network quality (fast, reliable)
  excellent,
  
  /// Good network quality (reliable, moderate speed)
  good,
  
  /// Fair network quality (some delays, occasional issues)
  fair,
  
  /// Poor network quality (slow, frequent issues)
  poor,
  
  /// No network connectivity
  offline;

  /// Returns whether this quality level is considered online
  bool get isOnline => this != NetworkQuality.offline;

  /// Returns whether this quality level is considered good enough for normal operations
  bool get isGoodEnough => 
      this == NetworkQuality.excellent || 
      this == NetworkQuality.good;

  /// Returns the priority value for this quality level (higher is better)
  int get priority {
    switch (this) {
      case NetworkQuality.excellent:
        return 5;
      case NetworkQuality.good:
        return 4;
      case NetworkQuality.fair:
        return 3;
      case NetworkQuality.poor:
        return 2;
      case NetworkQuality.offline:
        return 1;
    }
  }
}

/// Represents the current network connectivity status
class NetworkStatus {
  /// Whether the device is connected to the internet
  final bool isConnected;
  
  /// Quality of the network connection
  final NetworkQuality quality;
  
  /// Network latency if available
  final Duration? latency;
  
  /// Timestamp when the status was last checked
  final DateTime lastChecked;

  NetworkStatus({
    required this.isConnected,
    required this.quality,
    this.latency,
    DateTime? lastChecked,
  }) : lastChecked = lastChecked ?? DateTime.now();

  /// Creates a NetworkStatus representing an offline state
  factory NetworkStatus.offline() {
    return NetworkStatus(
      isConnected: false,
      quality: NetworkQuality.offline,
      lastChecked: DateTime.now(),
    );
  }

  /// Creates a NetworkStatus representing an online state with good quality
  factory NetworkStatus.online({
    NetworkQuality quality = NetworkQuality.good,
    Duration? latency,
  }) {
    return NetworkStatus(
      isConnected: true,
      quality: quality,
      latency: latency,
      lastChecked: DateTime.now(),
    );
  }

  /// Returns whether the network quality is good enough for normal operations
  bool get isGoodEnough => quality.isGoodEnough;

  /// Returns whether this status indicates the device is offline
  bool get isOffline => !isConnected || quality == NetworkQuality.offline;

  /// Returns a copy of this status with updated properties
  NetworkStatus copyWith({
    bool? isConnected,
    NetworkQuality? quality,
    Duration? latency,
    DateTime? lastChecked,
  }) {
    return NetworkStatus(
      isConnected: isConnected ?? this.isConnected,
      quality: quality ?? this.quality,
      latency: latency ?? this.latency,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  /// Converts the status to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'quality': quality.name,
      'latency': latency?.inMilliseconds,
      'lastChecked': lastChecked.toIso8601String(),
      'isGoodEnough': isGoodEnough,
      'isOffline': isOffline,
    };
  }

  /// Creates a NetworkStatus from a map
  static NetworkStatus fromMap(Map<String, dynamic> map) {
    final qualityName = map['quality'] as String;
    final quality = NetworkQuality.values.firstWhere(
      (q) => q.name == qualityName,
      orElse: () => NetworkQuality.offline,
    );

    final latencyMs = map['latency'] as int?;
    final latency = latencyMs != null ? Duration(milliseconds: latencyMs) : null;

    return NetworkStatus(
      isConnected: map['isConnected'] ?? false,
      quality: quality,
      latency: latency,
      lastChecked: DateTime.parse(map['lastChecked']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkStatus &&
          runtimeType == other.runtimeType &&
          isConnected == other.isConnected &&
          quality == other.quality &&
          latency == other.latency;

  @override
  int get hashCode =>
      isConnected.hashCode ^
      quality.hashCode ^
      latency.hashCode;

  @override
  String toString() {
    return 'NetworkStatus{isConnected: $isConnected, quality: $quality, latency: $latency, lastChecked: $lastChecked}';
  }
}