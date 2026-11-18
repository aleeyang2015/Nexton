import '../../../../l10n/generated/app_localizations.dart';

/// The personal page's words (#58).
abstract final class PersonalInfoCopy {
  /// `dd/MM/yyyy`, Latin digits as everywhere else in the App.
  static String date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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
