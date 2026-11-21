import 'package:flutter/material.dart';

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
    // home: (context) => EmployeeHomeScreen(),
    // attendanceMain: (context) => AttendanceMainScreen(),
    // attendanceDetail: (context) => AttendanceDetailScreen(),
    // clockinFlow: (context) => ClockinFlowScreen(),
    // clockoutFlow: (context) => ClockoutFlowScreen(),
    // attendanceCorrection: (context) => AttendanceCorrectionScreen(),
    // requestsMain: (context) => RequestMainScreen(),
    // leaveRequestForm: (context) => LeaveRequestFormScreen(),
    // leaveRequestDetail: (context) => LeaveRequestDetailScreen(),
    // overtimeRequestForm: (context) => const OvertimeRequestFormScreen(),
    // overtimeRequestDetail: (context) => const OvertimeRequestDetailScreen(),
    // correctionRequestDetail: (context) => const CorrectionRequestDetailScreen(),
    // documentsMain: (context) => const DocumentsMainScreen(),
    // payslipDetail: (context) => const PayslipDetailScreen(),
    // profile: (context) => const EmployeeProfileScreen(),
    // personalInfo: (context) => const PersonalInformationScreen(),
    // accountSecurity: (context) => const AccountSecurityScreen(),
    // applicationSettings: (context) => const ApplicationSettingsScreen(),
    // notificationPreferences: (context) => const NotificationPreferencesScreen(),
  };
}
