import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/employee_management/domain/entity/employee_profile.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/provider/employee_management_provider.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/add_edit_employee_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('AddEditEmployeeScreen Widget Tests', () {
    testWidgets('Mode Tambah: Menampilkan form kosong dengan tombol Tambah Karyawan',
        (tester) async {
      final fakeRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          empProvider: empProvider,
          child: const AddEditEmployeeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Karyawan Baru'), findsOneWidget);
      expect(find.text('IDENTITAS & KONTAK'), findsOneWidget);
      expect(find.text('POSISI & GAJI POKOK'), findsOneWidget);
      expect(find.text('Simpan Karyawan'), findsOneWidget);
    });

    testWidgets('Mode Edit: Mengisi form dengan data karyawan yang akan diedit',
        (tester) async {
      final fakeRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeRepo);

      final employee = EmployeeProfile(
        id: 'emp-edit-1',
        nik: '3578123456780001',
        name: 'Rudi Hartono',
        email: 'rudi@karyahr.com',
        phone: '081299998888',
        department: 'Gudang',
        position: 'Supervisor',
        role: 'EMPLOYEE',
        joinDate: DateTime(2025, 3, 1),
        employmentStatus: 'ACTIVE',
        baseSalary: 6000000,
        createdAt: DateTime(2025, 3, 1),
        updatedAt: DateTime(2025, 3, 1),
      );

      await tester.pumpWidget(
        createTestApp(
          empProvider: empProvider,
          child: AddEditEmployeeScreen(employeeToEdit: employee),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Karyawan'), findsOneWidget);
      expect(find.text('Rudi Hartono'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
    });

    testWidgets('Validasi form memblokir submit jika NIK / Nama kosong',
        (tester) async {
      final fakeRepo = FakeEmployeeManagementRepository();
      final empProvider = EmployeeManagementProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          empProvider: empProvider,
          child: const AddEditEmployeeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Submit form tanpa isi input
      await tester.tap(find.text('Simpan Karyawan'));
      await tester.pumpAndSettle();

      // Form validation error muncul
      expect(find.textContaining('wajib diisi'), findsWidgets);
    });
  });
}
