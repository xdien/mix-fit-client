import 'dart:async';
import 'package:mobx/mobx.dart';

import '../models/app_error.dart';
import '../models/network_status.dart';
import '../services/error_service_interface.dart';
import '../services/network_monitor.dart';

part 'error_store.g.dart';

/// MobX store for managing error UI state and network status
class ErrorStore = _ErrorStore with _$ErrorStore;

abstract class _ErrorStore with Store {
  final IErrorService _errorService;
  final NetworkMonitor _networkMonitor;
  
  StreamSubscription<List<AppError>>? _errorStreamSubscription;
  StreamSubscription<AppError?>? _currentErrorStreamSubscription;
  StreamSubscription<NetworkStatus>? _networkStatusSubscription;
  
  Timer? _autoDismissTimer;
  bool _disposed = false;

  _ErrorStore(this._errorService, this._networkMonitor) {
    _initializeSubscriptions();
  }

  // Observable properties for active errors
  @observable
  ObservableList<AppError> activeErrors = ObservableList<AppError>();

  @observable
  AppError? currentError;

  // Observable properties for network status
  @observable
  bool isOffline = false;

  @observable
  NetworkQuality networkQuality = NetworkQuality.good;

  @observable
  NetworkStatus? networkStatus;

  // Observable properties for error bar visibility and state
  @observable
  bool isErrorBarVisible = true;

  @observable
  bool isErrorBarMinimized = false;

  @observable
  bool showErrorDetailsFlag = false;

  // Observable properties for user preferences
  @observable
  bool autoHideNonCriticalErrors = true;

  @observable
  Duration autoHideDuration = const Duration(seconds: 15);

  @observable
  bool showNetworkStatusInBar = true;

  // Computed properties for error state calculations
  @computed
  bool get hasErrors => activeErrors.isNotEmpty;

  @computed
  bool get hasActiveErrors => activeErrors.isNotEmpty;

  @computed
  int get errorCount => activeErrors.length;

  @computed
  AppError? get priorityError {
    if (activeErrors.isEmpty) return null;
    
    // Find the error with the highest priority
    AppError? highestPriorityError;
    int highestPriority = -1;
    
    for (final error in activeErrors) {
      if (error.priority > highestPriority) {
        highestPriority = error.priority;
        highestPriorityError = error;
      }
    }
    
    return highestPriorityError;
  }

  @computed
  bool get shouldShowErrorBar => 
      (hasErrors || (isOffline && showNetworkStatusInBar)) && isErrorBarVisible;

  @computed
  bool get shouldShowOfflineIndicator => 
      isOffline && showNetworkStatusInBar;

  @computed
  bool get hasNetworkIssues => 
      isOffline || networkQuality == NetworkQuality.poor;

  @computed
  String get errorBarTitle {
    if (hasErrors && priorityError != null) {
      return priorityError!.message;
    } else if (isOffline) {
      return 'No internet connection';
    } else if (networkQuality == NetworkQuality.poor) {
      return 'Poor network connection';
    }
    return '';
  }

  @computed
  String get networkStatusText {
    if (isOffline) {
      return 'Offline';
    }
    
    switch (networkQuality) {
      case NetworkQuality.excellent:
        return 'Excellent connection';
      case NetworkQuality.good:
        return 'Good connection';
      case NetworkQuality.fair:
        return 'Fair connection';
      case NetworkQuality.poor:
        return 'Poor connection';
      case NetworkQuality.offline:
        return 'Offline';
    }
  }

  @computed
  bool get canRetryCurrentError {
    if (priorityError == null) return false;
    return priorityError!.actions?.any((action) => action.id == 'retry') ?? false;
  }

  @computed
  bool get shouldAutoHideCurrentError {
    if (priorityError == null) return false;
    return autoHideNonCriticalErrors && priorityError!.shouldAutoDismiss;
  }

  // Actions for error management
  @action
  void addError(AppError error) {
    _errorService.showError(error);
  }

  @action
  void removeError(String errorId) {
    _errorService.clearError(errorId);
  }

  @action
  void clearAllErrors() {
    _errorService.clearAllErrors();
  }

  @action
  void clearErrorsByType(String errorType) {
    _errorService.clearErrorsByType(errorType);
  }

  // Actions for error bar visibility and state management
  @action
  void showErrorBar() {
    isErrorBarVisible = true;
    isErrorBarMinimized = false;
  }

