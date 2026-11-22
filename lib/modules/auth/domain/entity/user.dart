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
  });

  bool get canManage => role == Role.admin || role == Role.owner;

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
  ];
}
