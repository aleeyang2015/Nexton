import 'package:equatable/equatable.dart';

/// The employee's own record as HR keeps it (#58), read-only: who they are,
/// how to reach them, where they sit, and whom to call in an emergency.
///
/// Holds nothing sensitive on purpose: salary, ID card, passport, tax,
/// social security and bank are never read from the server's answer.
class EmployeePersonalInfo extends Equatable {
  final String firstName;
  final String lastName;
  final String? firstNameLo;
  final String? lastNameLo;
  final String employeeNumber;
  final String? mobilePhone;
  final String? workPhone;
  final String? workPhoneExtension;
  final String? homePhone;
  final String? departmentName;

  /// Whom the employee reports to, as HR sent it.
  final String? managerName;

  /// The day they started, as a calendar date (no time, no zone).
  final DateTime? hireDate;
  final List<EmergencyContact> emergencyContacts;

  const EmployeePersonalInfo({
    this.firstName = '',
    this.lastName = '',
    this.firstNameLo,
    this.lastNameLo,
    this.employeeNumber = '',
    this.mobilePhone,
    this.workPhone,
    this.workPhoneExtension,
    this.homePhone,
    this.departmentName,
    this.managerName,
    this.hireDate,
    this.emergencyContacts = const [],
  });

  /// "First Last".
  String get name => '$firstName $lastName'.trim();

  /// The Lao name, when HR has one.
  String? get nameLo {
    final lo = '${firstNameLo ?? ''} ${lastNameLo ?? ''}'.trim();
    return lo.isEmpty ? null : lo;
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    firstNameLo,
    lastNameLo,
    employeeNumber,
    mobilePhone,
    workPhone,
    workPhoneExtension,
    homePhone,
    departmentName,
    managerName,
    hireDate,
    emergencyContacts,
  ];
}

/// Whom to call for the employee in an emergency.
class EmergencyContact extends Equatable {
  final String name;
  final String? nameLo;

  /// `spouse`, `parent`, `sibling`, `child`, `friend`, `other`, or whatever
  /// text HR typed: kept as sent.
  final String? relationship;
  final String? phone;
  final String? phoneSecondary;

  const EmergencyContact({
    required this.name,
    this.nameLo,
    this.relationship,
    this.phone,
    this.phoneSecondary,
  });

  @override
  List<Object?> get props => [
    name,
    nameLo,
    relationship,
    phone,
    phoneSecondary,
  ];
}
