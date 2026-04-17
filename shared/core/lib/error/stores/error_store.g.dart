// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_store.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$ErrorStore on _ErrorStore, Store {
  Computed<bool>? _$hasErrorsComputed;

  @override
  bool get hasErrors => (_$hasErrorsComputed ??=
          Computed<bool>(() => super.hasErrors, name: '_ErrorStore.hasErrors'))
      .value;
  Computed<bool>? _$hasActiveErrorsComputed;

  @override
  bool get hasActiveErrors =>
      (_$hasActiveErrorsComputed ??= Computed<bool>(() => super.hasActiveErrors,
              name: '_ErrorStore.hasActiveErrors'))
          .value;
  Computed<int>? _$errorCountComputed;

  @override
  int get errorCount => (_$errorCountComputed ??=
          Computed<int>(() => super.errorCount, name: '_ErrorStore.errorCount'))
      .value;
  Computed<AppError?>? _$priorityErrorComputed;

  @override
  AppError? get priorityError => (_$priorityErrorComputed ??=
          Computed<AppError?>(() => super.priorityError,
              name: '_ErrorStore.priorityError'))
      .value;
  Computed<bool>? _$shouldShowErrorBarComputed;

  @override
  bool get shouldShowErrorBar => (_$shouldShowErrorBarComputed ??=
          Computed<bool>(() => super.shouldShowErrorBar,
              name: '_ErrorStore.shouldShowErrorBar'))
      .value;
  Computed<bool>? _$shouldShowOfflineIndicatorComputed;

  @override
  bool get shouldShowOfflineIndicator =>
      (_$shouldShowOfflineIndicatorComputed ??= Computed<bool>(
              () => super.shouldShowOfflineIndicator,
              name: '_ErrorStore.shouldShowOfflineIndicator'))
          .value;
  Computed<bool>? _$hasNetworkIssuesComputed;

  @override
  bool get hasNetworkIssues => (_$hasNetworkIssuesComputed ??= Computed<bool>(
          () => super.hasNetworkIssues,
          name: '_ErrorStore.hasNetworkIssues'))
      .value;
  Computed<String>? _$errorBarTitleComputed;

  @override
  String get errorBarTitle =>
      (_$errorBarTitleComputed ??= Computed<String>(() => super.errorBarTitle,
              name: '_ErrorStore.errorBarTitle'))
          .value;
  Computed<String>? _$networkStatusTextComputed;

  @override
  String get networkStatusText => (_$networkStatusTextComputed ??=
          Computed<String>(() => super.networkStatusText,
              name: '_ErrorStore.networkStatusText'))
      .value;
  Computed<bool>? _$canRetryCurrentErrorComputed;

  @override
  bool get canRetryCurrentError => (_$canRetryCurrentErrorComputed ??=
          Computed<bool>(() => super.canRetryCurrentError,
              name: '_ErrorStore.canRetryCurrentError'))
      .value;
  Computed<bool>? _$shouldAutoHideCurrentErrorComputed;

  @override
  bool get shouldAutoHideCurrentError =>
      (_$shouldAutoHideCurrentErrorComputed ??= Computed<bool>(
              () => super.shouldAutoHideCurrentError,
              name: '_ErrorStore.shouldAutoHideCurrentError'))
          .value;

  late final _$activeErrorsAtom =
      Atom(name: '_ErrorStore.activeErrors', context: context);

  @override
  ObservableList<AppError> get activeErrors {
    _$activeErrorsAtom.reportRead();
    return super.activeErrors;
  }

  @override
  set activeErrors(ObservableList<AppError> value) {
    _$activeErrorsAtom.reportWrite(value, super.activeErrors, () {
      super.activeErrors = value;
    });
  }

  late final _$currentErrorAtom =
      Atom(name: '_ErrorStore.currentError', context: context);

  @override
  AppError? get currentError {
    _$currentErrorAtom.reportRead();
    return super.currentError;
  }

  @override
  set currentError(AppError? value) {
    _$currentErrorAtom.reportWrite(value, super.currentError, () {
      super.currentError = value;
    });
  }

  late final _$isOfflineAtom =
      Atom(name: '_ErrorStore.isOffline', context: context);

  @override
  bool get isOffline {
    _$isOfflineAtom.reportRead();
    return super.isOffline;
  }

  @override
  set isOffline(bool value) {
    _$isOfflineAtom.reportWrite(value, super.isOffline, () {
      super.isOffline = value;
    });
  }

  late final _$networkQualityAtom =
      Atom(name: '_ErrorStore.networkQuality', context: context);

  @override
  NetworkQuality get networkQuality {
    _$networkQualityAtom.reportRead();
    return super.networkQuality;
  }

  @override
  set networkQuality(NetworkQuality value) {
    _$networkQualityAtom.reportWrite(value, super.networkQuality, () {
      super.networkQuality = value;
    });
  }

  late final _$networkStatusAtom =
      Atom(name: '_ErrorStore.networkStatus', context: context);

  @override
  NetworkStatus? get networkStatus {
    _$networkStatusAtom.reportRead();
    return super.networkStatus;
  }

  @override
  set networkStatus(NetworkStatus? value) {
    _$networkStatusAtom.reportWrite(value, super.networkStatus, () {
      super.networkStatus = value;
    });
  }

  late final _$isErrorBarVisibleAtom =
      Atom(name: '_ErrorStore.isErrorBarVisible', context: context);

  @override
  bool get isErrorBarVisible {
    _$isErrorBarVisibleAtom.reportRead();
    return super.isErrorBarVisible;
  }

  @override
  set isErrorBarVisible(bool value) {
    _$isErrorBarVisibleAtom.reportWrite(value, super.isErrorBarVisible, () {
      super.isErrorBarVisible = value;
    });
  }

  late final _$isErrorBarMinimizedAtom =
      Atom(name: '_ErrorStore.isErrorBarMinimized', context: context);

  @override
  bool get isErrorBarMinimized {
    _$isErrorBarMinimizedAtom.reportRead();
    return super.isErrorBarMinimized;
  }

  @override
  set isErrorBarMinimized(bool value) {
    _$isErrorBarMinimizedAtom.reportWrite(value, super.isErrorBarMinimized, () {
      super.isErrorBarMinimized = value;
    });
  }

  late final _$showErrorDetailsFlagAtom =
      Atom(name: '_ErrorStore.showErrorDetailsFlag', context: context);

  @override
  bool get showErrorDetailsFlag {
    _$showErrorDetailsFlagAtom.reportRead();
    return super.showErrorDetailsFlag;
  }

  @override
  set showErrorDetailsFlag(bool value) {
    _$showErrorDetailsFlagAtom.reportWrite(value, super.showErrorDetailsFlag,
        () {
      super.showErrorDetailsFlag = value;
    });
  }

  late final _$autoHideNonCriticalErrorsAtom =
      Atom(name: '_ErrorStore.autoHideNonCriticalErrors', context: context);

  @override
  bool get autoHideNonCriticalErrors {
    _$autoHideNonCriticalErrorsAtom.reportRead();
    return super.autoHideNonCriticalErrors;
  }

  @override
  set autoHideNonCriticalErrors(bool value) {
    _$autoHideNonCriticalErrorsAtom
        .reportWrite(value, super.autoHideNonCriticalErrors, () {
      super.autoHideNonCriticalErrors = value;
    });
  }

  late final _$autoHideDurationAtom =
      Atom(name: '_ErrorStore.autoHideDuration', context: context);

  @override
  Duration get autoHideDuration {
    _$autoHideDurationAtom.reportRead();
    return super.autoHideDuration;
  }

  @override
  set autoHideDuration(Duration value) {
    _$autoHideDurationAtom.reportWrite(value, super.autoHideDuration, () {
      super.autoHideDuration = value;
    });
  }

  late final _$showNetworkStatusInBarAtom =
      Atom(name: '_ErrorStore.showNetworkStatusInBar', context: context);

  @override
  bool get showNetworkStatusInBar {
    _$showNetworkStatusInBarAtom.reportRead();
    return super.showNetworkStatusInBar;
  }

  @override
  set showNetworkStatusInBar(bool value) {
    _$showNetworkStatusInBarAtom
        .reportWrite(value, super.showNetworkStatusInBar, () {
      super.showNetworkStatusInBar = value;
    });
  }

  late final _$_ErrorStoreActionController =
      ActionController(name: '_ErrorStore', context: context);

  @override
  void addError(AppError error) {
    final _$actionInfo =
        _$_ErrorStoreActionController.startAction(name: '_ErrorStore.addError');
    try {
      return super.addError(error);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeError(String errorId) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.removeError');
    try {
      return super.removeError(errorId);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearAllErrors() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.clearAllErrors');
    try {
      return super.clearAllErrors();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearErrorsByType(String errorType) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.clearErrorsByType');
    try {
      return super.clearErrorsByType(errorType);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showErrorBar() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.showErrorBar');
    try {
      return super.showErrorBar();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideErrorBar() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.hideErrorBar');
    try {
      return super.hideErrorBar();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void minimizeErrorBar() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.minimizeErrorBar');
    try {
      return super.minimizeErrorBar();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void expandErrorBar() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.expandErrorBar');
    try {
      return super.expandErrorBar();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleErrorBarMinimized() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.toggleErrorBarMinimized');
    try {
      return super.toggleErrorBarMinimized();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void showErrorDetails() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.showErrorDetails');
    try {
      return super.showErrorDetails();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void hideErrorDetails() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.hideErrorDetails');
    try {
      return super.hideErrorDetails();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void toggleErrorDetails() {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.toggleErrorDetails');
    try {
      return super.toggleErrorDetails();
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAutoHideNonCriticalErrors(bool value) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.setAutoHideNonCriticalErrors');
    try {
      return super.setAutoHideNonCriticalErrors(value);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAutoHideDuration(Duration duration) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.setAutoHideDuration');
    try {
      return super.setAutoHideDuration(duration);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setShowNetworkStatusInBar(bool value) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore.setShowNetworkStatusInBar');
    try {
      return super.setShowNetworkStatusInBar(value);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateNetworkStatus(NetworkStatus status) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore._updateNetworkStatus');
    try {
      return super._updateNetworkStatus(status);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateActiveErrors(List<AppError> errors) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore._updateActiveErrors');
    try {
      return super._updateActiveErrors(errors);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void _updateCurrentError(AppError? error) {
    final _$actionInfo = _$_ErrorStoreActionController.startAction(
        name: '_ErrorStore._updateCurrentError');
    try {
      return super._updateCurrentError(error);
    } finally {
      _$_ErrorStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
activeErrors: ${activeErrors},
currentError: ${currentError},
isOffline: ${isOffline},
networkQuality: ${networkQuality},
networkStatus: ${networkStatus},
isErrorBarVisible: ${isErrorBarVisible},
isErrorBarMinimized: ${isErrorBarMinimized},
showErrorDetailsFlag: ${showErrorDetailsFlag},
autoHideNonCriticalErrors: ${autoHideNonCriticalErrors},
autoHideDuration: ${autoHideDuration},
showNetworkStatusInBar: ${showNetworkStatusInBar},
hasErrors: ${hasErrors},
hasActiveErrors: ${hasActiveErrors},
errorCount: ${errorCount},
priorityError: ${priorityError},
shouldShowErrorBar: ${shouldShowErrorBar},
shouldShowOfflineIndicator: ${shouldShowOfflineIndicator},
hasNetworkIssues: ${hasNetworkIssues},
errorBarTitle: ${errorBarTitle},
networkStatusText: ${networkStatusText},
canRetryCurrentError: ${canRetryCurrentError},
shouldAutoHideCurrentError: ${shouldAutoHideCurrentError}
    ''';
  }
}
