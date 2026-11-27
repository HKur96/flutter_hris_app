import 'package:flutter/material.dart';
import '../../modules/attendance/presentation/admin/screens/correction_approval_screen.dart';
import '../../modules/attendance/presentation/admin/screens/daily_attendance_monitoring_screen.dart';
import '../../modules/employee_management/presentation/screens/employee_list_screen.dart';

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
    employeeManagement: (context) => const EmployeeListScreen(showAppBar: true),
    attendanceReport: (context) =>
        const DailyAttendanceMonitoringScreen(showAppBar: true),
    attendanceCorrectionApproval: (context) =>
        const CorrectionApprovalScreen(),
  };
}
