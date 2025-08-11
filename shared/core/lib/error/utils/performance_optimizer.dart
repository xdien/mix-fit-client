import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/app_error.dart';

/// Performance optimization utilities for the error system
class ErrorSystemPerformanceOptimizer {
  static const int _defaultMaxCacheSize = 100;
  static const Duration _defaultCacheExpiry = Duration(minutes: 30);
  static const Duration _defaultDebounceDelay = Duration(milliseconds: 300);

  final int _maxCacheSize;
  final Duration _cacheExpiry;
  final Duration _debounceDelay;

  final Queue<AppError> _errorCache = Queue<AppError>();
  final Map<String, DateTime> _errorTimestamps = <String, DateTime>{};
  final Map<String, Timer> _debounceTimers = <String, Timer>{};
  final Set<String> _duplicateErrorIds = <String>{};

  ErrorSystemPerformanceOptimizer({
    int maxCacheSize = _defaultMaxCacheSize,
    Duration cacheExpiry = _defaultCacheExpiry,
    Duration debounceDelay = _defaultDebounceDelay,
  }) : _maxCacheSize = maxCacheSize,
       _cacheExpiry = cacheExpiry,
       _debounceDelay = debounceDelay;

  /// Optimizes error queue by removing duplicates and expired errors
  List<AppError> optimizeErrorQueue(List<AppError> errors) {
    final optimized = <AppError>[];
    final seen = <String>{};
    final now = DateTime.now();

    for (final error in errors) {
      // Skip duplicates
      if (seen.contains(error.id)) {
        continue;
      }

      // Skip expired errors (if they have timestamps)
      final timestamp = _errorTimestamps[error.id];
      if (timestamp != null && now.difference(timestamp) > _cacheExpiry) {
        _errorTimestamps.remove(error.id);
        continue;
      }

      seen.add(error.id);
      optimized.add(error);
    }

    return optimized;
  }

  /// Debounces error additions to prevent spam
  Future<bool> shouldAddError(AppError error) async {
    final errorKey = _getErrorKey(error);
    
    // Check if this error is already being debounced
    if (_debounceTimers.containsKey(errorKey)) {
      return false;
    }

    // Check for duplicate errors
    if (_isDuplicateError(error)) {
      return false;
    }

    // Start debounce timer
    _debounceTimers[errorKey] = Timer(_debounceDelay, () {
      _debounceTimers.remove(errorKey);
    });

    _recordError(error);
    return true;
  }

  /// Manages error cache size to prevent memory leaks
  void manageErrorCache(List<AppError> currentErrors) {
    // Add new errors to cache
    for (final error in currentErrors) {
      if (!_errorCache.any((e) => e.id == error.id)) {
        _errorCache.add(error);
        _errorTimestamps[error.id] = DateTime.now();
      }
    }

    // Remove excess errors from cache
    while (_errorCache.length > _maxCacheSize) {
      final removed = _errorCache.removeFirst();
      _errorTimestamps.remove(removed.id);
      _duplicateErrorIds.remove(removed.id);
    }

    // Clean up expired errors
    _cleanupExpiredErrors();
  }

  /// Batches error operations for better performance
  Future<void> batchErrorOperations(
    List<Future<void> Function()> operations,
  ) async {
    const batchSize = 10;
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      await Future.wait(batch.map((op) => op()));
      
      // Allow UI to update between batches
      await Future.delayed(const Duration(microseconds: 1));
    }
  }

  /// Optimizes error message formatting for performance
  String optimizeErrorMessage(String message, {int maxLength = 200}) {
    if (message.length <= maxLength) {
      return message;
    }

    // Truncate and add ellipsis
    return '${message.substring(0, maxLength - 3)}...';
  }

  /// Creates efficient error grouping for similar errors
  Map<String, List<AppError>> groupSimilarErrors(List<AppError> errors) {
    final groups = <String, List<AppError>>{};

    for (final error in errors) {
      final groupKey = _getErrorGroupKey(error);
      groups.putIfAbsent(groupKey, () => <AppError>[]).add(error);
    }

    return groups;
  }

  /// Calculates memory usage of error objects
  int calculateErrorMemoryUsage(List<AppError> errors) {
    int totalSize = 0;

    for (final error in errors) {
      totalSize += _calculateSingleErrorSize(error);
    }

    return totalSize;
  }

  /// Provides performance metrics for the error system
  ErrorSystemMetrics getPerformanceMetrics() {
    return ErrorSystemMetrics(
      cacheSize: _errorCache.length,
      maxCacheSize: _maxCacheSize,
      duplicateErrorCount: _duplicateErrorIds.length,
      activeDebounceTimers: _debounceTimers.length,
      memoryUsageBytes: calculateErrorMemoryUsage(_errorCache.toList()),
      cacheHitRatio: _calculateCacheHitRatio(),
    );
  }

  /// Clears all cached data and timers
  void dispose() {
    _errorCache.clear();
    _errorTimestamps.clear();
    _duplicateErrorIds.clear();
    
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }

  // Private helper methods

  String _getErrorKey(AppError error) {
    return '${error.type}_${error.message.hashCode}';
  }

  String _getErrorGroupKey(AppError error) {
    // Group by error type and first 50 characters of message
    final messagePrefix = error.message.length > 50 
        ? error.message.substring(0, 50)
        : error.message;
    return '${error.type}_$messagePrefix';
  }

  bool _isDuplicateError(AppError error) {
    final errorKey = _getErrorKey(error);
    
    // Check if we've seen this exact error recently
    if (_duplicateErrorIds.contains(errorKey)) {
      return true;
    }

    // Check for similar errors in cache
    return _errorCache.any((cachedError) => 
        _getErrorKey(cachedError) == errorKey);
  }

  void _recordError(AppError error) {
    final errorKey = _getErrorKey(error);
    _duplicateErrorIds.add(errorKey);
    _errorTimestamps[error.id] = DateTime.now();
  }

  void _cleanupExpiredErrors() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    _errorTimestamps.forEach((id, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredIds.add(id);
      }
    });

    for (final id in expiredIds) {
      _errorTimestamps.remove(id);
      _duplicateErrorIds.remove(id);
      _errorCache.removeWhere((error) => error.id == id);
    }
  }

  int _calculateSingleErrorSize(AppError error) {
    // Rough estimation of memory usage
    int size = 0;
    
    size += error.id.length * 2; // UTF-16 encoding
    size += error.message.length * 2;
    size += 8; // timestamp
    size += 4; // severity enum
    size += 4; // type enum
    
    // Add metadata size if present
    if (error.metadata != null) {
      size += error.metadata.toString().length * 2;
    }

    // Add type-specific sizes
    if (error is ApiError) {
      size += (error.endpoint?.length ?? 0) * 2;
      size += (error.method?.length ?? 0) * 2;
      size += 4; // status code
    } else if (error is ValidationError) {
      error.fieldErrors.forEach((key, values) {
        size += key.length * 2;
        size += values.join().length * 2;
      });
    } else if (error is NetworkError) {
      size += (error.url?.length ?? 0) * 2;
      size += 8; // timeout duration
    } else if (error is ClientError) {
      size += (error.stackTrace?.length ?? 0) * 2;
      size += (error.componentName?.length ?? 0) * 2;
    }

    return size;
  }

  double _calculateCacheHitRatio() {
    if (_errorCache.isEmpty) return 0.0;
    
    final totalRequests = _errorCache.length + _duplicateErrorIds.length;
    if (totalRequests == 0) return 0.0;
    
    return _duplicateErrorIds.length / totalRequests;
  }
}

