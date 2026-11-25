import 'package:equatable/equatable.dart';
import 'package:flutter_hris_app/core/config/enum.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String employeeId;
  final String email;
  final Role role;
  final bool isActive;
  final String storeName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? nik;
  final String? position;
  final String? department;

  const User({
    required this.id,
    required this.name,
    required this.employeeId,
    required this.email,
    required this.role,
    required this.isActive,
    required this.storeName,
    required this.createdAt,
    required this.updatedAt,
    this.nik,
    this.position,
    this.department,
  });

  bool get canManage => role == Role.admin || role == Role.owner;

  User copyWith({
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
    return User(
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

  @override
  List<Object?> get props => [
    id,
    name,
    employeeId,
    email,
    role,
    isActive,
    storeName,
    createdAt,
    updatedAt,
    nik,
    position,
    department,
  ];
}
