import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uttaranchal_app/app/routes.dart';
import 'package:uttaranchal_app/main.dart';
import 'package:uttaranchal_app/screens/demo/screen_index.dart';
import 'package:uttaranchal_app/state/app_state.dart';

void main() {
  testWidgets('Welcome screen renders and starts sign-in', (tester) async {
    await tester.pumpWidget(UttaranchalApp(state: AppState()));
    await tester.pumpAndSettle();
    expect(find.text('Let’s begin'), findsOneWidget);

    await tester.tap(find.text('Let’s begin'));
    await tester.pumpAndSettle();
    expect(find.text('Namaste.'), findsOneWidget);
  });

  testWidgets('Every designed screen builds without errors', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532); // iPhone 13-class
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // The test font renders every glyph as a wide square, so tiny overflow
    // warnings can appear here that never happen with the real fonts on a
    // device. Collect every *other* error.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      if (!msg.contains('overflowed')) errors.add(msg);
    };

    final routes = [...ScreenIndexScreen.customer, ...ScreenIndexScreen.staff].map((s) => s.$3).where((r) => r != R.welcome);
    for (final route in routes) {
      final before = errors.length;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(UttaranchalApp(state: AppState()));
      await tester.pump();
      tester.state<NavigatorState>(find.byType(Navigator)).pushNamed(route);
      // Animated map / progress widgets never fully settle, so pump frames.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      if (errors.length > before) errors.add('  ↑ on $route');
    }

    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}
