import '../../domain/entity/shift.dart';

class ShiftModel extends Shift {
  const ShiftModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.endTime,
    required super.breakMinutes,
    required super.lateToleranceMinutes,
    required super.isActive,
    super.isOvernight,
    super.grossWorkingMinutes,
    super.netWorkingMinutes,
    super.createdAt,
    super.updatedAt,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      return DateTime.tryParse(val.toString());
    }

    bool parseBool(dynamic val, {bool defaultValue = true}) {
      if (val == null) return defaultValue;
      if (val is bool) return val;
      final str = val.toString().trim().toLowerCase();
      if (str == 'true' || str == '1') return true;
      if (str == 'false' || str == '0') return false;
      return defaultValue;
    }

    int parseInt(dynamic val, {int defaultValue = 0}) {
      if (val == null) return defaultValue;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? defaultValue;
    }

    return ShiftModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '08:00',
      endTime: json['end_time']?.toString() ?? '17:00',
      breakMinutes: parseInt(json['break_minutes'], defaultValue: 60),
      lateToleranceMinutes: parseInt(json['late_tolerance_minutes'], defaultValue: 15),
      isActive: parseBool(json['is_active'], defaultValue: true),
      isOvernight: json['is_overnight'] != null
          ? parseBool(json['is_overnight'], defaultValue: false)
          : null,
      grossWorkingMinutes: json['gross_working_minutes'] != null
          ? parseInt(json['gross_working_minutes'])
          : null,
      netWorkingMinutes: json['net_working_minutes'] != null
          ? parseInt(json['net_working_minutes'])
          : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime,
      'end_time': endTime,
      'break_minutes': breakMinutes,
      'late_tolerance_minutes': lateToleranceMinutes,
      'is_active': isActive,
      if (isOvernight != null) 'is_overnight': isOvernight,
      if (grossWorkingMinutes != null) 'gross_working_minutes': grossWorkingMinutes,
      if (netWorkingMinutes != null) 'net_working_minutes': netWorkingMinutes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
