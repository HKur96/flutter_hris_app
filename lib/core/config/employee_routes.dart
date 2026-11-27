import 'package:flutter/material.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/attendance_history_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_in_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/clock_out_screen.dart';
import 'package:flutter_hris_app/modules/attendance/presentation/employee/screens/today_attendance_screen.dart';

class EmployeeRoutes {
  static const String home = '/employee/home';
  static const String attendanceMain = '/employee/attendance';
  static const String attendanceDetail = '/employee/attendance/detail';
  static const String clockinFlow = '/employee/clockin';
  static const String clockoutFlow = '/employee/clockout';
  static const String attendanceCorrection = '/employee/attendance-correction';
  static const String requestsMain = '/employee/requests';
  static const String leaveRequestForm = '/employee/leave-request/new';
  static const String leaveRequestDetail = '/employee/leave-request/detail';
  static const String overtimeRequestForm = '/employee/overtime-request/new';
  static const String overtimeRequestDetail =
      '/employee/overtime-request/detail';
  static const String correctionRequestDetail =
      '/employee/correction-request/detail';
  static const String documentsMain = '/employee/documents';
  static const String payslipDetail = '/employee/documents/payslip/detail';
  static const String profile = '/employee/profile';
  static const String personalInfo = '/employee/personal-info';
  static const String accountSecurity = '/employee/account-security';
  static const String applicationSettings = '/employee/app-settings';
  static const String notificationPreferences =
      '/employee/notification-preferences';

  static Map<String, WidgetBuilder> get routes => {
    attendanceMain: (context) => const TodayAttendanceScreen(),
    attendanceDetail: (context) => const AttendanceHistoryScreen(),
    clockinFlow: (context) => const ClockInScreen(),
    clockoutFlow: (context) => const ClockOutScreen(),
  };
}
