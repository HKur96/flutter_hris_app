import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/core/components/app_navigation_bar.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:flutter_hris_app/modules/auth/presentation/provider/auth_provider.dart';
import 'package:flutter_hris_app/modules/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:flutter_hris_app/modules/employee_management/presentation/screens/employee_list_screen.dart';
import 'package:flutter_hris_app/modules/shell/presentation/admin_shell.dart';
import 'package:flutter_hris_app/modules/shell/presentation/widgets/profile_view.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('AdminProfileView & NavigationBar Widget Tests', () {
    testWidgets('AppBottomNavBar untuk admin/owner memiliki 6 tab termasuk Profil',
        (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: selectedTab,
              onTap: (index) => selectedTab = index,
              currentUser: User(
                id: 'admin-1',
                name: 'Admin Utama',
                employeeId: 'emp-admin',
                email: 'admin@karyahr.com',
                role: Role.admin,
                isActive: true,
                storeName: 'Sixbox Roastery',
                isShift: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Karyawan'), findsOneWidget);
      expect(find.text('Shift'), findsOneWidget);
      expect(find.text('Approval'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap tab Profil
      await tester.tap(find.text('Profil'));
      expect(selectedTab, 5);
    });

    testWidgets(
        'AppBottomNavBar untuk admin/owner dengan isShift false hanya memiliki 5 tab (tanpa Shift)',
        (tester) async {
      int selectedTab = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: selectedTab,
              onTap: (index) => selectedTab = index,
              currentUser: User(
                id: 'admin-1',
                name: 'Admin Utama',
                employeeId: 'emp-admin',
                email: 'admin@karyahr.com',
                role: Role.admin,
                isActive: true,
                storeName: 'Sixbox Roastery',
                isShift: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Karyawan'), findsOneWidget);
      expect(find.text('Shift'), findsNothing); // Shift tidak muncul
      expect(find.text('Approval'), findsOneWidget);
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);

      // Tap tab Profil (indeks 4 saat isShift false)
      await tester.tap(find.text('Profil'));
      expect(selectedTab, 4);
    });

    testWidgets('Menampilkan komponen identitas owner dan pengaturan nama toko sesuai Stitch',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['owner@karyahr.com'] = User(
        id: 'owner-1',
        name: 'Owner Utama',
        employeeId: 'emp-owner',
        email: 'owner@karyahr.com',
        role: Role.owner,
        isActive: true,
        storeName: 'Sixbox Roastery',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('owner@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi identitas dan badge
      expect(find.text('Sixbox Roastery'), findsWidgets);
      expect(find.text('owner@karyahr.com'), findsWidgets);
      expect(find.text('OWNER'), findsOneWidget);
      expect(find.text('INFORMASI AKUN'), findsOneWidget);
      expect(find.text('INFORMASI PERUSAHAAN'), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
      expect(find.text('KEAMANAN & AUTENTIKASI'), findsOneWidget);
      expect(find.text('Keluar dari Aplikasi'), findsOneWidget);
    });

    testWidgets('Ubah nama toko via tombol Ubah memperbarui data storeName di AuthProvider',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['owner@karyahr.com'] = User(
        id: 'owner-1',
        name: 'Owner Utama',
        employeeId: 'emp-owner',
        email: 'owner@karyahr.com',
        role: Role.owner,
        isActive: true,
        storeName: 'Toko Lama',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('owner@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ubah nama toko via modal Bottom Sheet (Stitch Viewport 4)
      await tester.ensureVisible(find.text('Ubah'));
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      final nameFieldFinder = find.widgetWithText(TextFormField, 'Masukkan nama entitas usaha');
      await tester.enterText(nameFieldFinder, 'Sixbox Cabang Surabaya');
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verifikasi nama toko terupdate di provider
      expect(authProvider.user?.storeName, 'Sixbox Cabang Surabaya');
      expect(find.textContaining('Sixbox Cabang Surabaya'), findsWidgets);
    });

    testWidgets('Toggle AppShiftSlider di bottom sheet memperbarui isShift di AuthProvider dan UI',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['owner@karyahr.com'] = User(
        id: 'owner-1',
        name: 'Owner Utama',
        employeeId: 'emp-owner',
        email: 'owner@karyahr.com',
        role: Role.owner,
        isActive: true,
        storeName: 'Sixbox Roastery',
        isShift: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('owner@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan status awal Aktif
      expect(find.text('Aktif'), findsWidgets);

      // Buka bottom sheet
      await tester.ensureVisible(find.text('Ubah'));
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      // Verifikasi komponen slider hadir
      expect(find.text('Sistem Shift'), findsWidgets);
      expect(find.text('Non-Aktif'), findsOneWidget);

      // Tap Non-Aktif pada slider
      await tester.tap(find.text('Non-Aktif'));
      await tester.pumpAndSettle();

      // Simpan perubahan
      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verifikasi isShift menjadi false di provider dan UI menampilkan Tidak Aktif
      expect(authProvider.user?.isShift, false);
      expect(find.text('Tidak Aktif'), findsOneWidget);
    });

    testWidgets(
        'Klik tombol logout memunculkan dialog konfirmasi destruktif mirip _showSoftDeleteDialog',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['admin@karyahr.com'] = User(
        id: 'admin-1',
        name: 'Admin Utama',
        employeeId: 'emp-admin',
        email: 'admin@karyahr.com',
        role: Role.admin,
        isActive: true,
        storeName: 'Toko Berkah',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('admin@karyahr.com', 'password');

      bool navigatedToLogin = false;

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          routes: {
            AppConstants.kRouteLogin: (_) {
              navigatedToLogin = true;
              return const Scaffold(body: Text('Login Screen'));
            },
          },
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tombol Keluar dari Aplikasi
      await tester.ensureVisible(find.text('Keluar dari Aplikasi'));
      await tester.tap(find.text('Keluar dari Aplikasi'));
      await tester.pumpAndSettle();

      // Verifikasi dialog konfirmasi muncul dengan layout destruktif
      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.textContaining('admin@karyahr.com'), findsWidgets);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Ya, Keluar'), findsOneWidget);

      // Tap 'Ya, Keluar'
      await tester.tap(find.text('Ya, Keluar'));
      await tester.pumpAndSettle();

      // Verifikasi user logged out dan berpindah ke login
      expect(navigatedToLogin, isTrue);
      expect(authProvider.user, isNull);
    });

    testWidgets(
        'Role EMPLOYEE Full Data: Menampilkan NIK, Jabatan, Departemen dan Toko Read-Only tanpa tombol Ubah',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['siti@karyahr.com'] = User(
        id: 'emp-user-1',
        name: 'Siti Aminah',
        employeeId: 'EMP-001',
        email: 'siti@karyahr.com',
        role: Role.employee,
        isActive: true,
        storeName: 'PT Berkah Makmur Sejahtera',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nik: 'EMP-2024-001',
        position: 'Staff Kasir Senior',
        department: 'Operasional Outlet',
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('siti@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi identitas employee
      expect(find.text('Siti Aminah'), findsOneWidget);
      expect(find.text('siti@karyahr.com'), findsWidgets);
      expect(find.text('KARYAWAN'), findsOneWidget);

      // Verifikasi informasi kepegawaian (Stitch Viewport 2)
      expect(find.text('INFORMASI KEPEGAWAIAN'), findsOneWidget);
      expect(find.text('EMP-2024-001'), findsOneWidget);
      expect(find.text('Staff Kasir Senior'), findsOneWidget);
      expect(find.text('Operasional Outlet'), findsOneWidget);

      // Verifikasi Tempat Bekerja Read-Only (Hanya Baca dan tidak ada tombol Ubah)
      expect(find.text('TEMPAT BEKERJA'), findsOneWidget);
      expect(find.text('PT Berkah Makmur Sejahtera'), findsOneWidget);
      expect(find.text('Hanya Baca'), findsOneWidget);
      expect(find.text('Ubah'), findsNothing);

      // Verifikasi opsi Ubah Kata Sandi dan Keluar
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
      expect(find.text('Keluar dari Aplikasi'), findsOneWidget);
    });

    testWidgets(
        'Role EMPLOYEE Degraded: Menampilkan banner Akun Belum Tertaut NIK saat data NIK kosong',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['fauzi@karyahr.com'] = User(
        id: 'emp-user-2',
        name: 'Ahmad Fauzi',
        employeeId: '',
        email: 'fauzi@karyahr.com',
        role: Role.employee,
        isActive: true,
        storeName: 'PT Berkah Makmur Sejahtera',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        nik: null,
        position: null,
        department: null,
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('fauzi@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi banner degradasi ramah (Stitch Viewport 3)
      expect(find.text('Akun Belum Tertaut NIK'), findsOneWidget);
      expect(find.textContaining('Data detail kepegawaian'), findsOneWidget);
      expect(find.text('TEMPAT BEKERJA'), findsOneWidget);
      expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    });

    testWidgets('Membuka Bottom Sheet Ubah Kata Sandi dan melakukan submit',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['user@karyahr.com'] = User(
        id: 'user-pwd-1',
        name: 'Budi Santoso',
        employeeId: '',
        email: 'user@karyahr.com',
        role: Role.owner,
        isActive: true,
        storeName: 'Toko Budi',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('user@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Ubah Kata Sandi
      await tester.ensureVisible(find.text('Ubah Kata Sandi'));
      await tester.tap(find.text('Ubah Kata Sandi'));
      await tester.pumpAndSettle();

      // Verifikasi Bottom Sheet terbuka (Stitch Viewport 5)
      expect(find.text('Kata Sandi Saat Ini *'), findsOneWidget);
      expect(find.text('Kata Sandi Baru *'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi Baru *'), findsOneWidget);
      expect(find.text('Simpan Kata Sandi'), findsOneWidget);

      // Isi form kata sandi
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan kata sandi saat ini'),
        'oldpass123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Minimal 8 karakter'),
        'newpass1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Ulangi kata sandi baru'),
        'newpass1234',
      );

      await tester.ensureVisible(find.text('Simpan Kata Sandi'));
      await tester.tap(find.text('Simpan Kata Sandi'));
      await tester.pumpAndSettle();

      expect(find.text('Kata sandi berhasil diperbarui'), findsOneWidget);
    });

    testWidgets('Membuka Bottom Sheet Ubah Nama Toko dan melakukan submit',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['owner@karyahr.com'] = User(
        id: 'owner-modal-1',
        name: 'Owner Modal',
        employeeId: '',
        email: 'owner@karyahr.com',
        role: Role.owner,
        isActive: true,
        storeName: 'Toko Modal Lama',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('owner@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const Scaffold(
            body: AdminProfileView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap tombol Ubah
      await tester.ensureVisible(find.text('Ubah'));
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();

      // Verifikasi Bottom Sheet terbuka (Stitch Viewport 4)
      expect(find.text('Ubah Pengaturan Toko'), findsOneWidget);
      expect(find.text('Nama Toko'), findsOneWidget);
      expect(find.text('Sistem Shift'), findsWidgets);

      // Edit nama toko di sheet
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Masukkan nama entitas usaha'),
        'Toko Modal Baru Barokah',
      );

      await tester.ensureVisible(find.text('Simpan Perubahan'));
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(authProvider.user?.storeName, 'Toko Modal Baru Barokah');
    });

    testWidgets(
        'AdminShell _buildCurrentTab dinamis sesuai isShift (Approval, Payroll, Profil bergeser tepat)',
        (tester) async {
      final fakeRepo = FakeAuthRepository();
      fakeRepo.users['admin@karyahr.com'] = User(
        id: 'admin-1',
        name: 'Admin Utama',
        employeeId: 'emp-admin',
        email: 'admin@karyahr.com',
        role: Role.admin,
        isActive: true,
        storeName: 'Sixbox Roastery',
        isShift: false, // SHIFT NON-AKTIF
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authProvider = AuthProvider(repository: fakeRepo);
      await authProvider.login('admin@karyahr.com', 'password');

      await tester.pumpWidget(
        createTestApp(
          authProvider: authProvider,
          child: const AdminShell(),
        ),
      );
      await tester.pumpAndSettle();

      // Tab 0: Beranda
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Tap Tab 1: Karyawan
      await tester.tap(find.text('Karyawan'));
      await tester.pumpAndSettle();
      expect(find.byType(EmployeeListScreen), findsOneWidget);

      // Tap Tab 2: Approval (karena Shift tidak ada, tab kedua setelah Karyawan adalah Approval!)
      await tester.tap(find.text('Approval'));
      await tester.pumpAndSettle();
      expect(find.text('Pusat Persetujuan (Approval Center)'), findsOneWidget);

      // Tap Tab 3: Payroll
      await tester.tap(find.text('Payroll'));
      await tester.pumpAndSettle();
      expect(find.text('Periode Penggajian'), findsOneWidget);

      // Tap Tab 4: Profil
      await tester.tap(find.text('Profil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileView), findsOneWidget);
    });
  });
}
