// lib/main.dart
import 'package:babycare/child_profile_form_screen.dart';
import 'package:babycare/diaper_change_page_screen.dart';
import 'package:babycare/routes.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import 'go_router_refresh_stream.dart';
import 'login_screen.dart';
import 'home_screen.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        StreamProvider<User?>.value(
          value: FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    redirect: (BuildContext context, GoRouterState state) {
      print("go router");
      final user = context.read<User?>();
      final loggingIn = state.uri == Routes.login;

      if (user == null) {
        return Routes.login;
      }

      if (loggingIn) {
        return Routes.home;
      }

      print("redirect");
      print(state.path);
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => LoginScreen(),
      ),
      GoRoute(
        path: Routes.home,
        builder: (context, state) => HomeScreen(user: context.read<User?>(),),
      ),
      GoRoute(
        path: Routes.newChild,
        builder: (context, state) => ChildProfileForm(),
      ),
      GoRoute(
        path: Routes.child,
        builder: (context, state) => ChildProfileForm(id: state.pathParameters["id"],),
      ),
      GoRoute(
        path: Routes.child_diaper_change,
        builder: (context, state) => DiaperChangePageScreen(id: state.pathParameters["id"],),
      ),
    ],
    initialLocation: Routes.home,
    observers: [
      FirebaseAnalyticsObserver(analytics: analytics),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Baby Care',
      theme: ThemeData(
        scaffoldBackgroundColor: Color.fromARGB(255, 244, 244, 244),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromARGB(255, 97, 97, 97),
          foregroundColor: Colors.white,
        )
      ),
      routerConfig: _router,
    );
  }
}
