class AppConstants {
  // Private constructor to prevent external instantiation.
  AppConstants._();

  // The single instance of the class.
  static final AppConstants _instance = AppConstants._();

  // Factory constructor to provide access to the singleton instance.
  factory AppConstants() {
    return _instance;
  }

  // Base API URL default
  static const String kDefaultBaseUrl = String.fromEnvironment(
    'base_url',
    defaultValue: 'https://hris-backend-worker.hkurhris.workers.dev/',
  );

  // Auth
  static const String kRouteRoot = '/';
  static const String kRouteSplash = '/splash';
  static const String kRouteLogin = '/login';
  static const String kRouteInitOwnerSetup = '/initial-owner-setup';
  static const String kRouteDashboard = '/dashboard';
  static const String kRouteEmployeeShell = '/employee/shell';
  static const String kRouteAdminShell = '/admin/shell';

  // Employee
  static const String kRouteAddEditEmployee = '/add-edit-employee';
}
