import 'package:equatable/equatable.dart';

class Attendance extends Equatable {
  final String id;
  final String employeeId;
  final DateTime workDate;
  final String? shiftId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String status;
  final String? notes;
  final String employeeName;
  final String employeeNik;
  final String shiftName;
  final String shiftStartTime;
  final String shiftEndTime;
  final double? durationMinutes;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.workDate,
    required this.shiftId,
    required this.checkIn,
    required this.checkOut,
    required this.checkInLat,
    required this.checkInLng,
    required this.checkOutLat,
    required this.checkOutLng,
    required this.status,
    required this.notes,
    required this.employeeName,
    required this.employeeNik,
    required this.shiftName,
    required this.shiftStartTime,
    required this.shiftEndTime,
    required this.durationMinutes,
  });

  @override
  List<Object?> get props => [
    id,
    employeeId,
    workDate,
    shiftId,
    checkIn,
    checkOut,
    checkInLat,
    checkInLng,
    checkOutLat,
    checkOutLng,
    status,
    notes,
    employeeName,
    employeeNik,
    shiftName,
    shiftStartTime,
    shiftEndTime,
    durationMinutes,
  ];
}
