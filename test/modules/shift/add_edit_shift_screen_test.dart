import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/shift/domain/entity/shift.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/add_edit_shift_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('AddEditShiftScreen Widget Tests', () {
    testWidgets('Mode Tambah: Menampilkan form baru dengan kalkulasi jam kerja',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          shiftProvider: shiftProvider,
          child: const AddEditShiftScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tambah Shift Baru'), findsOneWidget);
      expect(find.text('08:00'), findsOneWidget);
      expect(find.text('17:00'), findsOneWidget);
      expect(find.text('Simpan Shift Baru'), findsOneWidget);
    });

    testWidgets('Mode Edit: Terisi data shift yang ada', (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      const shift = Shift(
        id: 'shift-custom',
        name: 'Shift Khusus Event',
        startTime: '10:00',
        endTime: '19:00',
        breakMinutes: 60,
        lateToleranceMinutes: 10,
        isActive: true,
      );

      await tester.pumpWidget(
        createTestApp(
          shiftProvider: shiftProvider,
          child: const AddEditShiftScreen(shift: shift),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ubah Template Shift'), findsOneWidget);
      expect(find.text('Shift Khusus Event'), findsWidgets);
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('19:00'), findsOneWidget);
      expect(find.text('Simpan Perubahan Shift'), findsOneWidget);
    });

    testWidgets('Validasi memblokir submit jika Nama Shift belum diisi',
        (tester) async {
      final fakeRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          shiftProvider: shiftProvider,
          child: const AddEditShiftScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Submit tanpa isi nama
      await tester.tap(find.text('Simpan Shift Baru'));
      await tester.pumpAndSettle();

      // Validasi muncul
      expect(find.textContaining('wajib diisi'), findsOneWidget);
    });
  });
}
