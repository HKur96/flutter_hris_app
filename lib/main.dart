import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/deployment_config_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/initial_owner_setup_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/login_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/admin_routes.dart';
import 'core/config/employee_routes.dart';
import 'core/theme/app_theme.dart';
import 'modules/dashboard/presentation/screens/dashboard_screen.dart';
import 'modules/shell/presentation/admin_shell.dart';
import 'modules/shell/presentation/employee_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await _initializeSupabase();
  runApp(RequestsInspector(enabled: kDebugMode, child: const MyApp()));
}

Future<void> _initializeSupabase() async {
  await Supabase.initialize(
    url: const String.fromEnvironment('url'),
    publishableKey: const String.fromEnvironment('publishable_key'),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'KaryaHR Mobile',
        debugShowCheckedModeBanner: false,
        navigatorKey: gNavigatorKey,
        theme: AppTheme.lightTheme,
        locale: const Locale('in', 'ID'),
        supportedLocales: const [Locale('in', 'ID')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        // Mengarahkan rute awal aplikasi ke SplashScreen
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/deployment-config': (context) => const DeploymentConfigScreen(),
          '/initial-owner-setup': (context) => const InitialOwnerSetupScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/employee/shell': (context) => const EmployeeShell(),
          '/admin/shell': (context) => const AdminShell(),
          ...AdminRoutes.routes,
          ...EmployeeRoutes.routes,
        },
      ),
    );
  }
}
