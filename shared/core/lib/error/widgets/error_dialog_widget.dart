import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../models/app_error.dart';
import '../models/api_error.dart';
import '../models/error_action.dart';
import '../models/error_severity.dart';
import '../models/error_type.dart';

/// A modal dialog widget for displaying critical errors that require user attention
class ErrorDialogWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onDismiss;
  final bool showDetails;

  const ErrorDialogWidget({
    Key? key,
    required this.error,
    this.onDismiss,
    this.showDetails = true,
  }) : super(key: key);

  /// Shows the error dialog as a modal
  static Future<void> show({
    required BuildContext context,
    required AppError error,
    VoidCallback? onDismiss,
    bool showDetails = true,
    bool barrierDismissible = false,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ErrorDialogWidget(
        error: error,
        onDismiss: onDismiss,
        showDetails: showDetails,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _getSemanticLabel(),
      child: AlertDialog(
        icon: _buildErrorIcon(),
        title: Text(
          _getDialogTitle(),
          style: TextStyle(
            color: _getTitleColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: _buildContent(context),
        actions: _buildActions(context),
        actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
        contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    IconData icon;
    Color color;

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

    return Semantics(
      label: '${error.severity.name} error icon',
      child: Icon(
        icon,
        color: color,
        size: 32.0,
      ),
    );
  }

  String _getDialogTitle() {
    switch (error.severity) {
      case ErrorSeverity.critical:
        return 'Critical Error';
      case ErrorSeverity.error:
        return 'Error Occurred';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.info:
        return 'Information';
    }
  }

  Color _getTitleColor(BuildContext context) {
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

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error message
          Text(
            error.message,
            style: const TextStyle(
              fontSize: 16.0,
              height: 1.4,
            ),
          ),
          
          // Error resolution guidance
          if (_shouldShowResolutionGuidance()) ...[
            const SizedBox(height: 16.0),
            _buildResolutionGuidance(context),
          ],
          
          // Error details
          if (showDetails && _shouldShowDetails()) ...[
            const SizedBox(height: 16.0),
            _buildDetailsSection(context),
          ],
        ],
      ),
    );
  }

  bool _shouldShowResolutionGuidance() {
    return error.type == ErrorType.authentication ||
           error.type == ErrorType.network ||
           error.type == ErrorType.api ||
           error.type == ErrorType.server ||
           error.type == ErrorType.validation ||
           _isAuthenticationError() ||
           _isServerError();
  }

  bool _isAuthenticationError() {
    if (error is ApiError) {
      final apiError = error as ApiError;
      return apiError.statusCode == 401;
    }
    return false;
  }

  bool _isServerError() {
    if (error is ApiError) {
      final apiError = error as ApiError;
      return apiError.statusCode >= 500;
    }
    return false;
  }

  Widget _buildResolutionGuidance(BuildContext context) {
    final steps = _getResolutionSteps();
    if (steps.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20.0,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                'How to resolve this:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20.0,
                    height: 20.0,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<String> _getResolutionSteps() {
    // Check for specific API error types first
    if (_isAuthenticationError()) {
      return [
        'Check your login credentials',
        'Try logging out and logging back in',
        'Contact support if the problem persists',
      ];
    }
    
    if (_isServerError()) {
      return [
        'Try the action again in a few moments',
        'Check your internet connection',
        'Contact support if the error continues',
      ];
    }

    switch (error.type) {
      case ErrorType.authentication:
        return [
          'Check your login credentials',
          'Try logging out and logging back in',
          'Contact support if the problem persists',
        ];
      case ErrorType.network:
        return [
          'Check your internet connection',
          'Try refreshing the page or restarting the app',
          'Wait a moment and try again',
        ];
      case ErrorType.api:
      case ErrorType.server:
        return [
          'Try the action again in a few moments',
          'Check your internet connection',
          'Contact support if the error continues',
        ];
      case ErrorType.validation:
        return [
          'Check the highlighted fields for errors',
          'Ensure all required information is provided',
          'Verify the format of your input',
        ];
      default:
        return [];
    }
  }

  bool _shouldShowDetails() {
    return error.metadata != null && error.metadata!.isNotEmpty;
  }

  Widget _buildDetailsSection(BuildContext context) {
    if (!_shouldShowDetails()) return const SizedBox.shrink();

    return Semantics(
      label: 'Error details',
      child: ExpansionTile(
        title: const Text(
          'Technical Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.0,
          ),
        ),
        initiallyExpanded: false,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Error ID', error.id),
                _buildDetailRow('Type', '${error.type.name} (${error.severity.name})'),
                _buildDetailRow('Timestamp', _formatTimestamp(error.timestamp)),
                if (error.metadata != null)
                  ...error.metadata!.entries
                      .where((entry) => entry.value != null)
                      .map((entry) => _buildDetailRow(
                            _formatMetadataKey(entry.key),
                            entry.value.toString(),
                          )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.0,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12.0,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.0,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetadataKey(String key) {
    // Convert camelCase or snake_case to Title Case
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    // Add custom error actions first
    if (error.actions != null && error.actions!.isNotEmpty) {
      for (final action in error.actions!) {
        actions.add(
          Semantics(
            label: '${action.label} button',
            button: true,
            child: action.isPrimary
                ? FilledButton(
                    onPressed: () {
                      action.onPressed();
                      if (action.id == 'dismiss' || action.id == 'retry') {
                        Navigator.of(context).pop();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: action.isDestructive 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.icon != null) ...[
                          Icon(action.icon, size: 18.0),
                          const SizedBox(width: 8.0),
                        ],
                        Text(action.label),
                      ],
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      action.onPressed();
                      if (action.id == 'dismiss' || action.id == 'retry') {
                        Navigator.of(context).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: action.isDestructive 
                          ? Colors.red 
                          : Theme.of(context).colorScheme.primary,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.icon != null) ...[
                          Icon(action.icon, size: 18.0),
                          const SizedBox(width: 8.0),
                        ],
                        Text(action.label),
                      ],
                    ),
                  ),
          ),
        );
      }
    }

    // Add default dismiss button if no custom dismiss action exists
    final hasDismissAction = error.actions?.any((action) => action.id == 'dismiss') ?? false;
    if (!hasDismissAction) {
      actions.add(
        Semantics(
          label: 'Close dialog button',
          button: true,
          child: TextButton(
            onPressed: () {
              onDismiss?.call();
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ),
      );
    }

    return actions;
  }

  String _getSemanticLabel() {
    return 'Error dialog: ${error.severity.name} - ${error.message}';
  }
}