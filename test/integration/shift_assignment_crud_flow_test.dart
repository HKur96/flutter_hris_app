import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_assignment_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/shift_assignment_list_screen.dart';
import '../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('Full Shift Assignment CRUD Flow Integration Tests', () {
    testWidgets(
        'CRUD Flow: Matrix View (Sunday Start) -> Bulk Assign -> Single Update -> Single Delete -> Bulk Update',
        (tester) async {
      final fakeRepo = FakeShiftAssignmentRepository();
      final asgProvider = ShiftAssignmentProvider(repository: fakeRepo);

      await tester.pumpWidget(
        createTestApp(
          asgProvider: asgProvider,
          child: const ShiftAssignmentListScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. READ & VERIFY: Matriks dimulai hari Minggu (MIN)
      expect(asgProvider.weekDays.first.weekday, DateTime.sunday);
      expect(find.text('MIN'), findsOneWidget);
      expect(asgProvider.totalCount, 2);

      // 2. CREATE: Buat Penugasan Massal
      final bulkResult = await asgProvider.createBulkAssignment(
        shiftId: 'shift-1',
        startDate: '2026-11-22',
        endDate: '2026-11-24',
        employeeIds: ['emp-2'],
        employeeNames: ['Ahmad Fauzi'],
        shiftName: 'Shift Pagi',
      );

      expect(bulkResult, isNotNull);
      expect(bulkResult?.totalDays, 3);
      expect(bulkResult?.totalEmployees, 1);
      expect(asgProvider.totalCount, 5); // 2 awal + 3 baru

      await tester.pumpAndSettle();
      expect(asgProvider.checkConflict('emp-2', '2026-11-22'), isTrue);

      // 3. UPDATE SINGLE: Ubah Penugasan Tunggal
      final targetId = asgProvider.assignments.first.id;
      final updateSuccess = await asgProvider.updateShiftAssignment(
        id: targetId,
        shiftId: 'shift-2', // Ganti ke Shift Siang
      );

      expect(updateSuccess, isTrue);
      final updatedItem = asgProvider.assignments.firstWhere((a) => a.id == targetId);
      expect(updatedItem.shiftId, 'shift-2');
      expect(updatedItem.shiftName, 'Shift Siang');

      await tester.pumpAndSettle();

      // 4. BULK UPDATE: Perbarui beberapa penugasan sekaligus
      final selectedIds = [
        asgProvider.assignments[1].id,
        asgProvider.assignments[2].id,
      ];

      final bulkUpdateSuccess = await asgProvider.updateBulkAssignment(
        shiftId: 'shift-2',
        assignmentIds: selectedIds,
      );

      expect(bulkUpdateSuccess, isTrue);
      expect(asgProvider.isSelectionMode, isFalse);

      await tester.pumpAndSettle();

      // 5. DELETE SINGLE: Hapus Penugasan Tunggal
      final deleteId = asgProvider.assignments.last.id;
      final initialCount = asgProvider.totalCount;

      final deleteSuccess = await asgProvider.deleteShiftAssignment(deleteId);
      expect(deleteSuccess, isTrue);
      expect(asgProvider.totalCount, initialCount - 1);

      await tester.pumpAndSettle();
    });
  });
}
