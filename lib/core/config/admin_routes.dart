import 'package:flutter/material.dart';

class AdminRoutes {
  static const String login = '/admin/login';
  static const String dashboard = '/admin/dashboard';
  static const String attendanceCorrectionApproval =
      '/admin/attendance-correction-approval';
  static const String leaveManagement = '/admin/leave-management';
  static const String overtimeManagement = '/admin/overtime-management';
  static const String shiftManagement = '/admin/shift-management';
  static const String departmentManagement = '/admin/department-management';
  static const String employeeManagement = '/admin/employee-management';
  static const String payslipManagement = '/admin/payslip-management';
  static const String attendanceReport = '/admin/attendance-report';
  static const String overtimeReport = '/admin/overtime-report';
  static const String absenceReport = '/admin/absence-report';
  static const String adminSettings = '/admin/admin-settings';

  static Map<String, WidgetBuilder> get routes => {
    // login: (context) => AdminLoginScreen(),

    // // Admin layout shell initialized with respective route
    // dashboard: (context) => const AdminLayout(initialRoute: dashboard),
    // attendanceReport: (context) =>
    //     const AdminLayout(initialRoute: attendanceReport),
    // overtimeReport: (context) => const AdminLayout(initialRoute: overtimeReport),
    // absenceReport: (context) => const AdminLayout(initialRoute: attendanceReport),

    // // Workforce approval
    // leaveManagement: (context) =>
    //     const AdminLayout(initialRoute: leaveManagement),
    // overtimeManagement: (context) =>
    //     const AdminLayout(initialRoute: overtimeManagement),
    // attendanceCorrectionApproval: (context) =>
    //     const AdminLayout(initialRoute: attendanceCorrectionApproval),

    // // Organization & management
    // employeeManagement: (context) =>
    //     const AdminLayout(initialRoute: employeeManagement),
    // departmentManagement: (context) =>
    //     const AdminLayout(initialRoute: departmentManagement),
    // shiftManagement: (context) =>
    //     const AdminLayout(initialRoute: shiftManagement),
    // payslipManagement: (context) =>
    //     const AdminLayout(initialRoute: payslipManagement),

    // // System & settings
    // adminSettings: (context) => const AdminLayout(initialRoute: adminSettings),
  };
}