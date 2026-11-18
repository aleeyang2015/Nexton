import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../attendance/presentation/widgets/requests_list_message.dart';
import '../../domain/entities/personal_info.dart';
import '../profile_error_copy.dart';
import '../providers/profile_notifier.dart';
import '../widgets/emergency_contact_card.dart';
import '../widgets/personal_info_copy.dart';
import '../widgets/personal_info_row.dart';

/// "ຂໍ້ມູນສ່ວນຕົວ" (#58): the employee's own record, read-only. Shows the
/// profile already loaded for the Profile page (no request of its own); a
/// pull reads it again. Nothing can be changed here: HR fixes what is wrong.
class PersonalInfoPage extends ConsumerWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.watch(profileNotifierProvider);
    final notifier = ref.read(profileNotifierProvider.notifier);
    final personal = profile.valueOrNull?.personal;

    final Widget body;
    if (personal != null) {
      body = _Details(personal: personal);
    } else if (profile.hasError && !profile.isLoading) {
      final copy = profileErrorCopy(l10n, profile.error!);
      body = RequestsListMessage(
        icon: Icons.error_outline,
        text: copy.text,
        onRetry: copy.canRetry ? notifier.refresh : null,
      );
    } else {
      body = const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.homeBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => context.canPop()
                  ? context.pop()
                  : context.go(AppRoutes.profile),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            title: customText(
              l10n.personal,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: notifier.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 40),
              children: [body],
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final EmployeePersonalInfo personal;

  const _Details({required this.personal});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hireDate = personal.hireDate;
    final ext = personal.workPhoneExtension;
    final workPhone = personal.workPhone;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          children: [
            PersonalInfoRow(
              label: l10n.personalName,
              value: _orNull(personal.name),
            ),
            if (personal.nameLo case final String lo)
              PersonalInfoRow(label: l10n.personalNameLo, value: lo),
            PersonalInfoRow(
              label: l10n.personalEmployeeNumber,
              value: _orNull(personal.employeeNumber),
            ),
          ],
        ),
        _Section(
          children: [
            PersonalInfoRow(
              label: l10n.personalMobilePhone,
              value: personal.mobilePhone,
            ),
            PersonalInfoRow(
              label: l10n.personalWorkPhone,
              value: workPhone == null
                  ? null
                  : ext == null
                  ? workPhone
                  : '$workPhone (${l10n.personalPhoneExt} $ext)',
            ),
            PersonalInfoRow(
              label: l10n.personalHomePhone,
              value: personal.homePhone,
            ),
          ],
        ),
        _Section(
          children: [
            PersonalInfoRow(
              label: l10n.personalDepartment,
              value: personal.departmentName,
            ),
            PersonalInfoRow(
              label: l10n.personalManager,
              value: personal.managerName,
            ),
            PersonalInfoRow(
              label: l10n.personalHireDate,
              value: hireDate == null ? null : PersonalInfoCopy.date(hireDate),
            ),
          ],
        ),
        heightBx(h: 8),
        customText(
          l10n.personalEmergencyContacts,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        heightBx(h: 10),
        if (personal.emergencyContacts.isEmpty)
          customText(
            l10n.personalNoEmergencyContacts,
            fontSize: 14,
            color: AppColors.subTitle,
          )
        else
          for (final contact in personal.emergencyContacts)
            EmergencyContactCard(contact: contact),
        heightBx(h: 24),
        customText(
          l10n.personalAskHrToFix,
          fontSize: 13,
          color: AppColors.subTitle,
          alight: TextAlign.center,
          maxLine: 3,
        ),
      ],
    );
  }

  static String? _orNull(String value) => value.isEmpty ? null : value;
}

class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: children),
    );
  }
}
