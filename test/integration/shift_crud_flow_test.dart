import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/shift_list_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('Full Master Shift CRUD Flow Integration Tests', () {
    testWidgets(
        'CRUD Flow: List Shifts -> Create Shift -> Update Shift -> Deactivate',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          shiftProvider: shiftProvider,
          child: const ShiftListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. LIST: Verifikasi 3 shift awal
      expect(find.text('Shift Pagi'), findsOneWidget);
      expect(find.text('Shift Siang'), findsOneWidget);
      expect(find.text('Shift Malam'), findsOneWidget);
      expect(shiftProvider.totalCount, 3);

      // 2. CREATE: Buat Shift Baru
      final createSuccess = await shiftProvider.createShift({
        'name': 'Shift Operasional Dini Hari',
        'start_time': '01:00',
        'end_time': '09:00',
        'break_minutes': 60,
        'late_tolerance_minutes': 15,
        'is_active': true,
      });

      expect(createSuccess, isTrue);
      final created = shiftProvider.shifts.firstWhere((s) => s.name == 'Shift Operasional Dini Hari');
      expect(created.name, 'Shift Operasional Dini Hari');
      expect(shiftProvider.totalCount, 4);

      await tester.pumpAndSettle();
      expect(find.text('Shift Operasional Dini Hari'), findsOneWidget);

      // 3. UPDATE: Perbarui Jam Kerja & Toleransi
      final updateSuccess = await shiftProvider.updateShift(
        created.id,
        {
          'name': 'Shift Dini Hari Revisi',
          'start_time': '02:00',
          'end_time': '10:00',
          'late_tolerance_minutes': 20,
        },
      );

      expect(updateSuccess, isTrue);
      final updated = shiftProvider.shifts.firstWhere((s) => s.id == created.id);
      expect(updated.name, 'Shift Dini Hari Revisi');
      expect(updated.startTime, '02:00');

      await tester.pumpAndSettle();
      expect(find.text('Shift Dini Hari Revisi'), findsOneWidget);

      // 4. DEACTIVATE: Nonaktifkan Shift (is_active = false)
      final deactivateSuccess = await shiftProvider.toggleShiftStatus(
        created.id,
        false,
      );
      expect(deactivateSuccess, isTrue);
      final deactivated = shiftProvider.shifts.firstWhere((s) => s.id == created.id);
      expect(deactivated.isActive, isFalse);

      await tester.pumpAndSettle();
      // Verifikasi hitungan shift aktif berkurang
      expect(shiftProvider.activeCount, 3);
    });
  });
}