  @action
  void hideErrorBar() {
    isErrorBarVisible = false;
  }

  @action
  void minimizeErrorBar() {
    isErrorBarMinimized = true;
  }

  @action
  void expandErrorBar() {
    isErrorBarMinimized = false;
  }

  @action
  void toggleErrorBarMinimized() {
    isErrorBarMinimized = !isErrorBarMinimized;
  }

  @action
  void showErrorDetails() {
    showErrorDetailsFlag = true;
  }

  @action
  void hideErrorDetails() {
    showErrorDetailsFlag = false;
  }

  @action
  void toggleErrorDetails() {
    showErrorDetailsFlag = !showErrorDetailsFlag;
  }

  // Actions for user preferences
  @action
  void setAutoHideNonCriticalErrors(bool value) {
    autoHideNonCriticalErrors = value;
    _scheduleAutoHideIfNeeded();
  }

  @action
  void setAutoHideDuration(Duration duration) {
    autoHideDuration = duration;
    _scheduleAutoHideIfNeeded();
  }

  @action
  void setShowNetworkStatusInBar(bool value) {
    showNetworkStatusInBar = value;
  }

  // Actions for handling network status updates
  @action
  void _updateNetworkStatus(NetworkStatus status) {
    networkStatus = status;
    isOffline = status.isOffline;
    networkQuality = status.quality;
    
    // Show error bar when network issues occur
    if (status.isOffline || status.quality == NetworkQuality.poor) {
      showErrorBar();
    }
    
    // Auto-minimize when connection is restored and no errors
    if (status.isConnected && 
        status.quality.isGoodEnough && 
        !hasErrors) {
      Timer(const Duration(seconds: 3), () {
        if (!hasErrors && !hasNetworkIssues) {
          minimizeErrorBar();
        }
      });
    }
  }

  @action
  void _updateActiveErrors(List<AppError> errors) {
    activeErrors.clear();
    activeErrors.addAll(errors);
    
    // Show error bar when errors are present
    if (errors.isNotEmpty) {
      showErrorBar();
    }
    
    // Schedule auto-hide for non-critical errors
    _scheduleAutoHideIfNeeded();
  }

  @action
  void _updateCurrentError(AppError? error) {
    currentError = error;
    
    // Cancel existing auto-dismiss timer
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    
    // Schedule auto-hide for the new current error if applicable
    _scheduleAutoHideIfNeeded();
  }

  // Private methods
  void _initializeSubscriptions() {
    // Subscribe to error service streams
    _errorStreamSubscription = _errorService.errorStream.listen(
      _updateActiveErrors,
      onError: (error) {
        print('Error stream subscription error: $error');
      },
    );

    _currentErrorStreamSubscription = _errorService.currentErrorStream.listen(
      _updateCurrentError,
      onError: (error) {
        print('Current error stream subscription error: $error');
      },
    );

    // Subscribe to network status changes
    _networkStatusSubscription = _networkMonitor.statusStream.listen(
      _updateNetworkStatus,
      onError: (error) {
        print('Network status subscription error: $error');
      },
    );

    // Initialize with current states
    _updateActiveErrors(_errorService.activeErrors);
    _updateCurrentError(_errorService.currentError);
    _updateNetworkStatus(_networkMonitor.currentStatus);
  }

  void _scheduleAutoHideIfNeeded() {
    if (_disposed) return;
    
    // Cancel existing timer
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    
    // Only schedule auto-hide if enabled and current error should auto-dismiss
    if (!shouldAutoHideCurrentError || priorityError == null) {
      return;
    }
    
    final error = priorityError!;
    final duration = autoHideNonCriticalErrors 
        ? autoHideDuration 
        : error.autoDismissDuration;
    
    _autoDismissTimer = Timer(duration, () {
      if (!_disposed && priorityError?.id == error.id) {
        removeError(error.id);
      }
    });
  }

  void dispose() {
    if (_disposed) return;
    
    _disposed = true;
    
    // Cancel subscriptions
    _errorStreamSubscription?.cancel();
    _currentErrorStreamSubscription?.cancel();
    _networkStatusSubscription?.cancel();
    
    // Cancel timers
    _autoDismissTimer?.cancel();
    
    // Clear observables
    activeErrors.clear();
    currentError = null;
    networkStatus = null;
  }
}