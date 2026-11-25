import '../../domain/entity/shift_assignment.dart';

/// Model Data Penugasan Shift (ShiftAssignmentModel)
/// Kompatibel dengan payload REST GAS Modul 4.
class ShiftAssignmentModel extends ShiftAssignment {
  const ShiftAssignmentModel({
    required super.id,
    required super.employeeId,
    required super.employeeName,
    super.employeeNik,
    super.employeeRole,
    super.employeeDepartment,
    required super.shiftId,
    required super.shiftName,
    required super.startTime,
    required super.endTime,
    required super.workDate,
    super.isOvernight,
    super.createdAt,
    super.updatedAt,
  });

  factory ShiftAssignmentModel.fromJson(Map<String, dynamic> json) {
    // Penanganan nested employee atau flat properties
    String empName = '';
    String? empNik;
    String? empRole;
    String? empDept;

    if (json['employee'] is Map<String, dynamic>) {
      final empMap = json['employee'] as Map<String, dynamic>;
      empName = empMap['name']?.toString() ?? '';
      empNik = empMap['nik']?.toString();
      empRole = empMap['role']?.toString();
      empDept = empMap['department']?.toString();
    } else {
      empName = json['employee_name']?.toString() ??
          json['employeeName']?.toString() ??
          json['name']?.toString() ??
          '';
      empNik = json['employee_nik']?.toString() ?? json['nik']?.toString();
      empRole = json['employee_role']?.toString() ?? json['role']?.toString();
      empDept = json['employee_department']?.toString() ??
          json['department']?.toString();
    }

    // Penanganan nested shift atau flat properties
    String sName = '';
    String sStart = '08:00';
    String sEnd = '17:00';
    bool overnight = false;

    if (json['shift'] is Map<String, dynamic>) {
      final shiftMap = json['shift'] as Map<String, dynamic>;
      sName = shiftMap['name']?.toString() ?? '';
      sStart = shiftMap['start_time']?.toString() ??
          shiftMap['startTime']?.toString() ??
          '08:00';
      sEnd = shiftMap['end_time']?.toString() ??
          shiftMap['endTime']?.toString() ??
          '17:00';
      overnight = shiftMap['is_overnight'] == true ||
          shiftMap['isOvernight'] == true;
    } else {
      sName = json['shift_name']?.toString() ??
          json['shiftName']?.toString() ??
          '';
      sStart = json['start_time']?.toString() ??
          json['startTime']?.toString() ??
          '08:00';
      sEnd = json['end_time']?.toString() ??
          json['endTime']?.toString() ??
          '17:00';
      overnight = json['is_overnight'] == true ||
          json['isOvernight'] == true;
    }

    // Tanggal kerja (format YYYY-MM-DD)
    String dateStr = json['work_date']?.toString() ??
        json['workDate']?.toString() ??
        json['date']?.toString() ??
        '';
    if (dateStr.length > 10) {
      dateStr = dateStr.substring(0, 10);
    }

    return ShiftAssignmentModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ??
          json['employeeId']?.toString() ??
          '',
      employeeName: empName.isNotEmpty ? empName : 'Karyawan',
      employeeNik: empNik,
      employeeRole: empRole,
      employeeDepartment: empDept,
      shiftId: json['shift_id']?.toString() ??
          json['shiftId']?.toString() ??
          '',
      shiftName: sName.isNotEmpty ? sName : 'Shift Kerja',
      startTime: sStart,
      endTime: sEnd,
      workDate: dateStr,
      isOvernight: overnight,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJsonSingle() {
    return {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'work_date': workDate,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_nik': employeeNik,
      'employee_role': employeeRole,
      'employee_department': employeeDepartment,
      'shift_id': shiftId,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'work_date': workDate,
      'is_overnight': isOvernight,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
