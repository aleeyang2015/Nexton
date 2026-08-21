// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  tenantId: json['tenant_id'] as String? ?? '',
  email: json['email'] as String? ?? '',
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  modules:
      (json['modules'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  employeeId: json['employee_id'] as String?,
  profilePhotoUrl: json['profile_photo_url'] as String?,
  departmentName: json['department_name'] as String?,
  positionTitle: json['position_title'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'tenant_id': instance.tenantId,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'roles': instance.roles,
  'permissions': instance.permissions,
  'modules': instance.modules,
  'employee_id': instance.employeeId,
  'profile_photo_url': instance.profilePhotoUrl,
  'department_name': instance.departmentName,
  'position_title': instance.positionTitle,
};
