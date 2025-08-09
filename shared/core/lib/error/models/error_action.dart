import 'package:flutter/material.dart';

/// Represents an action that can be taken to resolve or handle an error
class ErrorAction {
  /// Unique identifier for the action
  final String id;
  
  /// Display label for the action button
  final String label;
  
  /// Optional icon to display with the action
  final IconData? icon;
  
  /// Callback function to execute when the action is triggered
  final VoidCallback onPressed;
  
  /// Whether this is the primary action (highlighted differently)
  final bool isPrimary;
  
  /// Whether this action is destructive (e.g., delete, clear)
  final bool isDestructive;

  const ErrorAction({
    required this.id,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  /// Creates a retry action
  factory ErrorAction.retry(VoidCallback onRetry) {
    return ErrorAction(
      id: 'retry',
      label: 'Retry',
      icon: Icons.refresh,
      onPressed: onRetry,
      isPrimary: true,
    );
  }

  /// Creates a dismiss action
  factory ErrorAction.dismiss(VoidCallback onDismiss) {
    return ErrorAction(
      id: 'dismiss',
      label: 'Dismiss',
      icon: Icons.close,
      onPressed: onDismiss,
    );
  }

  /// Creates a details action
  factory ErrorAction.details(VoidCallback onShowDetails) {
    return ErrorAction(
      id: 'details',
      label: 'Details',
      icon: Icons.info_outline,
      onPressed: onShowDetails,
    );
  }

  /// Creates a login action
  factory ErrorAction.login(VoidCallback onLogin) {
    return ErrorAction(
      id: 'login',
      label: 'Login',
      icon: Icons.login,
      onPressed: onLogin,
      isPrimary: true,
    );
  }

  /// Creates a contact support action
  factory ErrorAction.contactSupport(VoidCallback onContactSupport) {
    return ErrorAction(
      id: 'contact_support',
      label: 'Contact Support',
      icon: Icons.support_agent,
      onPressed: onContactSupport,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorAction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ErrorAction{id: $id, label: $label, isPrimary: $isPrimary, isDestructive: $isDestructive}';
  }
}