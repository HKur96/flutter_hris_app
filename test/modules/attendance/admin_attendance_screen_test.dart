import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/screens/attendance_detail_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/screens/correction_approval_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/screens/daily_attendance_monitoring_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/admin/widgets/manual_attendance_dialog.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupTestEnvironment();
  });

  group('Admin Attendance Screens Widget Tests (Screen 04, 06, 07, 08)', () {
    final mockItem = Attendance(
      id: 'att-1',
      employeeId: 'emp-1',
      workDate: DateTime(2026, 11, 21),
      shiftId: 'shift-1',
      checkIn: DateTime(2026, 11, 21, 7, 54, 12),
      checkOut: DateTime(2026, 11, 21, 17, 3, 45),
      checkInLat: -6.2087634,
      checkInLng: 106.845599,
      checkOutLat: -6.2088120,
      checkOutLng: 106.845610,
      status: 'PRESENT',
      notes: 'Masuk tepat waktu di gerbang utama.',
      employeeName: 'Budi Santoso',
      employeeNik: '3201234567890001',
      shiftName: 'Shift Pagi Regular',
      shiftStartTime: '08:00',
      shiftEndTime: '17:00',
      durationMinutes: 549,
    );

    testWidgets('DailyAttendanceMonitoringScreen menampilkan daftar dan tombol + Manual', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository(initialList: [mockItem]);
      final provider = AttendanceProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          child: const DailyAttendanceMonitoringScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Data Presensi'), findsOneWidget);
      expect(find.text('+ Manual'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('Detail'), findsOneWidget);
    });

    testWidgets('AttendanceDetailScreen menampilkan detail shift dan koordinat teks', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: AttendanceDetailScreen(attendance: mockItem),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Detail Presensi'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('NIK: 3201234567890001'), findsOneWidget);
      expect(find.text('INFORMASI JADWAL SHIFT'), findsOneWidget);
      expect(find.text('WAKTU REALISASI KERJA'), findsOneWidget);
      expect(find.text('KOORDINAT GEOLOCATION (GPS)'), findsOneWidget);
      expect(find.textContaining('-6.2087634'), findsOneWidget);
      expect(find.text('CATATAN (NOTES)'), findsOneWidget);
      expect(find.text('"Masuk tepat waktu di gerbang utama."'), findsOneWidget);
    });

    testWidgets('ManualAttendanceDialog merender 5 field sesuai API Contract', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(body: ManualAttendanceDialog()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pencatatan Presensi Manual'), findsOneWidget);
      expect(find.text('Pilih Karyawan *'), findsOneWidget);
      expect(find.text('Tanggal Kerja *'), findsOneWidget);
      expect(find.text('Pilih Shift Kerja *'), findsOneWidget);
      expect(find.text('ABSENT (Tidak Hadir / Alpa)'), findsOneWidget);
      expect(find.text('Catatan Alasan *'), findsOneWidget);
      expect(find.text('Simpan Presensi'), findsOneWidget);
    });

    testWidgets('CorrectionApprovalScreen merender kartu perbandingan dan textarea audit', (
      tester,
    ) async {
      final lateItem = Attendance(
        id: 'att-2',
        employeeId: 'emp-2',
        workDate: DateTime(2026, 11, 21),
        shiftId: 'shift-1',
        checkIn: DateTime(2026, 11, 21, 8, 18),
        checkOut: null,
        checkInLat: -6.2088,
        checkInLng: 106.8456,
        checkOutLat: null,
        checkOutLng: null,
        status: 'LATE',
        notes: null,
        employeeName: 'Dewi Lestari',
        employeeNik: '3201234567890004',
        shiftName: 'Shift Pagi',
        shiftStartTime: '08:00',
        shiftEndTime: '17:00',
        durationMinutes: null,
      );

      await tester.pumpWidget(
        createTestApp(
          child: CorrectionApprovalScreen(attendance: lateItem),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Koreksi Data Presensi'), findsOneWidget);
      expect(find.text('PERBANDINGAN KOREKSI'), findsOneWidget);
      expect(find.text('Dewi Lestari'), findsOneWidget);
      expect(find.text('Status Saat Ini'), findsOneWidget);
      expect(find.text('Status Baru'), findsOneWidget);
      expect(find.text('Ubah Status Presensi *'), findsOneWidget);
      expect(find.text('Alasan Koreksi *'), findsOneWidget);
      expect(find.text('Simpan Perubahan Koreksi'), findsOneWidget);
    });
  });
}
