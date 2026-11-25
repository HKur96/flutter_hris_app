import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../domain/entity/shift.dart';
import '../provider/shift_provider.dart';
import 'add_edit_shift_screen.dart';
import 'shift_detail_screen.dart';

/// Mockup 01, 02 & 08: Daftar Master Shift (Shift List) sesuai Stitch Tahap 4.
/// Dilengkapi filter chip M3, live search, card shift interaktif, dan FAB Tambah Shift.
class ShiftListScreen extends StatefulWidget {
  const ShiftListScreen({super.key});

  @override
  State<ShiftListScreen> createState() => _ShiftListScreenState();
}

class _ShiftListScreenState extends State<ShiftListScreen> {
  late final User? _user = context.read<AuthProvider>().user;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftProvider = context.watch<ShiftProvider>();
    final shifts = shiftProvider.filteredShifts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                'Master Shift',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              actions: _user?.canManage == true
                  ? [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const AddEditShiftScreen(),
                              ),
                            );
                          },
                          child: Text('Tambah Shift'),
                        ),
                      ),
                    ]
                  : null,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AppColors.border, height: 1),
              ),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar 48dp Standard Sesuai Stitch Mockup 01
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  onChanged: (val) => shiftProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Cari nama shift...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              shiftProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Horizontal Filter Chips (Semua, Aktif, Nonaktif, Overnight)
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterChip(
                    label: 'Semua (${shiftProvider.totalCount})',
                    filterKey: 'Semua',
                    currentSelected: shiftProvider.selectedFilter,
                    onTap: () => shiftProvider.setSelectedFilter('Semua'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Aktif (${shiftProvider.activeCount})',
                    filterKey: 'Aktif',
                    currentSelected: shiftProvider.selectedFilter,
                    onTap: () => shiftProvider.setSelectedFilter('Aktif'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Nonaktif (${shiftProvider.inactiveCount})',
                    filterKey: 'Nonaktif',
                    currentSelected: shiftProvider.selectedFilter,
                    onTap: () => shiftProvider.setSelectedFilter('Nonaktif'),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Overnight (${shiftProvider.overnightCount})',
                    filterKey: 'Overnight',
                    currentSelected: shiftProvider.selectedFilter,
                    onTap: () => shiftProvider.setSelectedFilter('Overnight'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Shift List Content / Empty Resilience State
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await shiftProvider.fetchShifts();
                },
                child: shiftProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : shifts.isEmpty
                    ? _buildEmptyState(context, _user?.canManage == true)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                        itemCount: shifts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final shift = shifts[index];
                          return _buildShiftCard(
                            context: context,
                            shift: shift,
                            canManage: _user?.canManage == true,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String filterKey,
    required String currentSelected,
    required VoidCallback onTap,
  }) {
    final bool isSelected = currentSelected.startsWith(filterKey);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  /// Shift Item Card sesuai Stitch Mockup 01
  Widget _buildShiftCard({
    required BuildContext context,
    required Shift shift,
    required bool canManage,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ShiftDetailScreen(shift: shift)),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Nama Shift & Status Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: shift.isActive
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Jam Kerja & Badge Overnight
                        Row(
                          children: [
                            Text(
                              '${shift.startTime} - ${shift.endTime}',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '(${shift.formattedGrossHours})',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (shift.isCrossDayOvernight)
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFFE9D5FF),
                              ),
                            ),
                            child: Text(
                              'Lintas Malam',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF7E22CE),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status Badge (AKTIF / NONAKTIF)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: shift.isActive
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: shift.isActive
                            ? const Color(0xFFBBF7D0)
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      shift.isActive ? 'AKTIF' : 'NONAKTIF',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: shift.isActive
                            ? const Color(0xFF15803D)
                            : AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              // Footer: Istirahat, Toleransi & Chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.free_cancellation_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Istirahat: ${shift.breakMinutes} mnt',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.timelapse_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Toleransi: ${shift.lateToleranceMinutes} mnt',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty & Resilience State sesuai Stitch Mockup 08
  Widget _buildEmptyState(BuildContext context, bool canManage) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.schedule_outlined,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Tidak Ada Jadwal Shift',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ditemukan template shift yang sesuai dengan kriteria pencarian atau filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.space20),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Buat Template Shift Baru',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddEditShiftScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
