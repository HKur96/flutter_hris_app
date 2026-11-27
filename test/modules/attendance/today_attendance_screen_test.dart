import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/today_attendance_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupTestEnvironment();
  });

  group('TodayAttendanceScreen Widget Tests (Screen 01 & 10)', () {
    testWidgets('Menampilkan sesi presensi aktif dengan tombol Check-Out', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository(
        todayAttendance: Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          workDate: DateTime.now(),
          shiftId: 'shift-1',
          checkIn: DateTime.now().subtract(const Duration(hours: 2)),
          checkOut: null,
          checkInLat: -6.2088,
          checkInLng: 106.8456,
          checkOutLat: null,
          checkOutLng: null,
          status: 'PRESENT',
          notes: 'Masuk normal',
          employeeName: 'Budi Santoso',
          employeeNik: '3201234567890001',
          shiftName: 'Shift Pagi',
          shiftStartTime: '08:00',
          shiftEndTime: '17:00',
          durationMinutes: null,
        ),
      );

      final provider = AttendanceProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          child: const TodayAttendanceScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi komponen Screen 01
      expect(find.text('Presensi Hari Ini'), findsWidgets);
      expect(find.text('Jadwal Shift Anda'), findsOneWidget);
      expect(find.text('Shift Pagi'), findsOneWidget);
      expect(find.text('Status Sesi Hari Ini'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('CLOCK-IN'), findsOneWidget);
      expect(find.text('CLOCK-OUT'), findsOneWidget);

      // Verifikasi alert sesi aktif
      expect(
        find.textContaining('Anda memiliki sesi check-in aktif'),
        findsOneWidget,
      );

      // Verifikasi tombol kontekstual Check-Out
      expect(find.text('Lakukan Check-Out Sekarang'), findsOneWidget);
    });

    testWidgets('Menampilkan Empty State Screen 10 saat tidak ada shift hari ini', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository(todayAttendance: null);
      final provider = AttendanceProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          child: const TodayAttendanceScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      // Verifikasi Empty State Screen 10
      expect(find.text('Tidak Ada Jadwal Shift Hari Ini'), findsOneWidget);
      expect(
        find.text('Anda tidak memiliki penugasan shift aktif untuk hari ini.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.event_busy_rounded), findsOneWidget);
    });
  });
}
