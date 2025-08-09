import 'dart:async';
import 'dart:collection';

import '../models/api_error.dart';
import '../models/app_error.dart';
import '../models/client_error.dart';
import '../models/error_severity.dart';
import '../models/network_error.dart';
import '../models/network_status.dart';
import '../models/validation_error.dart';
import 'error_service_interface.dart';
import 'network_monitor.dart';

/// Concrete implementation of the error service that manages application errors
class ErrorService implements IErrorService {
  static const int _maxQueueSize = 5;
  static const Duration _criticalErrorPersistenceDuration = Duration(days: 7);

  final StreamController<List<AppError>> _errorStreamController = 
      StreamController<List<AppError>>.broadcast();
  final StreamController<AppError?> _currentErrorStreamController = 
      StreamController<AppError?>.broadcast();

  final Queue<AppError> _errorQueue = Queue<AppError>();
  final Map<String, Timer> _autoDismissTimers = <String, Timer>{};
  final Set<String> _errorSignatures = <String>{};

  final NetworkMonitor _networkMonitor;
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;

  bool _disposed = false;

  /// Creates an ErrorService with optional network monitoring
  ErrorService({NetworkMonitor? networkMonitor}) 
      : _networkMonitor = networkMonitor ?? NetworkMonitor() {
    _initializeNetworkMonitoring();
  }

  @override
  void showError(AppError error) {
    if (_disposed) return;

    // Check for similar errors that can be consolidated first
    final consolidatedError = _consolidateSimilarErrors(error);
    if (consolidatedError != null) {
      // Replace the existing similar error with the consolidated one
      _replaceErrorInQueue(consolidatedError.existingError, consolidatedError.consolidatedError);
      _persistCriticalError(consolidatedError.consolidatedError);
      _notifyListeners();
      return;
    }

    // Check for exact duplicate errors
    final signature = _generateErrorSignature(error);
    if (_errorSignatures.contains(signature)) {
      return; // Skip duplicate error
    }

    _errorSignatures.add(signature);
    _addErrorToQueue(error);
    _scheduleAutoDismiss(error);
    _persistCriticalError(error);
    _notifyListeners();
  }

  @override
  void showApiError(ApiError error) {
    showError(error);
  }

  @override
  void showValidationError(ValidationError error) {
    showError(error);
  }

  @override
  void showNetworkError(NetworkError error) {
    showError(error);
  }

  @override
  void showClientError(ClientError error) {
    showError(error);
  }

  @override
  void clearError(String errorId) {
    if (_disposed) return;

    _errorQueue.removeWhere((error) => error.id == errorId);
    _cancelAutoDismissTimer(errorId);
    _removeErrorSignature(errorId);
    _notifyListeners();
  }

  @override
  void clearAllErrors() {
    if (_disposed) return;

    _errorQueue.clear();
    _cancelAllAutoDismissTimers();
    _errorSignatures.clear();
    _notifyListeners();
  }

  @override
  void clearErrorsByType(String errorType) {
    if (_disposed) return;

    final errorsToRemove = _errorQueue
        .where((error) => error.type.name == errorType)
        .toList();

    for (final error in errorsToRemove) {
      clearError(error.id);
    }
  }

  @override
  Stream<List<AppError>> get errorStream => _errorStreamController.stream;

  @override
  Stream<AppError?> get currentErrorStream => _currentErrorStreamController.stream;

  @override
  bool get hasErrors => _errorQueue.isNotEmpty;

  @override
  List<AppError> get activeErrors => List.unmodifiable(_errorQueue);

  @override
  AppError? get currentError => _getPriorityError();

  /// Returns the current network status
  NetworkStatus get networkStatus => _networkMonitor.currentStatus;

  /// Returns whether the device is currently offline
  bool get isOffline => _networkMonitor.isOffline;

  /// Returns the network monitor instance
  NetworkMonitor get networkMonitor => _networkMonitor;

