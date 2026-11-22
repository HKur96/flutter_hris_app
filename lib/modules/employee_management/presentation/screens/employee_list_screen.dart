import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/config/app_constants.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/components/components.dart';
import '../../../auth/presentation/provider/auth_provider.dart';
import '../../domain/entity/employee_profile.dart';
import '../provider/employee_management_provider.dart';
import 'employee_detail_screen.dart';

/// Mockup 01, 02 & 08: Daftar Karyawan (Search, Filter, List, Empty State & FAB).
class EmployeeListScreen extends StatefulWidget {
  final bool showAppBar;

  const EmployeeListScreen({super.key, this.showAppBar = false});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  late final User? _user = context.read<AuthProvider>().user;

  late final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddEmployee() {
    Navigator.of(context).pushNamed(AppConstants.kRouteAddEditEmployee);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeManagementProvider>();
    final employees = provider.filteredEmployees;

    final filterOptions = [
      'Semua',
      'Aktif (${provider.activeCount})',
      'Nonaktif (${provider.inactiveCount})',
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Text(
                'Data Karyawan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: AppColors.border, height: 1),
              ),
            )
          : null,
      body: _buildContent(
        provider,
        _user?.canManage == true,
        filterOptions,
        employees,
      ),
    );
  }

  Widget _buildEmployeeListView(
    List<EmployeeProfile> list,
    EmployeeManagementProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space8,
        AppSpacing.space16,
        80, // Ruang untuk FloatingActionButton
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final emp = list[index];
        return _buildEmployeeTile(context, emp);
      },
    );
  }

  Widget _buildEmployeeTile(BuildContext context, EmployeeProfile emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EmployeeDetailScreen(employee: emp),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space12),
          child: Row(
            children: [
              // Avatar Inisial 40dp (WCAG AAA Contrast)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emp.isActive ? AppColors.brand100 : AppColors.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: emp.isActive ? AppColors.brand200 : AppColors.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  emp.initials,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: emp.isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space12),

              // Info Karyawan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            emp.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: emp.isActive
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: emp.isActive
                                ? AppColors.brand50
                                : AppColors.canvas,
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                            border: Border.all(
                              color: emp.isActive
                                  ? AppColors.brand200
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            emp.employmentStatus.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: emp.isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${emp.position} · ${emp.department}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIK: ${emp.nik}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.borderSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mockup 08: Empty State
  Widget _buildEmptyState(BuildContext context, bool canManage) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.group_off_rounded,
                size: 32,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Text(
              'Belum Ada Data Karyawan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tambahkan staf pertama untuk mulai mencatat presensi, jadwal shift, dan penggajian.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.space16),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 42),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    'Tambah Karyawan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: _openAddEmployee,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildContent(
    EmployeeManagementProvider provider,
    bool canManage,
    List<String> filterOptions,
    List<EmployeeProfile> employees,
  ) {
    return Column(
      children: [
        // 1. Search Bar 48dp (Mockup 01 & 02)
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space12,
            AppSpacing.space16,
            AppSpacing.space8,
          ),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama, NIK, jabatan...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      provider.setSearchQuery(val);
                    },
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      provider.setSearchQuery('');
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // 2. Filter Chips Bar (Horizontal Scroll)
        SizedBox(
          height: 38,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
            scrollDirection: Axis.horizontal,
            itemCount: filterOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final opt = filterOptions[index];
              final isSelected =
                  provider.selectedFilter == opt ||
                  (opt.startsWith('Aktif') &&
                      provider.selectedFilter.startsWith('Aktif')) ||
                  (opt.startsWith('Nonaktif') &&
                      provider.selectedFilter.startsWith('Nonaktif'));

              return FilterChip(
                selected: isSelected,
                label: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                backgroundColor: AppColors.surface,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                onSelected: (_) {
                  provider.setSelectedFilter(opt);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // 3. Employee List Content / Empty State
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              await provider.fetchEmployees();
            },
            child: provider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : employees.isEmpty
                ? _buildEmptyState(context, canManage)
                : _buildEmployeeListView(employees, provider),
          ),
        ),
      ],
    );
  }
}