/// Performance metrics for the error system
class ErrorSystemMetrics {
  final int cacheSize;
  final int maxCacheSize;
  final int duplicateErrorCount;
  final int activeDebounceTimers;
  final int memoryUsageBytes;
  final double cacheHitRatio;

  const ErrorSystemMetrics({
    required this.cacheSize,
    required this.maxCacheSize,
    required this.duplicateErrorCount,
    required this.activeDebounceTimers,
    required this.memoryUsageBytes,
    required this.cacheHitRatio,
  });

  /// Gets memory usage in a human-readable format
  String get formattedMemoryUsage {
    if (memoryUsageBytes < 1024) {
      return '${memoryUsageBytes}B';
    } else if (memoryUsageBytes < 1024 * 1024) {
      return '${(memoryUsageBytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(memoryUsageBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// Gets cache utilization percentage
  double get cacheUtilization {
    return maxCacheSize > 0 ? (cacheSize / maxCacheSize) : 0.0;
  }

  /// Checks if the system is performing optimally
  bool get isPerformingOptimally {
    return cacheUtilization < 0.8 && // Cache not too full
           cacheHitRatio > 0.1 && // Some duplicate detection
           activeDebounceTimers < 10; // Not too many pending operations
  }

  @override
  String toString() {
    return 'ErrorSystemMetrics('
           'cacheSize: $cacheSize/$maxCacheSize, '
           'duplicates: $duplicateErrorCount, '
           'memory: $formattedMemoryUsage, '
           'hitRatio: ${(cacheHitRatio * 100).toStringAsFixed(1)}%)';
  }
}

/// Memory leak detector for error system
class ErrorSystemMemoryLeakDetector {
  static const Duration _checkInterval = Duration(minutes: 5);
  static const int _memoryThresholdMB = 10;

  Timer? _checkTimer;
  final List<int> _memorySnapshots = [];
  final ErrorSystemPerformanceOptimizer _optimizer;

  ErrorSystemMemoryLeakDetector(this._optimizer);

  /// Starts monitoring for memory leaks
  void startMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _checkMemoryUsage());
  }

  /// Stops monitoring
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Checks current memory usage and detects potential leaks
  void _checkMemoryUsage() {
    final metrics = _optimizer.getPerformanceMetrics();
    final currentMemoryMB = metrics.memoryUsageBytes ~/ (1024 * 1024);
    
    _memorySnapshots.add(currentMemoryMB);
    
    // Keep only last 10 snapshots
    if (_memorySnapshots.length > 10) {
      _memorySnapshots.removeAt(0);
    }

    // Check for memory leak patterns
    if (_memorySnapshots.length >= 5) {
      final isIncreasing = _isMemoryIncreasing();
      final isAboveThreshold = currentMemoryMB > _memoryThresholdMB;

      if (isIncreasing && isAboveThreshold) {
        _reportPotentialMemoryLeak(currentMemoryMB);
      }
    }
  }

  bool _isMemoryIncreasing() {
    if (_memorySnapshots.length < 3) return false;

    final recent = _memorySnapshots.skip(_memorySnapshots.length - 3).toList();
    return recent[0] < recent[1] && recent[1] < recent[2];
  }

  void _reportPotentialMemoryLeak(int currentMemoryMB) {
    if (kDebugMode) {
      debugPrint('⚠️ Potential memory leak detected in error system: ${currentMemoryMB}MB');
      debugPrint('Memory snapshots: $_memorySnapshots');
      debugPrint('Consider calling dispose() on unused error components');
    }
  }

  void dispose() {
    stopMonitoring();
    _memorySnapshots.clear();
  }
}