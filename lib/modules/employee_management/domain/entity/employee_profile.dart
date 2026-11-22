import 'package:equatable/equatable.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Entitas domain profil karyawan sesuai spesifikasi 9 Atribut resmi API (Zero AI-Slop).
class EmployeeProfile extends Equatable {
  final String id;
  final String nik;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String position;
  final String? role;
  final DateTime? joinDate;
  final String employmentStatus; // 'ACTIVE' | 'INACTIVE'
  final double baseSalary;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const EmployeeProfile({
    required this.id,
    required this.nik,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.position,
    this.role,
    this.joinDate,
    required this.employmentStatus,
    required this.baseSalary,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isActive => employmentStatus.toUpperCase() == 'ACTIVE';

  /// Representasi tampilan peran akun ('Admin' | 'Karyawan')
  String get roleDisplay {
    if (role != null && role!.trim().isNotEmpty) {
      return role!.toUpperCase() == 'ADMIN' ? 'Admin' : 'Karyawan';
    }
    if (position.toLowerCase().contains('admin') ||
        department.toLowerCase().contains('admin')) {
      return 'Admin';
    }
    return 'Karyawan';
  }

  bool get isAdmin => roleDisplay == 'Admin';

  /// Inisial avatar 2 huruf (contoh: "Budi Santoso" -> "BS", "Dewi" -> "D")
  String get initials {
    final clean = name.trim();
    if (clean.isEmpty) return 'EM';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Gaji Pokok terformat dalam Rupiah
  String get formattedSalary => CurrencyFormatter.format(baseSalary);

  /// Perhitungan durasi masa kerja ringkas
  String get tenureDescription {
    if (joinDate == null) return '-';
    final now = DateTime.now();
    final difference = now.difference(joinDate!);
    final days = difference.inDays;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;

    if (years > 0 && months > 0) {
      return '$years Tahun $months Bulan';
    } else if (years > 0) {
      return '$years Tahun';
    } else if (months > 0) {
      return '$months Bulan';
    } else {
      return '$days Hari';
    }
  }

  EmployeeProfile copyWith({
    String? id,
    String? nik,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? position,
    String? role,
    DateTime? joinDate,
    String? employmentStatus,
    double? baseSalary,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return EmployeeProfile(
      id: id ?? this.id,
      nik: nik ?? this.nik,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      position: position ?? this.position,
      role: role ?? this.role,
      joinDate: joinDate ?? this.joinDate,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      baseSalary: baseSalary ?? this.baseSalary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nik,
    name,
    email,
    phone,
    department,
    position,
    role,
    joinDate,
    employmentStatus,
    baseSalary,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
