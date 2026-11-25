import 'package:equatable/equatable.dart';

/// Entitas domain Penugasan Shift (Shift Assignment) sesuai spesifikasi GAS Modul 4.
class ShiftAssignment extends Equatable {
  final String id;
  final String employeeId;
  final String employeeName;
  final String? employeeNik;
  final String? employeeRole;
  final String? employeeDepartment;
  final String shiftId;
  final String shiftName;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String workDate; // "YYYY-MM-DD"
  final bool isOvernight;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShiftAssignment({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    this.employeeNik,
    this.employeeRole,
    this.employeeDepartment,
    required this.shiftId,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.workDate,
    this.isOvernight = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Inisial dua huruf nama karyawan untuk Avatar (cth: "Budi Santoso" -> "BS")
  String get initials {
    final parts = employeeName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'HR';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Format rentang waktu kerja, misal "08:00 - 17:00"
  String get formattedTimeRange => '$startTime - $endTime';

  /// Format tanggal kerja yang ramah dibaca, misal "21 Nov 2026"
  String get formattedDate {
    try {
      final parsed = DateTime.parse(workDate);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return workDate;
    }
  }

  /// Format tanggal lengkap beserta hari, misal "Sabtu, 21 Nov 2026"
  String get formattedFullDateWithDay {
    try {
      final parsed = DateTime.parse(workDate);
      const days = [
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
        'Minggu',
      ];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final dayName = days[parsed.weekday - 1];
      return '$dayName, ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return workDate;
    }
  }

  /// Deteksi apakah penugasan ini jatuh pada hari ini
  bool get isToday {
    try {
      final parsed = DateTime.parse(workDate);
      final now = DateTime.now();
      return parsed.year == now.year &&
          parsed.month == now.month &&
          parsed.day == now.day;
    } catch (_) {
      return false;
    }
  }

  ShiftAssignment copyWith({
    String? id,
    String? employeeId,
    String? employeeName,
    String? employeeNik,
    String? employeeRole,
    String? employeeDepartment,
    String? shiftId,
    String? shiftName,
    String? startTime,
    String? endTime,
    String? workDate,
    bool? isOvernight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftAssignment(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeNik: employeeNik ?? this.employeeNik,
      employeeRole: employeeRole ?? this.employeeRole,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      workDate: workDate ?? this.workDate,
      isOvernight: isOvernight ?? this.isOvernight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    shiftId,
    workDate,
    startTime,
    endTime,
  ];
}

/// Hasil respons penugasan massal (Bulk Assignment Result) sesuai API 200/201
class BulkAssignmentResult extends Equatable {
  final int count;
  final int totalDays;
  final int totalEmployees;
  final List<String> employeeNames;
  final String startDate;
  final String endDate;
  final String shiftName;

  const BulkAssignmentResult({
    required this.count,
    required this.totalDays,
    required this.totalEmployees,
    required this.employeeNames,
    required this.startDate,
    required this.endDate,
    required this.shiftName,
  });

  @override
  List<Object?> get props => [
    count,
    totalDays,
    totalEmployees,
    employeeNames,
    startDate,
    endDate,
    shiftName,
  ];
}

/// Hasil respons pembaruan shift massal (Bulk Update Result) sesuai API 200
class BulkUpdateResult extends Equatable {
  final int count;
  final List<String> updatedIds;
  final String newShiftId;
  final String? newShiftName;

  const BulkUpdateResult({
    required this.count,
    required this.updatedIds,
    required this.newShiftId,
    this.newShiftName,
  });

  @override
  List<Object?> get props => [
    count,
    updatedIds,
    newShiftId,
    newShiftName,
  ];
}
