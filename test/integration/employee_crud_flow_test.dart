import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/add_edit_employee_screen.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/employee_list_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('Full Employee Management CRUD Flow Integration Tests', () {
    testWidgets('CRUD Flow: List -> Add Employee -> Edit -> Soft Delete',
        (tester) async {
      final fakeEmpRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeEmpRepo);

      // Login sebagai Admin
      final fakeAuthRepo = FakeAuthRepository();
      fakeAuthRepo.users['admin@karyahr.com'] = User(
        id: 'admin-1',
        name: 'Admin Toko',
        employeeId: 'emp-admin',
        email: 'admin@karyahr.com',
        role: Role.admin,
        isActive: true,
        storeName: 'Toko Berkah Uji',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final authProvider = AuthProvider(repository: fakeAuthRepo);
      await authProvider.login('admin@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          empProvider: empProvider,
          routes: {
            AppConstants.kRouteAddEditEmployee: (_) =>
                const AddEditEmployeeScreen(),
          },
          child: const EmployeeListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi List Karyawan Awal (2 Karyawan)
      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('Ahmad Fauzi'), findsOneWidget);
      expect(empProvider.totalCount, 2);

      // 2. CREATE: Tambah Karyawan Baru via Provider
      final createSuccess = await empProvider.createEmployee({
        'nik': '3578240407960003',
        'name': 'Dewi Lestari',
        'email': 'dewi@karyahr.com',
        'phone': '081234567899',
        'department': 'Barista & F&B',
        'position': 'Head Barista',
        'role': 'EMPLOYEE',
        'join_date': '2026-01-10',
        'base_salary': 5000000,
      });

      expect(createSuccess, isTrue);
      final created = empProvider.employees.firstWhere((e) => e.name == 'Dewi Lestari');
      expect(created.name, 'Dewi Lestari');
      expect(empProvider.totalCount, 3);

      await tester.pumpAndSettle();
      expect(find.text('Dewi Lestari'), findsOneWidget);

      // 3. UPDATE: Edit Karyawan
      final updateSuccess = await empProvider.updateEmployee(
        created.id,
        {
          'position': 'Store Manager',
          'base_salary': 6500000,
        },
      );

      expect(updateSuccess, isTrue);
      final updated = empProvider.employees.firstWhere((e) => e.id == created.id);
      expect(updated.position, 'Store Manager');

      await tester.pumpAndSettle();
      expect(find.textContaining('Store Manager'), findsOneWidget);

      // 4. DELETE / DEACTIVATE: Soft delete karyawan
      final deleted = await empProvider.deleteEmployee(created.id);
      expect(deleted, isTrue);

      // Verifikasi status karyawan menjadi nonaktif
      expect(empProvider.inactiveCount, 1);
    });
  });
}
