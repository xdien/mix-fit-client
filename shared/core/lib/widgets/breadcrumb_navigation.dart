import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Represents a single breadcrumb item
class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

/// A breadcrumb navigation widget that shows the current navigation path
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final Color? textColor;
  final Color? separatorColor;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const BreadcrumbNavigation({
    Key? key,
    required this.items,
    this.textColor,
    this.separatorColor,
    this.fontSize = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveTextColor = textColor ?? theme.textTheme.bodyMedium?.color;
    final effectiveSeparatorColor = separatorColor ?? theme.dividerColor;

    return Container(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              children: _buildBreadcrumbItems(
                context,
                effectiveTextColor,
                effectiveSeparatorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(
    BuildContext context,
    Color? textColor,
    Color? separatorColor,
  ) {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;

      // Add breadcrumb item
      widgets.add(_buildBreadcrumbItem(
        context,
        item,
        isLast,
        textColor,
      ));

      // Add separator if not last item
      if (!isLast) {
        widgets.add(_buildSeparator(separatorColor));
      }
    }

    return widgets;
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    BreadcrumbItem item,
    bool isLast,
    Color? textColor,
  ) {
    final textStyle = TextStyle(
      fontSize: fontSize,
      color: isLast ? textColor : textColor?.withOpacity(0.7),
      fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: fontSize + 2,
            color: textStyle.color,
          ),
          const SizedBox(width: 4),
        ],
        Text(item.label, style: textStyle),
      ],
    );

    if (item.route != null && !isLast) {
      return InkWell(
        onTap: () => context.go(item.route!),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: content,
    );
  }

  Widget _buildSeparator(Color? separatorColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        size: fontSize + 2,
        color: separatorColor,
      ),
    );
  }
}

/// Helper class to build breadcrumbs for common navigation patterns
class BreadcrumbBuilder {
  /// Build breadcrumbs for vehicle repair entry screens
  static List<BreadcrumbItem> buildVehicleRepairEntryBreadcrumbs({
    required String currentScreen,
    String? vehicleId,
    String? licensePlate,
  }) {
    final breadcrumbs = <BreadcrumbItem>[
      const BreadcrumbItem(
        label: 'Home',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Vehicle Entries',
        route: '/vehicle-entries',
        icon: Icons.car_repair,
      ),
    ];

    switch (currentScreen) {
      case 'add':
        breadcrumbs.add(const BreadcrumbItem(
          label: 'Add New Entry',
          icon: Icons.add,
        ));
        break;
      case 'edit':
        breadcrumbs.add(BreadcrumbItem(
          label: 'Edit ${licensePlate ?? vehicleId ?? 'Entry'}',
          icon: Icons.edit,
        ));
        break;
      case 'history':
        breadcrumbs.add(BreadcrumbItem(
          label: 'History - ${licensePlate ?? vehicleId ?? 'Vehicle'}',
          icon: Icons.history,
        ));
        break;
      case 'list':
      default:
        // For list screen, don't add additional breadcrumb
        break;
    }

    return breadcrumbs;
  }

  /// Build breadcrumbs for customer management screens
  static List<BreadcrumbItem> buildCustomerManagementBreadcrumbs({
    required String currentScreen,
    String? customerId,
    String? customerName,
  }) {
    final breadcrumbs = <BreadcrumbItem>[
      const BreadcrumbItem(
        label: 'Home',
        route: '/home',
        icon: Icons.home,
      ),
      const BreadcrumbItem(
        label: 'Customers',
        route: '/customers',
        icon: Icons.people,
      ),
    ];

    switch (currentScreen) {
      case 'add':
        breadcrumbs.add(const BreadcrumbItem(
          label: 'Add New Customer',
          icon: Icons.person_add,
        ));
        break;
      case 'edit':
        breadcrumbs.add(BreadcrumbItem(
          label: 'Edit ${customerName ?? customerId ?? 'Customer'}',
          icon: Icons.edit,
        ));
        break;
      case 'list':
      default:
        // For list screen, don't add additional breadcrumb
        break;
    }

    return breadcrumbs;
  }
}