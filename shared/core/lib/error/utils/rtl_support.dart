import 'package:flutter/material.dart';

/// Utilities for RTL (Right-to-Left) language support in error UI components
class RTLSupport {
  /// Checks if the current locale is RTL
  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Checks if a locale is RTL based on language code
  static bool isRTLLocale(Locale locale) {
    const rtlLanguages = {
      'ar', // Arabic
      'he', // Hebrew
      'fa', // Persian/Farsi
      'ur', // Urdu
      'ku', // Kurdish
      'dv', // Divehi
      'ps', // Pashto
      'sd', // Sindhi
    };
    
    return rtlLanguages.contains(locale.languageCode);
  }

  /// Gets the appropriate text direction for a locale
  static TextDirection getTextDirection(Locale locale) {
    return isRTLLocale(locale) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Gets the appropriate text align for RTL support
  static TextAlign getTextAlign(BuildContext context, {TextAlign? defaultAlign}) {
    if (isRTL(context)) {
      switch (defaultAlign) {
        case TextAlign.left:
          return TextAlign.right;
        case TextAlign.right:
          return TextAlign.left;
        case TextAlign.start:
          return TextAlign.start; // Flutter handles this automatically
        case TextAlign.end:
          return TextAlign.end; // Flutter handles this automatically
        default:
          return defaultAlign ?? TextAlign.start;
      }
    }
    return defaultAlign ?? TextAlign.start;
  }

  /// Gets the appropriate edge insets for RTL support
  static EdgeInsets getEdgeInsets(
    BuildContext context, {
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) {
    if (isRTL(context)) {
      return EdgeInsets.only(
        left: right,
        top: top,
        right: left,
        bottom: bottom,
      );
    }
    return EdgeInsets.only(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Gets the appropriate edge insets from LTRB for RTL support
  static EdgeInsets getEdgeInsetsFromLTRB(
    BuildContext context,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    return getEdgeInsets(
      context,
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  /// Gets the appropriate border radius for RTL support
  static BorderRadius getBorderRadius(
    BuildContext context, {
    double topLeft = 0.0,
    double topRight = 0.0,
    double bottomLeft = 0.0,
    double bottomRight = 0.0,
  }) {
    if (isRTL(context)) {
      return BorderRadius.only(
        topLeft: Radius.circular(topRight),
        topRight: Radius.circular(topLeft),
        bottomLeft: Radius.circular(bottomRight),
        bottomRight: Radius.circular(bottomLeft),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }

  /// Gets the appropriate alignment for RTL support
  static Alignment getAlignment(BuildContext context, Alignment alignment) {
    if (isRTL(context)) {
      switch (alignment) {
        case Alignment.centerLeft:
          return Alignment.centerRight;
        case Alignment.centerRight:
          return Alignment.centerLeft;
        case Alignment.topLeft:
          return Alignment.topRight;
        case Alignment.topRight:
          return Alignment.topLeft;
        case Alignment.bottomLeft:
          return Alignment.bottomRight;
        case Alignment.bottomRight:
          return Alignment.bottomLeft;
        default:
          return alignment;
      }
    }
    return alignment;
  }

  /// Gets the appropriate main axis alignment for RTL support
  static MainAxisAlignment getMainAxisAlignment(
    BuildContext context,
    MainAxisAlignment alignment,
  ) {
    if (isRTL(context)) {
      switch (alignment) {
        case MainAxisAlignment.start:
          return MainAxisAlignment.end;
        case MainAxisAlignment.end:
          return MainAxisAlignment.start;
        default:
          return alignment;
      }
    }
    return alignment;
  }

  /// Gets the appropriate cross axis alignment for RTL support
  static CrossAxisAlignment getCrossAxisAlignment(
    BuildContext context,
    CrossAxisAlignment alignment,
  ) {
    if (isRTL(context)) {
      switch (alignment) {
        case CrossAxisAlignment.start:
          return CrossAxisAlignment.end;
        case CrossAxisAlignment.end:
          return CrossAxisAlignment.start;
        default:
          return alignment;
      }
    }
    return alignment;
  }

  /// Gets the appropriate icon for RTL support (flips directional icons)
  static IconData getIcon(BuildContext context, IconData icon) {
    if (!isRTL(context)) return icon;

    // Map of LTR icons to their RTL equivalents
    final rtlIconMap = <IconData, IconData>{
      Icons.arrow_back: Icons.arrow_forward,
      Icons.arrow_forward: Icons.arrow_back,
      Icons.arrow_back_ios: Icons.arrow_forward_ios,
      Icons.arrow_forward_ios: Icons.arrow_back_ios,
      Icons.chevron_left: Icons.chevron_right,
      Icons.chevron_right: Icons.chevron_left,
      Icons.keyboard_arrow_left: Icons.keyboard_arrow_right,
      Icons.keyboard_arrow_right: Icons.keyboard_arrow_left,
      Icons.navigate_before: Icons.navigate_next,
      Icons.navigate_next: Icons.navigate_before,
      Icons.first_page: Icons.last_page,
      Icons.last_page: Icons.first_page,
      Icons.undo: Icons.redo,
      Icons.redo: Icons.undo,
      Icons.format_align_left: Icons.format_align_right,
      Icons.format_align_right: Icons.format_align_left,
      Icons.format_indent_decrease: Icons.format_indent_increase,
      Icons.format_indent_increase: Icons.format_indent_decrease,
    };

    return rtlIconMap[icon] ?? icon;
  }

  /// Wraps a widget with appropriate directionality for error components
  static Widget wrapWithDirectionality(
    BuildContext context,
    Widget child, {
    TextDirection? textDirection,
  }) {
    final direction = textDirection ?? Directionality.of(context);
    
    return Directionality(
      textDirection: direction,
      child: child,
    );
  }

  /// Creates a text widget with RTL support
  static Widget createRTLText(
    BuildContext context,
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style,
      textAlign: getTextAlign(context, defaultAlign: textAlign),
      maxLines: maxLines,
      overflow: overflow,
      textDirection: Directionality.of(context),
    );
  }

  /// Creates a row with RTL-aware spacing and alignment
  static Widget createRTLRow(
    BuildContext context, {
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: getMainAxisAlignment(context, mainAxisAlignment),
      crossAxisAlignment: getCrossAxisAlignment(context, crossAxisAlignment),
      mainAxisSize: mainAxisSize,
      textDirection: Directionality.of(context),
      children: children,
    );
  }

  /// Creates a column with RTL-aware cross axis alignment
  static Widget createRTLColumn(
    BuildContext context, {
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: getCrossAxisAlignment(context, crossAxisAlignment),
      mainAxisSize: mainAxisSize,
      textDirection: Directionality.of(context),
      children: children,
    );
  }

  /// Creates a container with RTL-aware padding and alignment
  static Widget createRTLContainer(
    BuildContext context, {
    Widget? child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Alignment? alignment,
    Decoration? decoration,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment != null ? getAlignment(context, alignment) : null,
      decoration: decoration,
      child: child,
    );
  }

  /// Creates an icon button with RTL-aware icon
  static Widget createRTLIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    double? iconSize,
    Color? color,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(getIcon(context, icon)),
      onPressed: onPressed,
      iconSize: iconSize,
      color: color,
      tooltip: tooltip,
    );
  }

  /// Creates a list tile with RTL support
  static Widget createRTLListTile(
    BuildContext context, {
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      contentPadding: contentPadding,
    );
  }
}