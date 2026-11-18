import '../../../../l10n/generated/app_localizations.dart';

/// The personal page's words (#58).
abstract final class PersonalInfoCopy {
  /// `dd/MM/yyyy`, Latin digits as everywhere else in the App.
  static String date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';

  /// The work phone and its extension: "021 412 000 (Ext. 12)", either one
  /// alone, or null when HR has neither.
  static String? workPhone(
    AppLocalizations l10n,
    String? phone,
    String? extension,
  ) {
    final ext = extension == null
        ? null
        : '${l10n.personalPhoneExt} $extension';
    if (phone == null) return ext;
    return ext == null ? phone : '$phone ($ext)';
  }

  /// The web's relationship values in the App's words; anything else as HR
  /// typed it.
  static String relationship(AppLocalizations l10n, String value) =>
      switch (value.toLowerCase()) {
        'spouse' => l10n.relationshipSpouse,
        'parent' => l10n.relationshipParent,
        'sibling' => l10n.relationshipSibling,
        'child' => l10n.relationshipChild,
        'friend' => l10n.relationshipFriend,
        'other' => l10n.relationshipOther,
        _ => value,
      };
}
