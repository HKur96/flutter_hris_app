import 'package:equatable/equatable.dart';
import 'package:flutter_hris_app/core/config/enum.dart';

class User extends Equatable {
  final String id;
  final String employeeId;
  final String email;
  final Role role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.employeeId,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    email,
    role,
    isActive,
    createdAt,
    updatedAt,
  ];
}
