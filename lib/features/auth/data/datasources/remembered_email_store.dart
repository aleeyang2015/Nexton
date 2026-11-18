import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';

/// The email "Remember my email" keeps for the next sign-in on this phone
/// (#60). In SharedPreferences, not the keychain: it shows on the login
/// screen anyway. It never throws: a failed read is "nothing saved", and a
/// failed write is ignored, so the login itself can never fail because of
/// it.
class RememberedEmailStore {
  final SharedPreferences _prefs;

  RememberedEmailStore(this._prefs);

  /// The saved email, or null.
  String? read() {
    try {
      final email = _prefs.getString(AppConstants.rememberedEmailKey)?.trim();
      return email == null || email.isEmpty ? null : email;
    } catch (_) {
      return null;
    }
  }

  /// Keeps [email] (trimmed, as the login sends it) for the next sign-in.
  Future<void> save(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return clear();
    try {
      await _prefs.setString(AppConstants.rememberedEmailKey, trimmed);
    } catch (_) {
      // Not saved: the next sign-in starts empty. Nothing else to do.
    }
  }

  /// Forgets the saved email.
  Future<void> clear() async {
    try {
      await _prefs.remove(AppConstants.rememberedEmailKey);
    } catch (_) {
      // Left as it was.
    }
  }
}
