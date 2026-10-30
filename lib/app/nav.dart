import 'package:flutter/material.dart';

/// Marker argument: tells the router to use a soft cross-fade instead of a
/// push animation (used when switching bottom-nav tabs).
class TabSwitch {
  const TabSwitch();
}

const kTabSwitch = TabSwitch();

/// Switch to a bottom-navigation tab root, clearing the stack beneath it.
void goTab(BuildContext context, String route) {
  Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false, arguments: kTabSwitch);
}

/// Push a route.
Future<T?> go<T extends Object?>(BuildContext context, String route, {Object? args}) {
  return Navigator.of(context).pushNamed<T>(route, arguments: args);
}

/// Replace the current route.
void goReplace(BuildContext context, String route, {Object? args}) {
  Navigator.of(context).pushReplacementNamed(route, arguments: args);
}

/// Push [route] keeping only the very first route (tab root) beneath it.
void goFromRoot(BuildContext context, String route, {Object? args}) {
  Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => r.isFirst, arguments: args);
}
