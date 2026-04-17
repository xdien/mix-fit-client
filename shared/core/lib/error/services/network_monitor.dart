import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../models/network_status.dart';

/// Service for monitoring network connectivity and quality
class NetworkMonitor {
  static const Duration _defaultCheckInterval = Duration(seconds: 30);
  static const Duration _qualityCheckTimeout = Duration(seconds: 5);
  static const List<String> _testHosts = [
    'google.com',
    'cloudflare.com',
    '8.8.8.8',
  ];

  final StreamController<bool> _connectivityController = 
      StreamController<bool>.broadcast();
  final StreamController<NetworkQuality> _qualityController = 
      StreamController<NetworkQuality>.broadcast();
  final StreamController<NetworkStatus> _statusController = 
      StreamController<NetworkStatus>.broadcast();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;
  bool _disposed = false;
  
  NetworkStatus _currentStatus = NetworkStatus.offline();

  /// Stream of connectivity changes (true = connected, false = disconnected)
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Stream of network quality changes
  Stream<NetworkQuality> get qualityStream => _qualityController.stream;

  /// Stream of complete network status updates
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Whether the device is currently connected
  bool get isConnected => _currentStatus.isConnected;

  /// Current network quality
  NetworkQuality get currentQuality => _currentStatus.quality;

  /// Starts continuous network monitoring
  void startMonitoring({Duration interval = _defaultCheckInterval}) {
    if (_disposed || _isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(interval, (_) => _checkNetworkStatus());
    
    // Perform initial check
    _checkNetworkStatus();
  }

  /// Stops network monitoring
  void stopMonitoring() {
    if (_disposed) return;

    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Performs a one-time connectivity check
  Future<bool> checkConnectivity() async {
    if (_disposed) return false;

    try {
      // Try to resolve a reliable host
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Measures network quality by testing latency and reliability
  Future<NetworkQuality> measureQuality() async {
    if (_disposed) return NetworkQuality.offline;

    final isConnected = await checkConnectivity();
    if (!isConnected) {
      return NetworkQuality.offline;
    }

    try {
      final latencies = <Duration>[];
      int successfulTests = 0;

      // Test multiple hosts for reliability
      for (final host in _testHosts) {
        try {
          final stopwatch = Stopwatch()..start();
          final result = await InternetAddress.lookup(host)
              .timeout(_qualityCheckTimeout);
          stopwatch.stop();

          if (result.isNotEmpty) {
            latencies.add(stopwatch.elapsed);
            successfulTests++;
          }
        } catch (e) {
          // Host test failed, continue with others
        }
      }

      if (successfulTests == 0) {
        return NetworkQuality.offline;
      }

      // Calculate average latency
      final totalLatency = latencies.fold<Duration>(
        Duration.zero,
        (sum, latency) => sum + latency,
      );
      final averageLatency = Duration(
        microseconds: totalLatency.inMicroseconds ~/ latencies.length,
      );

      // Calculate reliability percentage
      final reliability = successfulTests / _testHosts.length;

      return _calculateQualityFromMetrics(averageLatency, reliability);
    } catch (e) {
      return NetworkQuality.poor;
    }
  }

  /// Performs a comprehensive network status check
  Future<NetworkStatus> checkNetworkStatus() async {
    if (_disposed) return NetworkStatus.offline();

    final isConnected = await checkConnectivity();
    if (!isConnected) {
      return NetworkStatus.offline();
    }

    final quality = await measureQuality();
    final latency = await _measureLatency();

    return NetworkStatus(
      isConnected: isConnected,
      quality: quality,
      latency: latency,
    );
  }

  /// Disposes of the network monitor and cleans up resources
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    stopMonitoring();
    
    _connectivityController.close();
    _qualityController.close();
    _statusController.close();
  }

  /// Performs network status check and notifies listeners
  Future<void> _checkNetworkStatus() async {
    if (_disposed) return;

    try {
      final newStatus = await checkNetworkStatus();
      final previousStatus = _currentStatus;
      
      _currentStatus = newStatus;

      // Only notify if not disposed and streams are not closed
      if (!_disposed) {
        // Notify listeners of changes
        if (previousStatus.isConnected != newStatus.isConnected) {
          if (!_connectivityController.isClosed) {
            _connectivityController.add(newStatus.isConnected);
          }
        }

        if (previousStatus.quality != newStatus.quality) {
          if (!_qualityController.isClosed) {
            _qualityController.add(newStatus.quality);
          }
        }

        if (!_statusController.isClosed) {
          _statusController.add(newStatus);
        }
      }
    } catch (e) {
      // Handle monitoring errors gracefully
      if (_disposed) return;
      
      final offlineStatus = NetworkStatus.offline();
      if (_currentStatus.isConnected) {
        _currentStatus = offlineStatus;
        
        if (!_disposed) {
          if (!_connectivityController.isClosed) {
            _connectivityController.add(false);
          }
          if (!_qualityController.isClosed) {
            _qualityController.add(NetworkQuality.offline);
          }
          if (!_statusController.isClosed) {
            _statusController.add(offlineStatus);
          }
        }
      }
    }
  }

  /// Measures network latency to a reliable host
  Future<Duration?> _measureLatency() async {
    try {
      final stopwatch = Stopwatch()..start();
      await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));
      stopwatch.stop();
      
      return stopwatch.elapsed;
    } catch (e) {
      return null;
    }
  }

  /// Calculates network quality based on latency and reliability metrics
  NetworkQuality _calculateQualityFromMetrics(Duration latency, double reliability) {
    final latencyMs = latency.inMilliseconds;

    // If reliability is very low, quality is poor regardless of latency
    if (reliability < 0.5) {
      return NetworkQuality.poor;
    }

    // Determine quality based on latency and reliability
    if (latencyMs <= 50 && reliability >= 0.9) {
      return NetworkQuality.excellent;
    } else if (latencyMs <= 150 && reliability >= 0.8) {
      return NetworkQuality.good;
    } else if (latencyMs <= 300 && reliability >= 0.6) {
      return NetworkQuality.fair;
    } else {
      return NetworkQuality.poor;
    }
  }
}

/// Extension methods for NetworkMonitor to provide additional utilities
extension NetworkMonitorUtils on NetworkMonitor {
  /// Returns whether the current connection is good enough for normal operations
  bool get isConnectionGoodEnough => currentQuality.isGoodEnough;

  /// Returns whether the device is currently offline
  bool get isOffline => currentStatus.isOffline;

  /// Returns a human-readable description of the current network status
  String get statusDescription {
    if (!isConnected) {
      return 'No internet connection';
    }

    switch (currentQuality) {
      case NetworkQuality.excellent:
        return 'Excellent connection';
      case NetworkQuality.good:
        return 'Good connection';
      case NetworkQuality.fair:
        return 'Fair connection';
      case NetworkQuality.poor:
        return 'Poor connection';
      case NetworkQuality.offline:
        return 'No internet connection';
    }
  }

  /// Returns an appropriate icon name for the current network status
  String get statusIcon {
    if (!isConnected) {
      return 'wifi_off';
    }

    switch (currentQuality) {
      case NetworkQuality.excellent:
        return 'wifi';
      case NetworkQuality.good:
        return 'wifi';
      case NetworkQuality.fair:
        return 'wifi_1_bar';
      case NetworkQuality.poor:
        return 'wifi_1_bar';
      case NetworkQuality.offline:
        return 'wifi_off';
    }
  }
}