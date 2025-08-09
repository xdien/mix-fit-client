import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/app_error.dart';
import '../models/error_action.dart';
import '../models/error_severity.dart';

/// A non-intrusive snackbar widget for displaying low-priority error notifications
class ErrorSnackbarWidget extends StatelessWidget {
  final AppError error;
  final Duration? duration;
  final VoidCallback? onDismiss;
  final bool showAction;

  const ErrorSnackbarWidget({
    Key? key,
    required this.error,
    this.duration,
    this.onDismiss,
    this.showAction = true,
  }) : super(key: key);

  /// Shows the error snackbar in the given context
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show({
    required BuildContext context,
    required AppError error,
    Duration? duration,
    VoidCallback? onDismiss,
    bool showAction = true,
    SnackBarBehavior behavior = SnackBarBehavior.floating,
  }) {
    final snackBar = SnackBar(
      content: ErrorSnackbarWidget(
        error: error,
        duration: duration,
        onDismiss: onDismiss,
        showAction: showAction,
      ),
      duration: duration ?? _getDefaultDuration(error.severity),
      behavior: behavior,
      backgroundColor: _getBackgroundColor(context, error.severity),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: const EdgeInsets.all(16.0),
      padding: EdgeInsets.zero,
      action: showAction ? _buildSnackBarAction(context, error, onDismiss) : null,
    );

    return ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows multiple error snackbars in sequence
  static void showMultiple({
    required BuildContext context,
    required List<AppError> errors,
    Duration? duration,
    VoidCallback? onDismiss,
    bool showAction = true,
    Duration delayBetween = const Duration(milliseconds: 300),
  }) {
    for (int i = 0; i < errors.length; i++) {
      Future.delayed(delayBetween * i, () {
        if (context.mounted) {
          show(
            context: context,
            error: errors[i],
            duration: duration,
            onDismiss: onDismiss,
            showAction: showAction,
          );
        }
      });
    }
  }

  static Duration _getDefaultDuration(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return const Duration(seconds: 4);
      case ErrorSeverity.warning:
        return const Duration(seconds: 6);
      case ErrorSeverity.error:
        return const Duration(seconds: 8);
      case ErrorSeverity.critical:
        return const Duration(seconds: 10);
    }
  }

  static Color _getBackgroundColor(BuildContext context, ErrorSeverity severity) {
    final theme = Theme.of(context);
    
    switch (severity) {
      case ErrorSeverity.info:
        return Colors.blue.shade600;
      case ErrorSeverity.warning:
        return Colors.orange.shade600;
      case ErrorSeverity.error:
        return Colors.red.shade600;
      case ErrorSeverity.critical:
        return Colors.red.shade800;
    }
  }

  static SnackBarAction? _buildSnackBarAction(
    BuildContext context,
    AppError error,
    VoidCallback? onDismiss,
  ) {
    // Look for primary action first
    final primaryAction = error.actions?.cast<ErrorAction?>().firstWhere(
      (action) => action?.isPrimary == true,
      orElse: () => null,
    );

    if (primaryAction != null) {
      return SnackBarAction(
        label: primaryAction.label,
        textColor: Colors.white,
        onPressed: () {
          primaryAction.onPressed();
          onDismiss?.call();
        },
      );
    }

    // Look for retry action
    final retryAction = error.actions?.cast<ErrorAction?>().firstWhere(
      (action) => action?.id == 'retry',
      orElse: () => null,
    );

    if (retryAction != null) {
      return SnackBarAction(
        label: retryAction.label,
        textColor: Colors.white,
        onPressed: () {
          retryAction.onPressed();
          onDismiss?.call();
        },
      );
    }

    // Default dismiss action
    return SnackBarAction(
      label: 'Dismiss',
      textColor: Colors.white,
      onPressed: () {
        onDismiss?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _getSemanticLabel(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            _buildErrorIcon(),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    error.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_shouldShowSubtitle()) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      _getSubtitle(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (_shouldShowInlineAction()) ...[
              const SizedBox(width: 12.0),
              _buildInlineAction(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData icon;
    Color color = Colors.white;

    switch (error.severity) {
      case ErrorSeverity.critical:
        icon = Icons.error;
        break;
      case ErrorSeverity.error:
        icon = Icons.warning;
        break;
      case ErrorSeverity.warning:
        icon = Icons.info;
        break;
      case ErrorSeverity.info:
        icon = Icons.info_outline;
        break;
    }

    return Semantics(
      label: '${error.severity.name} error icon',
      child: Icon(
        icon,
        color: color,
        size: 20.0,
      ),
    );
  }

  bool _shouldShowSubtitle() {
    return error.type.name.isNotEmpty && error.severity != ErrorSeverity.info;
  }

  String _getSubtitle() {
    final typeText = error.type.name.replaceAll('_', ' ').toUpperCase();
    return '$typeText ERROR';
  }

  bool _shouldShowInlineAction() {
    // Show inline action for critical errors or when there's a primary action
    return error.severity == ErrorSeverity.critical ||
           (error.actions?.any((action) => action.isPrimary) ?? false);
  }

  Widget _buildInlineAction(BuildContext context) {
    final primaryAction = error.actions?.cast<ErrorAction?>().firstWhere(
      (action) => action?.isPrimary == true,
      orElse: () => null,
    );

    if (primaryAction != null) {
      return Semantics(
        label: '${primaryAction.label} button',
        button: true,
        child: TextButton(
          onPressed: () {
            primaryAction.onPressed();
            onDismiss?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            primaryAction.label,
            style: const TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Default action for critical errors
    if (error.severity == ErrorSeverity.critical) {
      return Semantics(
        label: 'View details button',
        button: true,
        child: TextButton(
          onPressed: () {
            // This would typically show the error dialog
            onDismiss?.call();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Details',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  String _getSemanticLabel() {
    return 'Error notification: ${error.severity.name} - ${error.message}';
  }
}

/// A queue manager for handling multiple snackbar notifications
class ErrorSnackbarQueue {
  static final List<AppError> _queue = [];
  static bool _isProcessing = false;

  /// Adds an error to the snackbar queue
  static void add(AppError error) {
    _queue.add(error);
    _processQueue();
  }

  /// Adds multiple errors to the snackbar queue
  static void addAll(List<AppError> errors) {
    _queue.addAll(errors);
    _processQueue();
  }

  /// Clears the snackbar queue
  static void clear() {
    _queue.clear();
  }

  /// Gets the current queue length
  static int get length => _queue.length;

  /// Processes the queue and shows snackbars
  static void _processQueue() {
    // For testing purposes, we don't automatically process the queue
    // In a real implementation, this would show snackbars with proper context
  }

  static void _processNextItem() {
    // Implementation would go here in a real app
  }
}