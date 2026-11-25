import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_hris_app/modules/shift/presentation/provider/shift_assignment_provider.dart';
import 'package:flutter_hris_app/modules/shift/presentation/screens/shift_assignment_list_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupTestEnvironment();
  });

  group('ShiftAssignmentListScreen Widget Tests', () {
    testWidgets(
        'Menampilkan Segmented Switcher (Matriks Grid & Kartu) dan tombol Hari Ini',
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

      expect(find.text('Penugasan Shift'), findsWidgets);
      expect(find.text('Matriks Grid'), findsOneWidget);
      expect(find.text('Kartu'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
    });

    testWidgets(
        'Header 7 hari pada Matriks Grid diawali dari hari Minggu (MIN)',
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

      // Pastikan hari Minggu (MIN) muncul pertama
      expect(find.text('MIN'), findsOneWidget);
      expect(find.text('SEN'), findsOneWidget);
      expect(find.text('SEL'), findsOneWidget);
      expect(find.text('RAB'), findsOneWidget);
      expect(find.text('KAM'), findsOneWidget);
      expect(find.text('JUM'), findsOneWidget);
      expect(find.text('SAB'), findsOneWidget);
    });

    testWidgets('Beralih ke mode tampilan Kartu saat tab Kartu ditekan',
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

      // Awalnya Matriks Grid aktif
      expect(asgProvider.isMatrixView, isTrue);

      // Tap tab Kartu
      await tester.tap(find.text('Kartu'));
      await tester.pumpAndSettle();

      // Sekarang Kartu aktif
      expect(asgProvider.isMatrixView, isFalse);
    });

    testWidgets('Mode checklist (seleksi massal) menampilkan toolbar bawah',
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

      // Tap checklist button di AppBar
      final checklistIconFinder = find.byIcon(Icons.checklist_rounded);
      expect(checklistIconFinder, findsOneWidget);

      await tester.tap(checklistIconFinder);
      await tester.pumpAndSettle();

      // Mode seleksi aktif
      expect(asgProvider.isSelectionMode, isTrue);
      expect(find.text('0 Penugasan Terpilih'), findsOneWidget);
      expect(find.text('Ubah Shift'), findsOneWidget);
    });
  });
}
