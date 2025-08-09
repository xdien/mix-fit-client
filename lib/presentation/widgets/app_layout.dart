import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';

/// Main app layout that handles error status bar positioning and responsive design
class AppLayout extends StatelessWidget {
  final Widget child;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;

  const AppLayout({
    Key? key,
    required this.child,
    this.drawer,
    this.appBar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();

    return Observer(
      builder: (context) {
        return Scaffold(
          appBar: appBar,
          drawer: drawer,
          body: Column(
            children: [
              // Error status bar at the top
              if (errorStore.shouldShowErrorBar)
                _ErrorStatusBarContainer(errorStore: errorStore),
              
              // Main content
              Expanded(child: child),
            ],
          ),
        );
      },
    );
  }
}

/// Container for the error status bar with proper styling and animations
class _ErrorStatusBarContainer extends StatelessWidget {
  final ErrorStore errorStore;

  const _ErrorStatusBarContainer({
    required this.errorStore,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: errorStore.isErrorBarMinimized ? 32.0 : 56.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _getErrorBarBackgroundColor(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: ErrorStatusBarWidget(errorStore: errorStore),
          ),
        );
      },
    );
  }

  Color _getErrorBarBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    
    if (errorStore.hasErrors && errorStore.priorityError != null) {
      final error = errorStore.priorityError!;
      switch (error.severity.name) {
        case 'critical':
          return Colors.red.shade100;
        case 'error':
          return Colors.orange.shade100;
        case 'warning':
          return Colors.yellow.shade100;
        case 'info':
          return Colors.blue.shade100;
        default:
          return theme.colorScheme.errorContainer;
      }
    }
    
    if (errorStore.isOffline) {
      return Colors.grey.shade200;
    }
    
    return theme.colorScheme.surface;
  }
}

/// Responsive layout helper for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    Key? key,
    required this.mobile,
    this.tablet,
    this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= 768) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Extension to help with responsive design
extension ResponsiveExtension on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < 768;
  bool get isTablet => MediaQuery.of(this).size.width >= 768 && MediaQuery.of(this).size.width < 1200;
  bool get isDesktop => MediaQuery.of(this).size.width >= 1200;
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}