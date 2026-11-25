import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/employee_list_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('EmployeeListScreen Widget Tests', () {
    testWidgets('Menampilkan daftar karyawan dari provider dengan benar',
        (tester) async {
      final fakeEmpRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeEmpRepo);

      final fakeAuthRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          empProvider: empProvider,
          child: const EmployeeListScreen(showAppBar: true),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi daftar karyawan muncul
      expect(find.text('Data Karyawan'), findsOneWidget);
      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('Ahmad Fauzi'), findsOneWidget);
    });

    testWidgets('Fitur pencarian memfilter karyawan sesuai query teks',
        (tester) async {
      final fakeEmpRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeEmpRepo);

      final fakeAuthRepo = FakeAuthRepository();
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          empProvider: empProvider,
          child: const EmployeeListScreen(showAppBar: true),
        ),
      );
      await tester.pumpAndSettle();

      // Masukkan kata kunci pencarian
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Siti');
      await tester.pumpAndSettle();

      // Siti Aminah tetap ada, Ahmad Fauzi tersaring
      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('Ahmad Fauzi'), findsNothing);
    });

    testWidgets(
        'Admin/Owner melihat Floating Action Button untuk menambah karyawan',
        (tester) async {
      final fakeEmpRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeEmpRepo);

      // Setup user login sebagai Admin
      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.users['admin@karyahr.com'] = User(
        id: 'admin-1',
        name: 'Admin Utama',
        employeeId: 'emp-admin',
        email: 'admin@karyahr.com',
        role: Role.admin,
        isActive: true,
        storeName: 'Toko Uji',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final authProvider = AuthProvider(repository: fakeAuthRepo);
      await authProvider.login('admin@karyahr.com', 'password');

      bool navigatedToAdd = false;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          empProvider: empProvider,
          routes: {
            AppConstants.kRouteAddEditEmployee: (_) {
              navigatedToAdd = true;
              return const Scaffold(body: Text('Add Employee Page'));
            },
          },
          child: const EmployeeListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Temukan FAB atau tombol tambah karyawan
      final addIconFinder = find.byIcon(Icons.add);
      expect(addIconFinder, findsOneWidget);

      await tester.tap(addIconFinder);
      await tester.pumpAndSettle();

      expect(navigatedToAdd, isTrue);
    });
  });
}
