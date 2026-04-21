import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T>(Widget page) {
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) {
      return Future<T?>.value();
    }

    return navigator.push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }
}
