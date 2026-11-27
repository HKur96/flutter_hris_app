import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_in_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_out_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/provider/attendance_provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupTestEnvironment();
  });

  group('ClockInScreen & ClockOutScreen Widget Tests', () {
    testWidgets('ClockInScreen merender form dan koordinat numerik', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository();
      final provider = AttendanceProvider(repository: fakeRepo);
      provider.setPositionForTest(
        Position(
          longitude: 106.845599,
          latitude: -6.2087634,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const ClockInScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Clock-In'), findsWidgets);
      expect(find.text('Pencatatan Kehadiran Mandiri'), findsOneWidget);
      expect(find.text('Karyawan'), findsWidgets);
      expect(find.text('Waktu Perangkat'), findsOneWidget);
      expect(find.text('Shift Kerja'), findsOneWidget);
      expect(find.text('Koordinat Clock-In'), findsOneWidget);
      expect(find.text('Catatan Presensi'), findsOneWidget);
    });

    testWidgets('ClockInScreen merender state 09A Izin Lokasi Ditolak', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository();
      final provider = AttendanceProvider(repository: fakeRepo);
      provider.setLocationStateForTest(isDenied: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ClockInScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Izin Lokasi Perangkat Ditolak'), findsOneWidget);
      expect(find.text('Buka Pengaturan Izin'), findsOneWidget);
      expect(find.text('Coba Dapatkan Lokasi Lagi'), findsOneWidget);
    });

    testWidgets('ClockInScreen merender state 09B Mock GPS Terdeteksi', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository();
      final provider = AttendanceProvider(repository: fakeRepo);
      provider.setLocationStateForTest(isMock: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ClockInScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Lokasi Palsu (Mock GPS) Terdeteksi'), findsOneWidget);
      expect(find.text('Kebijakan Keamanan Perusahaan'), findsOneWidget);
      expect(find.text('Pindai Ulang Perangkat'), findsOneWidget);
    });

    testWidgets('ClockOutScreen merender ringkasan sesi aktif dan durasi', (
      tester,
    ) async {
      final fakeRepo = FakeAttendanceRepository(
        todayAttendance: Attendance(
          id: 'att-1',
          employeeId: 'emp-1',
          workDate: DateTime.now(),
          shiftId: 'shift-1',
          checkIn: DateTime.now().subtract(const Duration(hours: 4)),
          checkOut: null,
          checkInLat: -6.2088,
          checkInLng: 106.8456,
          checkOutLat: null,
          checkOutLng: null,
          status: 'PRESENT',
          notes: null,
          employeeName: 'Budi Santoso',
          employeeNik: '3201234567890001',
          shiftName: 'Shift Pagi (08:00 - 17:00)',
          shiftStartTime: '08:00',
          shiftEndTime: '17:00',
          durationMinutes: null,
        ),
      );
      final provider = AttendanceProvider(repository: fakeRepo);
      provider.setPositionForTest(
        Position(
          longitude: 106.845610,
          latitude: -6.2088120,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        ),
      );
      await provider.fetchTodayAttendance();

      await tester.pumpWidget(
        createTestApp(
          child: const ClockOutScreen(),
          attendanceProvider: provider,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Konfirmasi Clock-Out'), findsWidgets);
      expect(find.text('Akhiri Sesi Kerja Harian'), findsOneWidget);
      expect(find.text('Jam Check-In'), findsOneWidget);
      expect(find.text('Jadwal Shift'), findsOneWidget);
      expect(find.text('Perkiraan Durasi'), findsOneWidget);
      expect(find.text('Koordinat Clock-Out'), findsOneWidget);
      expect(find.text('Catatan Kepulangan'), findsOneWidget);
    });
  });
}