  @override
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _cancelAllAutoDismissTimers();
    _networkStatusSubscription?.cancel();
    _networkMonitor.dispose();
    _errorStreamController.close();
    _currentErrorStreamController.close();
    _errorQueue.clear();
    _errorSignatures.clear();
  }

  /// Adds an error to the queue with priority-based ordering
  void _addErrorToQueue(AppError error) {
    // Remove oldest error if queue is at maximum capacity
    if (_errorQueue.length >= _maxQueueSize) {
      // Find the oldest error (by timestamp) with the lowest priority
      AppError? oldestError;
      DateTime? oldestTimestamp;
      int lowestPriority = error.priority; // Only remove errors with lower or equal priority
      
      for (final queueError in _errorQueue) {
        if (queueError.priority <= lowestPriority) {
          if (oldestError == null || queueError.timestamp.isBefore(oldestTimestamp!)) {
            oldestError = queueError;
            oldestTimestamp = queueError.timestamp;
          }
        }
      }
      
      // If no suitable error found, remove the oldest overall
      if (oldestError == null) {
        oldestTimestamp = null;
        for (final queueError in _errorQueue) {
          if (oldestError == null || queueError.timestamp.isBefore(oldestTimestamp!)) {
            oldestError = queueError;
            oldestTimestamp = queueError.timestamp;
          }
        }
      }
      
      if (oldestError != null) {
        _errorQueue.remove(oldestError);
        _cancelAutoDismissTimer(oldestError.id);
        _removeErrorSignature(oldestError.id);
      }
    }

    // Insert error in priority order (highest priority first)
    bool inserted = false;
    final queueList = _errorQueue.toList();
    
    for (int i = 0; i < queueList.length; i++) {
      if (error.priority > queueList[i].priority) {
        _errorQueue.clear();
        _errorQueue.addAll([
          ...queueList.take(i),
          error,
          ...queueList.skip(i),
        ]);
        inserted = true;
        break;
      }
    }

    if (!inserted) {
      _errorQueue.add(error);
    }
  }

  /// Schedules auto-dismiss for errors that support it
  void _scheduleAutoDismiss(AppError error) {
    if (!error.shouldAutoDismiss) return;

    final timer = Timer(error.autoDismissDuration, () {
      clearError(error.id);
    });

    _autoDismissTimers[error.id] = timer;
  }

  /// Cancels the auto-dismiss timer for a specific error
  void _cancelAutoDismissTimer(String errorId) {
    final timer = _autoDismissTimers.remove(errorId);
    timer?.cancel();
  }

  /// Cancels all auto-dismiss timers
  void _cancelAllAutoDismissTimers() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
  }

  /// Persists critical errors for later retrieval
  void _persistCriticalError(AppError error) {
    if (error.severity != ErrorSeverity.critical) return;

    // TODO: Implement persistence to local storage
    // This would store critical errors to be retrieved after app restart
    // For now, we'll just log that persistence should happen
    print('Critical error should be persisted: ${error.id}');
  }

  /// Generates a signature for error deduplication
  String _generateErrorSignature(AppError error) {
    // Create a signature based on error type, message, and key metadata
    final buffer = StringBuffer();
    buffer.write(error.type.name);
    buffer.write('|');
    buffer.write(error.message);
    
    // Add type-specific signature components
    if (error is ApiError) {
      buffer.write('|${error.statusCode}|${error.endpoint}|${error.method}');
    } else if (error is NetworkError) {
      buffer.write('|${error.networkType.name}|${error.url ?? ''}');
    } else if (error is ValidationError) {
      buffer.write('|${error.formId ?? ''}|${error.fieldErrors.keys.join(',')}');
    } else if (error is ClientError) {
      buffer.write('|${error.componentName ?? ''}');
    }

    return buffer.toString();
  }

  /// Removes error signature for the given error ID
  void _removeErrorSignature(String errorId) {
    // Find and remove the signature for this error
    final error = _errorQueue.cast<AppError?>().firstWhere(
      (e) => e?.id == errorId,
      orElse: () => null,
    );
    
    if (error != null) {
      final signature = _generateErrorSignature(error);
      _errorSignatures.remove(signature);
    }
  }

  /// Gets the highest priority error from the queue
  AppError? _getPriorityError() {
    if (_errorQueue.isEmpty) return null;
    
    // Queue is already sorted by priority, so first item is highest priority
    return _errorQueue.first;
  }

  /// Notifies all listeners about error state changes
  void _notifyListeners() {
    if (_disposed) return;

    final errorList = List<AppError>.from(_errorQueue);
    final currentError = _getPriorityError();

    _errorStreamController.add(errorList);
    _currentErrorStreamController.add(currentError);
  }

  /// Initializes network monitoring and sets up status change listeners
  void _initializeNetworkMonitoring() {
    // Start network monitoring
    _networkMonitor.startMonitoring();

    // Listen for network status changes
    _networkStatusSubscription = _networkMonitor.statusStream.listen(
      _handleNetworkStatusChange,
      onError: (error) {
        // Handle network monitoring errors gracefully
        print('Network monitoring error: $error');
      },
    );
  }

  /// Handles network status changes and creates appropriate errors
  void _handleNetworkStatusChange(NetworkStatus status) {
    if (_disposed) return;

    // Clear existing network errors when connection is restored
    if (status.isConnected && !status.isOffline) {
      clearErrorsByType('network');
      clearErrorsByType('offline');
      return;
    }

    // Create network error for offline state
    if (status.isOffline) {
      final offlineError = NetworkError(
        message: 'No internet connection available',
        networkType: NetworkErrorType.noConnection,
      );
      showError(offlineError);
      return;
    }

    // Create network error for poor quality
    if (status.quality == NetworkQuality.poor) {
      final poorQualityError = NetworkError(
        message: 'Poor network connection detected',
        networkType: NetworkErrorType.poorQuality,
      );
      showError(poorQualityError);
    }
  }

  /// Consolidates similar errors to prevent queue overflow with duplicates
  _ConsolidationResult? _consolidateSimilarErrors(AppError newError) {
    for (final existingError in _errorQueue) {
      if (_areErrorsSimilar(existingError, newError)) {
        final consolidatedError = _createConsolidatedError(existingError, newError);
        return _ConsolidationResult(
          existingError: existingError,
          consolidatedError: consolidatedError,
        );
      }
    }
    return null;
  }

  /// Determines if two errors are similar enough to be consolidated
  bool _areErrorsSimilar(AppError error1, AppError error2) {
    // Must be the same type and severity
    if (error1.type != error2.type || error1.severity != error2.severity) {
      return false;
    }

    // Type-specific similarity checks
    if (error1 is ApiError && error2 is ApiError) {
      return _areApiErrorsSimilar(error1, error2);
    } else if (error1 is NetworkError && error2 is NetworkError) {
      return _areNetworkErrorsSimilar(error1, error2);
    } else if (error1 is ValidationError && error2 is ValidationError) {
      return _areValidationErrorsSimilar(error1, error2);
    } else if (error1 is ClientError && error2 is ClientError) {
      return _areClientErrorsSimilar(error1, error2);
    }

    // Generic similarity check for other error types
    return error1.message == error2.message;
  }

  /// Checks if two API errors are similar
  bool _areApiErrorsSimilar(ApiError error1, ApiError error2) {
    return error1.statusCode == error2.statusCode &&
           error1.endpoint == error2.endpoint &&
           error1.method == error2.method;
  }

  /// Checks if two network errors are similar
  bool _areNetworkErrorsSimilar(NetworkError error1, NetworkError error2) {
    return error1.networkType == error2.networkType &&
           error1.url == error2.url;
  }

  /// Checks if two validation errors are similar
  bool _areValidationErrorsSimilar(ValidationError error1, ValidationError error2) {
    // Validation errors are similar if they're from the same form
    // regardless of which specific fields have errors
    return error1.formId == error2.formId;
  }

  /// Checks if two client errors are similar
  bool _areClientErrorsSimilar(ClientError error1, ClientError error2) {
    return error1.componentName == error2.componentName &&
           error1.message == error2.message;
  }

  /// Checks if field errors are similar
  bool _areFieldErrorsSimilar(
    Map<String, List<String>> fields1,
    Map<String, List<String>> fields2,
  ) {
    if (fields1.length != fields2.length) return false;
    
    for (final key in fields1.keys) {
      if (!fields2.containsKey(key)) return false;
    }
    
    return true;
  }

  /// Creates a consolidated error from two similar errors
  AppError _createConsolidatedError(AppError existingError, AppError newError) {
    // Use the newer timestamp and combine metadata
    final combinedMetadata = <String, dynamic>{
      ...?existingError.metadata,
      ...?newError.metadata,
      'consolidatedCount': (existingError.metadata?['consolidatedCount'] ?? 1) + 1,
      'lastOccurrence': newError.timestamp.toIso8601String(),
      'firstOccurrence': existingError.timestamp.toIso8601String(),
    };

    final consolidatedMessage = _createConsolidatedMessage(existingError.message, combinedMetadata);

    // Create consolidated error based on type
    if (existingError is ApiError && newError is ApiError) {
      return ApiError.withMetadata(
        id: existingError.id, // Keep the same ID
        message: consolidatedMessage,
        statusCode: existingError.statusCode,
        endpoint: existingError.endpoint,
        method: existingError.method,
        timestamp: newError.timestamp,
        requestData: existingError.requestData,
        responseData: existingError.responseData,
        actions: existingError.actions,
        metadata: combinedMetadata,
      );
    } else if (existingError is NetworkError && newError is NetworkError) {
      return NetworkError.withMetadata(
        id: existingError.id,
        message: consolidatedMessage,
        networkType: existingError.networkType,
        timeout: existingError.timeout,
        url: existingError.url,
        timestamp: newError.timestamp,
        actions: existingError.actions,
        metadata: combinedMetadata,
      );
    } else if (existingError is ValidationError && newError is ValidationError) {
      // Merge field errors for validation errors
      final mergedFieldErrors = <String, List<String>>{
        ...existingError.fieldErrors,
      };
      
      for (final entry in newError.fieldErrors.entries) {
        if (mergedFieldErrors.containsKey(entry.key)) {
          // Combine unique error messages
          final existingMessages = mergedFieldErrors[entry.key]!;
          final newMessages = entry.value.where(
            (msg) => !existingMessages.contains(msg),
          );
          mergedFieldErrors[entry.key] = [...existingMessages, ...newMessages];
        } else {
          mergedFieldErrors[entry.key] = entry.value;
        }
      }

      return ValidationError.withMetadata(
        id: existingError.id,
        message: consolidatedMessage,
        fieldErrors: mergedFieldErrors,
        formId: existingError.formId,
        timestamp: newError.timestamp,
        actions: existingError.actions,
        metadata: combinedMetadata,
      );
    } else if (existingError is ClientError && newError is ClientError) {
      return ClientError.withMetadata(
        id: existingError.id,
        message: consolidatedMessage,
        stackTrace: existingError.stackTrace,
        componentName: existingError.componentName,
        context: existingError.context,
        timestamp: newError.timestamp,
        actions: existingError.actions,
        metadata: combinedMetadata,
      );
    }

    // Fallback for generic errors - this shouldn't happen with current error types
    return existingError.copyWith(
      timestamp: newError.timestamp,
      message: consolidatedMessage,
    );
  }

  /// Creates a consolidated error message
  String _createConsolidatedMessage(String originalMessage, Map<String, dynamic> metadata) {
    final count = metadata['consolidatedCount'] ?? 1;
    if (count > 1) {
      return '$originalMessage (occurred $count times)';
    }
    return originalMessage;
  }

  /// Replaces an existing error in the queue with a new one
  void _replaceErrorInQueue(AppError existingError, AppError newError) {
    final index = _errorQueue.toList().indexWhere((e) => e.id == existingError.id);
    if (index != -1) {
      // Cancel the old error's timer
      _cancelAutoDismissTimer(existingError.id);
      _removeErrorSignature(existingError.id);

      // Replace with new error
      final queueList = _errorQueue.toList();
      queueList[index] = newError;
      
      _errorQueue.clear();
      _errorQueue.addAll(queueList);

      // Add new error signature and schedule auto-dismiss
      final signature = _generateErrorSignature(newError);
      _errorSignatures.add(signature);
      _scheduleAutoDismiss(newError);
    }
  }
}

/// Helper class for error consolidation results
class _ConsolidationResult {
  final AppError existingError;
  final AppError consolidatedError;

  _ConsolidationResult({
    required this.existingError,
    required this.consolidatedError,
  });
}