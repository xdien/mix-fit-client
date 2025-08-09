import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:core/error/stores/error_store.dart';
import 'package:core/error/widgets/error_status_bar_widget.dart';

/// Custom scaffold that includes the error status bar integration
class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget? drawer;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool primary;
  final DragStartBehavior drawerDragStartBehavior;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Color? drawerScrimColor;
  final double? drawerEdgeDragWidth;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final String? restorationId;

  const AppScaffold({
    Key? key,
    required this.body,
    this.drawer,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.primary = true,
    this.drawerDragStartBehavior = DragStartBehavior.start,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.drawerScrimColor,
    this.drawerEdgeDragWidth,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.restorationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final errorStore = GetIt.instance<ErrorStore>();

    return Observer(
      builder: (context) {
        return Scaffold(
          appBar: _buildAppBarWithErrorBar(context, errorStore),
          drawer: drawer,
          body: body,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomNavigationBar: bottomNavigationBar,
          bottomSheet: bottomSheet,
          backgroundColor: backgroundColor,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          primary: primary,
          drawerDragStartBehavior: drawerDragStartBehavior,
          extendBody: extendBody,
          extendBodyBehindAppBar: extendBodyBehindAppBar,
          drawerScrimColor: drawerScrimColor,
          drawerEdgeDragWidth: drawerEdgeDragWidth,
          drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
          endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
          restorationId: restorationId,
        );
      },
    );
  }

  PreferredSizeWidget? _buildAppBarWithErrorBar(BuildContext context, ErrorStore errorStore) {
    // If there's an existing appBar, we need to combine it with the error bar
    if (appBar != null) {
      return _CombinedAppBar(
        originalAppBar: appBar!,
        errorStore: errorStore,
      );
    }

    // If there's no existing appBar but we need to show the error bar, create a minimal one
    if (errorStore.shouldShowErrorBar) {
      return _ErrorOnlyAppBar(errorStore: errorStore);
    }

    // No appBar needed
    return null;
  }
}

/// Custom AppBar that combines the original AppBar with the error status bar
class _CombinedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PreferredSizeWidget originalAppBar;
  final ErrorStore errorStore;

  const _CombinedAppBar({
    required this.originalAppBar,
    required this.errorStore,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show error status bar if needed
            if (errorStore.shouldShowErrorBar)
              ErrorStatusBarWidget(),
            // Original AppBar
            originalAppBar,
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize {
    final originalSize = originalAppBar.preferredSize;
    final errorBarHeight = errorStore.shouldShowErrorBar 
        ? (errorStore.isErrorBarMinimized ? 32.0 : 56.0) 
        : 0.0;
    
    return Size(
      originalSize.width,
      originalSize.height + errorBarHeight,
    );
  }
}

/// Minimal AppBar that only shows the error status bar
class _ErrorOnlyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ErrorStore errorStore;

  const _ErrorOnlyAppBar({
    required this.errorStore,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (!errorStore.shouldShowErrorBar) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: ErrorStatusBarWidget(),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize {
    final errorBarHeight = errorStore.shouldShowErrorBar 
        ? (errorStore.isErrorBarMinimized ? 32.0 : 56.0) 
        : 0.0;
    
    return Size(double.infinity, errorBarHeight);
  }
}