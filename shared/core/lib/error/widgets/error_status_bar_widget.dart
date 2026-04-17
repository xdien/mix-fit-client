import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../models/app_error.dart';
import '../models/error_action.dart';
import '../models/error_severity.dart';
import '../models/network_status.dart';
import '../stores/error_store.dart';

/// A comprehensive status bar widget that shows error status,
/// network connectivity indicators, and provides user interaction capabilities
class ErrorStatusBarWidget extends StatelessWidget {
  final ErrorStore errorStore;
  final bool showDetails;
  final bool isMinimized;
  final VoidCallback? onTap;
  final VoidCallback? onMinimize;
  final VoidCallback? onExpand;

  const ErrorStatusBarWidget({
    Key? key,
    required this.errorStore,
    this.showDetails = true,
    this.isMinimized = false,
    this.onTap,
    this.onMinimize,
    this.onExpand,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        // Don't show the status bar if no errors and good network connection
        if (!errorStore.shouldShowErrorBar) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: _getSemanticLabel(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Material(
              color: _getBackgroundColor(context),
              elevation: _shouldShowElevation() ? 2.0 : 0.0,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: isMinimized ? 8.0 : 12.0,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _getBorderColor(context),
                      width: 0.5,
                    ),
                  ),
                ),
                child: isMinimized 
                    ? _buildMinimizedContent(context) 
                    : _buildFullContent(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimizedContent(BuildContext context) {
    return Row(
      children: [
        _buildStatusIcon(context),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            errorStore.errorBarTitle,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: _getTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8.0),
        _buildNetworkQualityIndicator(context),
        const SizedBox(width: 8.0),
        if (onExpand != null)
          Semantics(
            label: 'Expand error details',
            button: true,
            child: GestureDetector(
              onTap: onExpand,
              child: Icon(
                Icons.expand_more,
                size: 20.0,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _buildStatusIcon(context),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorStore.errorBarTitle,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: _getTextColor(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (errorStore.hasNetworkIssues && !errorStore.hasErrors)
                    Text(
                      errorStore.networkStatusText,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: _getTextColor(context).withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            _buildNetworkQualityIndicator(context),
            const SizedBox(width: 12.0),
            _buildActionButtons(context),
          ],
        ),
        if (_shouldShowDetails()) ...[
          const SizedBox(height: 8.0),
          _buildDetailsSection(context),
        ],
      ],
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    IconData icon;
    Color color;

    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      switch (error.severity) {
        case ErrorSeverity.critical:
          icon = Icons.error;
          color = Colors.red;
          break;
        case ErrorSeverity.error:
          icon = Icons.warning;
          color = Colors.orange;
          break;
        case ErrorSeverity.warning:
          icon = Icons.info;
          color = Colors.amber;
          break;
        case ErrorSeverity.info:
          icon = Icons.info_outline;
          color = Colors.blue;
          break;
      }
    } else if (errorStore.isOffline) {
      icon = Icons.wifi_off;
      color = Colors.grey;
    } else if (errorStore.networkQuality == NetworkQuality.poor) {
      icon = Icons.signal_wifi_bad;
      color = Colors.orange;
    } else {
      icon = Icons.check_circle;
      color = Colors.green;
    }

    return Semantics(
      label: _getStatusIconSemanticLabel(),
      child: Icon(
        icon,
        size: 20.0,
        color: color,
      ),
    );
  }

  Widget _buildNetworkQualityIndicator(BuildContext context) {
    if (!errorStore.showNetworkStatusInBar) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String tooltip;

    switch (errorStore.networkQuality) {
      case NetworkQuality.excellent:
        icon = Icons.signal_wifi_4_bar;
        color = Colors.green;
        tooltip = 'Excellent connection';
        break;
      case NetworkQuality.good:
        icon = Icons.signal_wifi_4_bar;
        color = Colors.blue;
        tooltip = 'Good connection';
        break;
      case NetworkQuality.fair:
        icon = Icons.network_wifi_2_bar;
        color = Colors.orange;
        tooltip = 'Fair connection';
        break;
      case NetworkQuality.poor:
        icon = Icons.network_wifi_1_bar;
        color = Colors.red;
        tooltip = 'Poor connection';
        break;
      case NetworkQuality.offline:
        icon = Icons.wifi_off;
        color = Colors.grey;
        tooltip = 'Offline';
        break;
    }

    return Semantics(
      label: 'Network quality: $tooltip',
      child: Tooltip(
        message: tooltip,
        child: Icon(
          icon,
          size: 16.0,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = <Widget>[];

    // Add retry button if current error can be retried
    if (errorStore.canRetryCurrentError && errorStore.priorityError != null) {
      final retryAction = errorStore.priorityError!.actions
          ?.cast<ErrorAction?>()
          .firstWhere((action) => action?.id == 'retry', orElse: () => null);
      
      if (retryAction != null) {
        actions.add(
          Semantics(
            label: 'Retry action',
            button: true,
            child: IconButton(
              onPressed: retryAction.onPressed,
              icon: Icon(retryAction.icon ?? Icons.refresh),
              iconSize: 20.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(
                minWidth: 32.0,
                minHeight: 32.0,
              ),
              tooltip: retryAction.label,
            ),
          ),
        );
      }
    }

    // Add dismiss button if current error can be dismissed
    if (errorStore.priorityError != null) {
      final dismissAction = errorStore.priorityError!.actions
          ?.cast<ErrorAction?>()
          .firstWhere((action) => action?.id == 'dismiss', orElse: () => null);
      
      if (dismissAction != null) {
        actions.add(
          Semantics(
            label: 'Dismiss error',
            button: true,
            child: IconButton(
              onPressed: dismissAction.onPressed,
              icon: Icon(dismissAction.icon ?? Icons.close),
              iconSize: 20.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(
                minWidth: 32.0,
                minHeight: 32.0,
              ),
              tooltip: dismissAction.label,
            ),
          ),
        );
      }
    }

    // Add details button if available
    if (errorStore.priorityError != null) {
      final detailsAction = errorStore.priorityError!.actions
          ?.cast<ErrorAction?>()
          .firstWhere((action) => action?.id == 'details', orElse: () => null);
      
      if (detailsAction != null) {
        actions.add(
          Semantics(
            label: 'Show error details',
            button: true,
            child: IconButton(
              onPressed: detailsAction.onPressed,
              icon: Icon(detailsAction.icon ?? Icons.info_outline),
              iconSize: 20.0,
              padding: const EdgeInsets.all(4.0),
              constraints: const BoxConstraints(
                minWidth: 32.0,
                minHeight: 32.0,
              ),
              tooltip: detailsAction.label,
            ),
          ),
        );
      }
    }

    // Add minimize button
    if (onMinimize != null) {
      actions.add(
        Semantics(
          label: 'Minimize error bar',
          button: true,
          child: IconButton(
            onPressed: onMinimize,
            icon: const Icon(Icons.expand_less),
            iconSize: 20.0,
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(
              minWidth: 32.0,
              minHeight: 32.0,
            ),
            tooltip: 'Minimize',
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    final details = <String>[];
    
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      
      // Add error type and severity
      details.add('Type: ${error.type.name} (${error.severity.name})');
      
      // Add timestamp
      final timeAgo = DateTime.now().difference(error.timestamp);
      if (timeAgo.inMinutes < 1) {
        details.add('Occurred: Just now');
      } else if (timeAgo.inHours < 1) {
        details.add('Occurred: ${timeAgo.inMinutes} minutes ago');
      } else {
        details.add('Occurred: ${timeAgo.inHours} hours ago');
      }
      
      // Add metadata if available
      if (error.metadata != null && error.metadata!.isNotEmpty) {
        error.metadata!.forEach((key, value) {
          if (value != null) {
            details.add('$key: $value');
          }
        });
      }
    }
    
    if (errorStore.networkStatus != null) {
      final status = errorStore.networkStatus!;
      if (status.latency != null) {
        details.add('Network latency: ${status.latency!.inMilliseconds}ms');
      }
      
      final lastCheckedAgo = DateTime.now().difference(status.lastChecked);
      if (lastCheckedAgo.inMinutes < 1) {
        details.add('Network checked: Just now');
      } else {
        details.add('Network checked: ${lastCheckedAgo.inMinutes} minutes ago');
      }
    }

    if (details.isEmpty) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Error details',
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              detail,
              style: TextStyle(
                fontSize: 12.0,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  bool _shouldShowDetails() {
    return showDetails && !isMinimized && (
      errorStore.showErrorDetailsFlag ||
      errorStore.hasErrors ||
      errorStore.hasNetworkIssues
    );
  }

  bool _shouldShowElevation() {
    return errorStore.hasErrors || errorStore.hasNetworkIssues;
  }

  Color _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      switch (error.severity) {
        case ErrorSeverity.critical:
          return Colors.red.withOpacity(0.1);
        case ErrorSeverity.error:
          return Colors.orange.withOpacity(0.1);
        case ErrorSeverity.warning:
          return Colors.amber.withOpacity(0.1);
        case ErrorSeverity.info:
          return Colors.blue.withOpacity(0.05);
      }
    } else if (errorStore.isOffline) {
      return Colors.grey.withOpacity(0.1);
    } else if (errorStore.networkQuality == NetworkQuality.poor) {
      return Colors.orange.withOpacity(0.05);
    }
    
    return theme.colorScheme.surface;
  }

  Color _getBorderColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      switch (error.severity) {
        case ErrorSeverity.critical:
          return Colors.red.withOpacity(0.3);
        case ErrorSeverity.error:
          return Colors.orange.withOpacity(0.3);
        case ErrorSeverity.warning:
          return Colors.amber.withOpacity(0.3);
        case ErrorSeverity.info:
          return Colors.blue.withOpacity(0.3);
      }
    } else if (errorStore.isOffline) {
      return Colors.grey.withOpacity(0.3);
    } else if (errorStore.networkQuality == NetworkQuality.poor) {
      return Colors.orange.withOpacity(0.3);
    }
    
    return theme.colorScheme.outline.withOpacity(0.2);
  }

  Color _getTextColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      switch (error.severity) {
        case ErrorSeverity.critical:
          return Colors.red.shade800;
        case ErrorSeverity.error:
          return Colors.orange.shade800;
        case ErrorSeverity.warning:
          return Colors.amber.shade800;
        case ErrorSeverity.info:
          return Colors.blue.shade800;
      }
    }
    
    return theme.colorScheme.onSurface;
  }

  String _getSemanticLabel() {
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      return 'Error status bar: ${error.severity.name} error - ${error.message}';
    } else if (errorStore.isOffline) {
      return 'Network status bar: Device is offline';
    } else if (errorStore.networkQuality == NetworkQuality.poor) {
      return 'Network status bar: Poor network connection';
    }
    return 'Status bar: All systems normal';
  }

  String _getStatusIconSemanticLabel() {
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      return '${error.severity.name} error icon';
    } else if (errorStore.isOffline) {
      return 'Offline icon';
    } else if (errorStore.networkQuality == NetworkQuality.poor) {
      return 'Poor connection icon';
    }
    return 'Status normal icon';
  }
}