import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/auth/presentation/screens/login_screen.dart';
import 'package:flutter_hris_app/modules/auth/presentation/widgets/exception_container.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Menampilkan komponen login form dengan benar', (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi judul dan form input
      expect(find.text('Masuk ke Akun'), findsWidgets);
      expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('Toggle icon visibility mengubah status obscure kata sandi',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Default password obscure adalah true
      final passwordFieldFinder = find.byType(TextField).at(1);
      final passwordWidget = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordWidget.obscureText, isTrue);

      // Tap icon visibility toggle
      final toggleFinder = find.byIcon(Icons.visibility_off_outlined);
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Kata sandi sekarang terlihat
      final updatedPasswordWidget = tester.widget<TextField>(passwordFieldFinder);
      expect(updatedPasswordWidget.obscureText, isFalse);
    });

    testWidgets('Menampilkan pesan error ketika login gagal', (tester) async {
      final fakeRepo = FakeAuthRepository()
        ..shouldFail = true
        ..failMessage = 'Kredensial login tidak valid';
      final authProvider = AuthProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi input email dan kata sandi
      await tester.enterText(
        find.byType(TextField).at(0),
        'salah@karyahr.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'password123',
      );

      // Tap tombol masuk
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi pesan error muncul
      expect(find.byType(ExceptionContainer), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('Kredensial login tidak valid')),
        findsOneWidget,
      );
    });

    testWidgets('Login sukses sebagai OWNER mengarahkan ke Admin Shell',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeRepo);

      bool navigatedToAdminShell = false;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          routes: {
            AppConstants.kRouteAdminShell: (ctx) {
              navigatedToAdminShell = true;
              return const Scaffold(body: Text('Admin Shell Page'));
            },
          },
          child: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Isi email owner
      await tester.enterText(
        find.byType(TextField).at(0),
        'owner@karyahr.com',
      );
      await tester.enterText(
        find.byType(TextField).at(1),
        'PasswordOwner123!',
      );

      // Tap Masuk
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi navigasi ke Admin Shell berhasil
      expect(navigatedToAdminShell, isTrue);
      expect(find.text('Admin Shell Page'), findsOneWidget);
    });
  });
}
