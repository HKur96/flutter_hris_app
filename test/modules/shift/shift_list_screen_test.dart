import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/shift_list_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('ShiftListScreen Widget Tests', () {
    testWidgets('Menampilkan daftar template shift dengan durasi dan badge',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      final fakeAuthRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          shiftProvider: shiftProvider,
          child: const ShiftListScreen(showAppBar: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi template shift muncul
      expect(find.text('Master Shift'), findsOneWidget);
      expect(find.text('Shift Pagi'), findsOneWidget);
      expect(find.text('Shift Siang'), findsOneWidget);
      expect(find.text('Shift Malam'), findsOneWidget);

      // Verifikasi badge lintas hari / overnight
      expect(find.text('Lintas Malam'), findsOneWidget);
    });

    testWidgets('Pencarian shift menyaring daftar sesuai nama shift',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      final fakeAuthRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          shiftProvider: shiftProvider,
          child: const ShiftListScreen(showAppBar: true),
        ),
      );
      await tester.pumpAndSettle();

      // Input pencarian 'Malam'
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Malam');
      await tester.pumpAndSettle();

      expect(find.text('Shift Malam'), findsOneWidget);
      expect(find.text('Shift Pagi'), findsNothing);
      expect(find.text('Shift Siang'), findsNothing);
    });

    testWidgets('Admin/Owner melihat tombol Tambah Shift di AppBar',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.users['admin@karyahr.com'] = User(
        id: 'admin-1',
        name: 'Admin',
        employeeId: 'emp-admin',
        email: 'admin@karyahr.com',
        role: Role.admin,
        isActive: true,
        storeName: 'Toko',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final authProvider = AuthProvider(repository: fakeAuthRepo);
      await authProvider.login('admin@karyahr.com', 'pass');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          shiftProvider: shiftProvider,
          child: const ShiftListScreen(showAppBar: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Shift'), findsOneWidget);
    });
  });
}
