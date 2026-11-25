import 'package:equatable/equatable.dart';

/// Entitas domain Master Shift sesuai spesifikasi resmi API Modul 3 (Zero AI-Slop).
class Shift extends Equatable {
  final String id;
  final String name;
  final String startTime; // "HH:mm", misal "08:00"
  final String endTime; // "HH:mm", misal "17:00"
  final int breakMinutes;
  final int lateToleranceMinutes;
  final bool isActive;
  final bool? isOvernight;
  final int? grossWorkingMinutes;
  final int? netWorkingMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.breakMinutes,
    required this.lateToleranceMinutes,
    required this.isActive,
    this.isOvernight,
    this.grossWorkingMinutes,
    this.netWorkingMinutes,
    this.createdAt,
    this.updatedAt,
  });

  /// Deteksi otomatis apakah shift melewati tengah malam (Cross-day Overnight)
  bool get isCrossDayOvernight {
    if (isOvernight != null) return isOvernight!;
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);
    return end <= start;
  }

  /// Kalkulasi durasi kerja kotor dalam menit (gross working minutes)
  int get calculatedGrossMinutes {
    if (grossWorkingMinutes != null && grossWorkingMinutes! > 0) {
      return grossWorkingMinutes!;
    }
    final start = _timeToMinutes(startTime);
    final end = _timeToMinutes(endTime);
    if (end > start) {
      return end - start;
    } else {
      // Melewati tengah malam
      return (24 * 60 - start) + end;
    }
  }

  /// Kalkulasi durasi kerja bersih dalam menit setelah dikurangi istirahat
  int get calculatedNetMinutes {
    if (netWorkingMinutes != null && netWorkingMinutes! > 0) {
      return netWorkingMinutes!;
    }
    final gross = calculatedGrossMinutes;
    final net = gross - breakMinutes;
    return net > 0 ? net : 0;
  }

  /// Format jam kerja "08:00 - 17:00 WIB"
  String get formattedTimeRange => '$startTime - $endTime WIB';

  /// Format durasi kotor dalam jam, cth: "9.0 Jam"
  String get formattedGrossHours {
    final hours = calculatedGrossMinutes / 60.0;
    return '${hours.toStringAsFixed(1)} Jam';
  }

  /// Format durasi bersih dalam jam, cth: "8.0 Jam"
  String get formattedNetHours {
    final hours = calculatedNetMinutes / 60.0;
    return '${hours.toStringAsFixed(1)} Jam';
  }

  static int _timeToMinutes(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0].trim());
      final minute = int.parse(parts[1].trim());
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  Shift copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    int? breakMinutes,
    int? lateToleranceMinutes,
    bool? isActive,
    bool? isOvernight,
    int? grossWorkingMinutes,
    int? netWorkingMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      lateToleranceMinutes: lateToleranceMinutes ?? this.lateToleranceMinutes,
      isActive: isActive ?? this.isActive,
      isOvernight: isOvernight ?? this.isOvernight,
      grossWorkingMinutes: grossWorkingMinutes ?? this.grossWorkingMinutes,
      netWorkingMinutes: netWorkingMinutes ?? this.netWorkingMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        startTime,
        endTime,
        breakMinutes,
        lateToleranceMinutes,
        isActive,
        isOvernight,
        grossWorkingMinutes,
        netWorkingMinutes,
        createdAt,
        updatedAt,
      ];
}
