import 'package:flutter_hris_app/modules/auth/domain/entity/setup_status.dart';

class SetupStatusModel extends SetupStatus {
  const SetupStatusModel({
    required super.needsSetup,
    required super.hasOwner,
    required super.totalUsers,
    required super.activeOwners,
    required super.message,
  });

  factory SetupStatusModel.fromJson(Map<String, dynamic> json) =>
      SetupStatusModel(
        needsSetup: json['needsSetup'] == true,
        hasOwner: json['hasOwner'] == true,
        totalUsers: json['totalUsers'] is int ? json['totalUsers'] as int : 0,
        activeOwners:
            json['activeOwners'] is int ? json['activeOwners'] as int : 0,
        message: json['message']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'needsSetup': needsSetup,
    'hasOwner': hasOwner,
    'totalUsers': totalUsers,
    'activeOwners': activeOwners,
    'message': message,
  };
}
