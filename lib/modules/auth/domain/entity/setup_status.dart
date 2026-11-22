import 'package:equatable/equatable.dart';

class SetupStatus extends Equatable {
  final bool needsSetup;
  final bool hasOwner;
  final int totalUsers;
  final int activeOwners;
  final String message;

  const SetupStatus({
    required this.needsSetup,
    required this.hasOwner,
    required this.totalUsers,
    required this.activeOwners,
    required this.message,
  });

  @override
  List<Object?> get props => [
    needsSetup,
    hasOwner,
    totalUsers,
    activeOwners,
    message,
  ];
}
