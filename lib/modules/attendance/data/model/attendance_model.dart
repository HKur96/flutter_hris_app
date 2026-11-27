import 'package:flutter_hris_app/modules/attendance/domain/entity/attendance.dart';

class AttendanceModel extends Attendance {
  const AttendanceModel({
    required super.id,
    required super.employeeId,
    required super.workDate,
    required super.shiftId,
    required super.checkIn,
    required super.checkOut,
    required super.checkInLat,
    required super.checkInLng,
    required super.checkOutLat,
    required super.checkOutLng,
    required super.status,
    required super.notes,
    required super.employeeName,
    required super.employeeNik,
    required super.shiftName,
    required super.shiftStartTime,
    required super.shiftEndTime,
    required super.durationMinutes,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedWorkDate = DateTime.now();
    if (json['work_date'] != null) {
      if (json['work_date'] is DateTime) {
        parsedWorkDate = json['work_date'] as DateTime;
      } else {
        parsedWorkDate =
            DateTime.tryParse(json['work_date'].toString()) ?? DateTime.now();
      }
    }

    DateTime? parsedCheckIn;
    if (json['check_in'] != null) {
      if (json['check_in'] is DateTime) {
        parsedCheckIn = json['check_in'] as DateTime;
      } else {
        parsedCheckIn = DateTime.tryParse(json['check_in'].toString());
      }
    }

    DateTime? parsedCheckOut;
    if (json['check_out'] != null) {
      if (json['check_out'] is DateTime) {
        parsedCheckOut = json['check_out'] as DateTime;
      } else {
        parsedCheckOut = DateTime.tryParse(json['check_out'].toString());
      }
    }

    return AttendanceModel(
      id: json['id']?.toString() ?? '',
      employeeId: json['employee_id']?.toString() ?? '',
      workDate: parsedWorkDate,
      shiftId: json['shift_id']?.toString(),
      checkIn: parsedCheckIn,
      checkOut: parsedCheckOut,
      checkInLat: (json['check_in_lat'] as num?)?.toDouble(),
      checkInLng: (json['check_in_lng'] as num?)?.toDouble(),
      checkOutLat: (json['check_out_lat'] as num?)?.toDouble(),
      checkOutLng: (json['check_out_lng'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'PRESENT',
      notes: json['notes']?.toString(),
      employeeName: json['employee_name']?.toString() ?? '',
      employeeNik: json['employee_nik']?.toString() ?? '',
      shiftName: json['shift_name']?.toString() ?? '',
      shiftStartTime: json['shift_start_time']?.toString() ?? '',
      shiftEndTime: json['shift_end_time']?.toString() ?? '',
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'work_date': workDate.toIso8601String().split('T').first,
    'shift_id': shiftId,
    'check_in': checkIn?.toIso8601String(),
    'check_out': checkOut?.toIso8601String(),
    'check_in_lat': checkInLat,
    'check_in_lng': checkInLng,
    'check_out_lat': checkOutLat,
    'check_out_lng': checkOutLng,
    'status': status,
    'notes': notes,
    'employee_name': employeeName,
    'employee_nik': employeeNik,
    'shift_name': shiftName,
    'shift_start_time': shiftStartTime,
    'shift_end_time': shiftEndTime,
    'duration_minutes': durationMinutes,
  };

  AttendanceModel copyWith({
    String? id,
    String? employeeId,
    DateTime? workDate,
    String? shiftId,
    DateTime? checkIn,
    DateTime? checkOut,
    double? checkInLat,
    double? checkInLng,
    double? checkOutLat,
    double? checkOutLng,
    String? status,
    String? notes,
    String? employeeName,
    String? employeeNik,
    String? shiftName,
    String? shiftStartTime,
    String? shiftEndTime,
    double? durationMinutes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      workDate: workDate ?? this.workDate,
      shiftId: shiftId ?? this.shiftId,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      checkInLat: checkInLat ?? this.checkInLat,
      checkInLng: checkInLng ?? this.checkInLng,
      checkOutLat: checkOutLat ?? this.checkOutLat,
      checkOutLng: checkOutLng ?? this.checkOutLng,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      employeeName: employeeName ?? this.employeeName,
      employeeNik: employeeNik ?? this.employeeNik,
      shiftName: shiftName ?? this.shiftName,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
