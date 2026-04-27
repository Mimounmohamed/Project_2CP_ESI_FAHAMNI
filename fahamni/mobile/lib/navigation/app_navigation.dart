import 'package:flutter/material.dart';

final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> push<T>(Widget page) {
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) {
      return Future<T?>.value();
    }

    return navigator.push<T>(buildFadeRoute<T>(page));
  }

  Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    final NavigatorState? navigator = navigatorKey.currentState;
    if (navigator == null) {
      return Future<T?>.value();
    }

    return navigator.pushReplacement<T, TO>(
      buildFadeRoute<T>(page),
      result: result,
    );
  }
}

PageRouteBuilder<T> buildFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
