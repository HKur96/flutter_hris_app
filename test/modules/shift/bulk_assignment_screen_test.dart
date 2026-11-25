import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_assignment_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/bulk_assignment_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('BulkAssignmentScreen Widget Tests', () {
    testWidgets('Menampilkan komponen form penugasan massal dengan benar',
        (tester) async {
      final fakeAsgRepo = FakeShiftAssignmentRepository();
      final asgProvider = ShiftAssignmentProvider(repository: fakeAsgRepo);

      final fakeShiftRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeShiftRepo);

      await tester.pumpWidget(
        createTestApp(
          asgProvider: asgProvider,
          shiftProvider: shiftProvider,
          child: const BulkAssignmentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Form Penugasan Shift'), findsOneWidget);
      expect(find.text('Pilih Shift'), findsOneWidget);
      expect(find.text('Tgl Mulai'), findsOneWidget);
      expect(find.text('Tgl Selesai'), findsOneWidget);
      expect(find.text('Pilih Karyawan'), findsOneWidget);
      expect(find.text('Simpan Penugasan Shift'), findsOneWidget);
    });

    testWidgets(
        'Auto-select karyawan dan tanggal langsung aktif jika parameter diteruskan',
        (tester) async {
      final fakeAsgRepo = FakeShiftAssignmentRepository();
      final asgProvider = ShiftAssignmentProvider(repository: fakeAsgRepo);

      final fakeShiftRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeShiftRepo);

      final selectedDay = DateTime(2026, 11, 25);

      await tester.pumpWidget(
        createTestApp(
          asgProvider: asgProvider,
          shiftProvider: shiftProvider,
          child: BulkAssignmentScreen(
            employeeId: 'emp-1',
            selectedDay: selectedDay,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tanggal langsung terisi 2026-11-25 di start & end
      expect(find.text('2026-11-25'), findsNWidgets(2));

      // Karyawan langsung terisi 1 Terpilih
      expect(find.text('1 Terpilih'), findsOneWidget);
    });

    testWidgets(
        'Checklist karyawan mengubah kalkulasi perkiraan entri shift secara reaktif',
        (tester) async {
      final fakeAsgRepo = FakeShiftAssignmentRepository();
      final asgProvider = ShiftAssignmentProvider(repository: fakeAsgRepo);

      final fakeShiftRepo = FakeShiftRepository();
      final shiftProvider = ShiftProvider(repository: fakeShiftRepo);

      await tester.pumpWidget(
        createTestApp(
          asgProvider: asgProvider,
          shiftProvider: shiftProvider,
          child: const BulkAssignmentScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Awalnya 0 Karyawan terpilih -> 0 Penugasan Baru
      expect(find.text('0 Karyawan'), findsOneWidget);
      expect(find.textContaining('0 Penugasan Baru'), findsOneWidget);

      // Tap 'Pilih Semua'
      await tester.tap(find.text('Pilih Semua'));
      await tester.pumpAndSettle();

      // Terupdate menjadi 2 Karyawan terpilih
      expect(find.text('2 Karyawan'), findsOneWidget);
      expect(find.textContaining('Penugasan Baru'), findsWidgets);
    });
  });
}
