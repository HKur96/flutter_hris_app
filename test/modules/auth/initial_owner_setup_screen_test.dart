import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/initial_owner_setup_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('InitialOwnerSetupScreen Widget Tests', () {
    testWidgets('Menampilkan komponen formulir pendaftaran owner awal',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const InitialOwnerSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inisialisasi Sistem'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(3)); // email, pass, confirm
      expect(find.text('Buat Akun OWNER'), findsOneWidget);
    });

    testWidgets(
        'Menampilkan validasi jika konfirmasi password tidak cocok dengan password',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const InitialOwnerSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi input dengan password tidak cocok
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'owner@karyahr.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'Password123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'PasswordBeda123!',
      );

      // Tap Buat Akun Owner
      await tester.tap(find.text('Buat Akun OWNER'));
      await tester.pumpAndSettle();

      expect(find.text('password tidak sesuai'), findsOneWidget);
    });

    testWidgets('Setup owner berhasil melakukan navigasi ke Admin Shell',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      bool navigatedToAdmin = false;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          routes: {
            AppConstants.kRouteAdminShell: (ctx) {
              navigatedToAdmin = true;
              return const Scaffold(body: Text('Admin Shell Page'));
            },
          },
          child: const InitialOwnerSetupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi input valid
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'owner@karyahr.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'PasswordRahasia123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'PasswordRahasia123!',
      );

      // Tap Buat Akun Owner
      await tester.tap(find.text('Buat Akun OWNER'));
      await tester.pumpAndSettle();

      expect(navigatedToAdmin, isTrue);
      expect(find.text('Admin Shell Page'), findsOneWidget);
    });
  });
}
