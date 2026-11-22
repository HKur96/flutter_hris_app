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
    required super.storeName, required super.name,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    name: json['name'] ?? 'Owner',
    employeeId: json['employee_id'] ?? '',
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
  );

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
  };
}
