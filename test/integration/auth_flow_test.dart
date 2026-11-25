import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/initial_owner_setup_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/login_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('Full Auth Flow Integration Tests', () {
    testWidgets(
        'Flow 1: First-time install -> Needs Setup -> Initial Owner Setup -> Admin Shell',
        (tester) async {
      final fakeRepo = FakeAuthRepository(
        initialSetupStatus: const SetupStatus(
          needsSetup: true,
          hasOwner: false,
          totalUsers: 0,
          activeOwners: 0,
          message: 'Setup is required',
        ),
      );
      final authProvider = AuthProvider(repository: fakeRepo);

      // Simulasikan status setup
      final status = await authProvider.checkSetupStatus(showLoadingDialog: false);
      expect(status?.needsSetup, isTrue);

      String currentRoute = AppConstants.kRouteInitOwnerSetup;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          routes: {
            AppConstants.kRouteAdminShell: (_) {
              currentRoute = AppConstants.kRouteAdminShell;
              return const Scaffold(body: Text('Admin Shell Screen'));
            },
            AppConstants.kRouteLogin: (_) {
              currentRoute = AppConstants.kRouteLogin;
              return const LoginScreen();
            },
          },
          child: const InitialOwnerSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan layar Initial Owner Setup tampil
      expect(find.text('Inisialisasi Sistem'), findsOneWidget);

      // Isi form pembuatan akun owner
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'owner@company.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'SecurePassword123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'SecurePassword123!',
      );

      // Submit
      await tester.tap(find.text('Buat Akun OWNER'));
      await tester.pumpAndSettle();

      // Verifikasi berhasil dibuat dan navigasi ke Admin Shell
      expect(currentRoute, AppConstants.kRouteAdminShell);
      expect(find.text('Admin Shell Screen'), findsOneWidget);
      expect(authProvider.user?.email, 'owner@company.com');
      expect(authProvider.user?.canManage, isTrue);
    });

    testWidgets(
        'Flow 2: Normal login -> Employee login -> Navigates to Employee Shell',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      String currentRoute = AppConstants.kRouteLogin;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          routes: {
            AppConstants.kRouteEmployeeShell: (_) {
              currentRoute = AppConstants.kRouteEmployeeShell;
              return const Scaffold(body: Text('Employee Shell Screen'));
            },
            AppConstants.kRouteAdminShell: (_) {
              currentRoute = AppConstants.kRouteAdminShell;
              return const Scaffold(body: Text('Admin Shell Screen'));
            },
          },
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Input kredensial karyawan biasa
      await tester.enterText(
        find.byType(TextField).at(0),
        'budi.santoso@karyahr.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'PasswordBudi123!',
      );

      // Submit
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi navigasi ke Employee Shell
      expect(currentRoute, AppConstants.kRouteEmployeeShell);
      expect(find.text('Employee Shell Screen'), findsOneWidget);
      expect(authProvider.user?.canManage, isFalse);
    });
  });
}
