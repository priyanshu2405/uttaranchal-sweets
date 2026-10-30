import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/router.dart';
import 'app/routes.dart';
import 'app/theme.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlay);
  runApp(UttaranchalApp(state: AppState()));
}

class UttaranchalApp extends StatelessWidget {
  final AppState state;
  const UttaranchalApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Uttaranchal Dairy & Sweets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: R.welcome,
        onGenerateRoute: AppRouter.onGenerateRoute,
        // Keep the carefully-set type legible but stop very large system
        // font sizes from breaking the demo layouts.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(minScaleFactor: 0.9, maxScaleFactor: 1.15)),
            child: child!,
          );
        },
      ),
    );
  }
}
