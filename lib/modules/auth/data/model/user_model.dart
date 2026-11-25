import 'package:flutter_hris_app/core/config/enum.dart';
import 'package:flutter_hris_app/modules/auth/domain/entity/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.employeeId,
    required super.email,
    required super.role,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
    required super.storeName,
    required super.name,
    super.nik,
    super.position,
    super.department,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final employeeData = json['employee'] is Map<String, dynamic>
        ? json['employee'] as Map<String, dynamic>
        : null;

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? (json['role'] == 'owner' ? 'Owner' : 'Pengguna'),
      employeeId: json['employee_id']?.toString() ??
          (employeeData?['id']?.toString() ?? ''),
      email: json['email'] ?? '',
      role: Role.fromValue(json['role']?.toString() ?? 'employee'),
      isActive: json['is_active'] == true,
      storeName: json['store_name'] ?? '-',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      nik: json['nik']?.toString() ??
          employeeData?['nik']?.toString() ??
          (json['employee_id']?.toString().isNotEmpty == true
              ? json['employee_id'].toString()
              : null),
      position: json['position']?.toString() ??
          employeeData?['position']?.toString() ??
          employeeData?['job_title']?.toString(),
      department: json['department']?.toString() ??
          employeeData?['department']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': role == Role.owner ? null : name,
    'employee_id': employeeId,
    'email': email,
    'role': role.name.toLowerCase(),
    'is_active': isActive == true,
    'store_name': storeName,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'nik': nik,
    'position': position,
    'department': department,
  };

  @override
  UserModel copyWith({
    String? id,
    String? name,
    String? employeeId,
    String? email,
    Role? role,
    bool? isActive,
    String? storeName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? nik,
    String? position,
    String? department,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      storeName: storeName ?? this.storeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nik: nik ?? this.nik,
      position: position ?? this.position,
      department: department ?? this.department,
    );
  }
}
