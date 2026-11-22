import '../../domain/entity/employee_profile.dart';

class EmployeeProfileModel extends EmployeeProfile {
  const EmployeeProfileModel({
    required super.id,
    required super.nik,
    required super.name,
    required super.email,
    required super.phone,
    required super.department,
    required super.position,
    super.role,
    super.joinDate,
    required super.employmentStatus,
    required super.baseSalary,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  factory EmployeeProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    return EmployeeProfileModel(
      id: json['id']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      role: json['role']?.toString() ?? json['user']?['role']?.toString(),
      joinDate: parseDate(json['join_date']),
      employmentStatus: json['employment_status']?.toString().toUpperCase() ?? 'ACTIVE',
      baseSalary: (double.tryParse(json['base_salary']?.toString() ?? '0') ?? 0).toDouble(),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDate(json['updated_at']) ?? DateTime.now(),
      deletedAt: parseDate(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nik': nik,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'position': position,
      if (role != null) 'role': role,
      'join_date': joinDate != null
          ? "${joinDate!.year.toString().padLeft(4, '0')}-${joinDate!.month.toString().padLeft(2, '0')}-${joinDate!.day.toString().padLeft(2, '0')}"
          : null,
      'employment_status': employmentStatus,
      'base_salary': baseSalary,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
    };
  }
}
