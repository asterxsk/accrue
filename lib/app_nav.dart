import 'package:flutter/material.dart';

/// Which top-level tab the shell is showing.
///
/// Lives above the navigator so a pushed screen can return the user to Today
/// after deleting the habit it was showing.
class AppNav extends ChangeNotifier {
  AppNav([this._index = 0]);

  int _index;
  int get index => _index;

  void select(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}

class AppNavScope extends InheritedNotifier<AppNav> {
  const AppNavScope({
    super.key,
    required AppNav nav,
    required super.child,
  }) : super(notifier: nav);

  static AppNav of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppNavScope>();
    assert(scope != null, 'AppNavScope is missing above this widget');
    return scope!.notifier!;
  }
}
