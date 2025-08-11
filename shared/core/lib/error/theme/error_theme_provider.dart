import 'package:flutter/material.dart';
import '../config/error_system_config.dart';

/// Provider for error theme configuration
class ErrorThemeProvider extends InheritedWidget {
  final ErrorThemeConfig themeConfig;
  final ThemeMode themeMode;

  const ErrorThemeProvider({
    Key? key,
    required this.themeConfig,
    required this.themeMode,
    required Widget child,
  }) : super(key: key, child: child);

  static ErrorThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorThemeProvider>();
  }

  static ErrorThemeConfig getThemeConfig(BuildContext context) {
    final provider = of(context);
    if (provider != null) {
      return provider.themeConfig;
    }
    
    // Fallback to theme-based configuration
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark 
        ? ErrorThemeConfig.dark 
        : const ErrorThemeConfig();
  }

  @override
  bool updateShouldNotify(ErrorThemeProvider oldWidget) {
    return themeConfig != oldWidget.themeConfig || 
           themeMode != oldWidget.themeMode;
  }
}

/// Extension methods for error theme integration
extension ErrorThemeExtensions on ErrorThemeConfig {
  /// Gets the appropriate color for an error severity
  Color getColorForSeverity(ErrorSeverity severity, ErrorColorType colorType) {
    switch (colorType) {
      case ErrorColorType.primary:
        return severityColors[severity] ?? Colors.grey;
      case ErrorColorType.background:
        return backgroundColors[severity] ?? Colors.grey.shade100;
      case ErrorColorType.text:
        return textColors[severity] ?? Colors.black87;
      case ErrorColorType.icon:
        return iconColors[severity] ?? Colors.grey.shade600;
      case ErrorColorType.border:
        return borderColors[severity] ?? Colors.grey.shade300;
    }
  }

  /// Gets the appropriate icon for an error severity
  IconData getIconForSeverity(ErrorSeverity severity) {
    return severityIcons[severity] ?? Icons.info_outline;
  }

  /// Creates a decoration for error containers
  BoxDecoration createErrorDecoration(ErrorSeverity severity, {
    bool isElevated = false,
    bool hasBorder = true,
  }) {
    return BoxDecoration(
      color: getColorForSeverity(severity, ErrorColorType.background),
      borderRadius: borderRadius,
      border: hasBorder 
          ? Border.all(
              color: getColorForSeverity(severity, ErrorColorType.border),
              width: 1.0,
            )
          : null,
      boxShadow: isElevated
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: elevation,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Creates a text style for error messages
  TextStyle createErrorTextStyle(ErrorSeverity severity, {
    bool isBold = false,
    double? fontSize,
  }) {
    return messageTextStyle.copyWith(
      color: getColorForSeverity(severity, ErrorColorType.text),
      fontWeight: isBold ? FontWeight.w600 : messageTextStyle.fontWeight,
      fontSize: fontSize ?? messageTextStyle.fontSize,
    );
  }

  /// Creates a text style for error action buttons
  TextStyle createActionTextStyle(ErrorSeverity severity, {
    bool isPrimary = false,
  }) {
    return actionTextStyle.copyWith(
      color: isPrimary 
          ? getColorForSeverity(severity, ErrorColorType.primary)
          : getColorForSeverity(severity, ErrorColorType.text),
    );
  }

  /// Creates a button style for error actions
  ButtonStyle createActionButtonStyle(ErrorSeverity severity, {
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.styleFrom(
        backgroundColor: getColorForSeverity(severity, ErrorColorType.primary),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      );
    } else {
      return TextButton.styleFrom(
        foregroundColor: getColorForSeverity(severity, ErrorColorType.primary),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
      );
    }
  }

  /// Adapts theme for high contrast mode
  ErrorThemeConfig adaptForHighContrast() {
    return ErrorThemeConfig.highContrast.copyWith(
      animationDuration: animationDuration,
      borderRadius: borderRadius,
      elevation: elevation * 2, // Increase elevation for better visibility
    );
  }

  /// Adapts theme for reduced motion
  ErrorThemeConfig adaptForReducedMotion() {
    return copyWith(
      animationDuration: const Duration(milliseconds: 100), // Faster animations
    );
  }
}

/// Types of colors used in error theming
enum ErrorColorType {
  primary,
  background,
  text,
  icon,
  border,
}

/// Widget that applies error theme to its children
class ErrorThemeScope extends StatelessWidget {
  final ErrorSeverity severity;
  final Widget child;
  final bool isElevated;
  final bool hasBorder;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ErrorThemeScope({
    Key? key,
    required this.severity,
    required this.child,
    this.isElevated = false,
    this.hasBorder = true,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeConfig = ErrorThemeProvider.getThemeConfig(context);
    
    return Container(
      margin: margin,
      padding: padding,
      decoration: themeConfig.createErrorDecoration(
        severity,
        isElevated: isElevated,
        hasBorder: hasBorder,
      ),
      child: child,
    );
  }
}

/// Widget for displaying error icons with proper theming
class ErrorIcon extends StatelessWidget {
  final ErrorSeverity severity;
  final double? size;
  final IconData? customIcon;

  const ErrorIcon({
    Key? key,
    required this.severity,
    this.size,
    this.customIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeConfig = ErrorThemeProvider.getThemeConfig(context);
    
    return Icon(
      customIcon ?? themeConfig.getIconForSeverity(severity),
      color: themeConfig.getColorForSeverity(severity, ErrorColorType.icon),
      size: size ?? 24.0,
    );
  }
}

/// Widget for displaying error text with proper theming
class ErrorText extends StatelessWidget {
  final String text;
  final ErrorSeverity severity;
  final bool isBold;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ErrorText({
    Key? key,
    required this.text,
    required this.severity,
    this.isBold = false,
    this.fontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeConfig = ErrorThemeProvider.getThemeConfig(context);
    
    return Text(
      text,
      style: themeConfig.createErrorTextStyle(
        severity,
        isBold: isBold,
        fontSize: fontSize,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Widget for error action buttons with proper theming
class ErrorActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final ErrorSeverity severity;
  final bool isPrimary;
  final IconData? icon;

  const ErrorActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.severity,
    this.isPrimary = false,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeConfig = ErrorThemeProvider.getThemeConfig(context);
    
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(label),
        style: themeConfig.createActionButtonStyle(severity, isPrimary: true),
      );
    } else {
      return TextButton.icon(
        onPressed: onPressed,
        icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
        label: Text(label),
        style: themeConfig.createActionButtonStyle(severity, isPrimary: false),
      );
    }
  }
}