import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/global.dart';
import 'package:flutter_hris_app/modules/attendance/data/repository/attendance_repository_impl.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/initial_owner_setup_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/login_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/splash_screen.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/add_edit_employee_screen.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_assignment_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
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
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeManagementProvider()),
        ChangeNotifierProvider(create: (_) => ShiftProvider()),
        ChangeNotifierProvider(create: (_) => ShiftAssignmentProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              AttendanceProvider(repository: AttendanceRepositoryImpl()),
        ),
      ],
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
        initialRoute: AppConstants.kRouteRoot,
        routes: {
          AppConstants.kRouteRoot: (context) => const SplashScreen(),
          AppConstants.kRouteSplash: (context) => const SplashScreen(),
          AppConstants.kRouteLogin: (context) => const LoginScreen(),
          AppConstants.kRouteInitOwnerSetup: (context) =>
              const InitialOwnerSetupScreen(),
          AppConstants.kRouteDashboard: (context) =>
              const DashboardScreen(showAppBar: true),
          AppConstants.kRouteEmployeeShell: (context) => const EmployeeShell(),
          AppConstants.kRouteAdminShell: (context) => const AdminShell(),
          AppConstants.kRouteAddEditEmployee: (context) =>
              const AddEditEmployeeScreen(),
          ...AdminRoutes.routes,
          ...EmployeeRoutes.routes,
        },
      ),
    );
  }
}
