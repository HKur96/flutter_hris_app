import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hris_app/core/components/app_navigation_bar.dart';
import 'package:flutter_hris_app/core/config/enum.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String employeeId;
  final String email;
  final Role role;
  final bool isActive;
  final String storeName;
  final bool isShift;
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
    this.isShift = true,
    required this.createdAt,
    required this.updatedAt,
    this.nik,
    this.position,
    this.department,
  });

  bool get canManage => role == Role.admin || role == Role.owner;

  List<AppNavItem> get navItems => role == Role.employee
      ? [
          AppNavItem(
            label: 'Beranda',
            activeIcon: Icons.dashboard_rounded,
            inactiveIcon: Icons.dashboard_outlined,
          ),
          AppNavItem(
            label: 'Cuti & Izin',
            activeIcon: Icons.event_available_rounded,
            inactiveIcon: Icons.event_available_outlined,
          ),
          AppNavItem(
            label: 'Slip Gaji',
            activeIcon: Icons.receipt_long_rounded,
            inactiveIcon: Icons.receipt_long_outlined,
          ),
          AppNavItem(
            label: 'Profil',
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline_rounded,
          ),
        ]
      : [
          AppNavItem(
            label: 'Beranda',
            activeIcon: Icons.dashboard_rounded,
            inactiveIcon: Icons.dashboard_outlined,
          ),
          AppNavItem(
            label: 'Karyawan',
            activeIcon: Icons.people_alt_rounded,
            inactiveIcon: Icons.people_alt_outlined,
          ),
          if (isShift)
            AppNavItem(
              label: 'Shift',
              activeIcon: Icons.schedule_rounded,
              inactiveIcon: Icons.schedule_outlined,
            ),
          AppNavItem(
            label: 'Approval',
            activeIcon: Icons.fact_check_rounded,
            inactiveIcon: Icons.fact_check_outlined,
          ),
          AppNavItem(
            label: 'Payroll',
            activeIcon: Icons.payments_rounded,
            inactiveIcon: Icons.payments_outlined,
          ),
          AppNavItem(
            label: 'Profil',
            activeIcon: Icons.person_rounded,
            inactiveIcon: Icons.person_outline_rounded,
          ),
        ];

  User copyWith({
    String? id,
    String? name,
    String? employeeId,
    String? email,
    Role? role,
    bool? isActive,
    String? storeName,
    bool? isShift,
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
      isShift: isShift ?? this.isShift,
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
    isShift,
    createdAt,
    updatedAt,
    nik,
    position,
    department,
  ];
}
