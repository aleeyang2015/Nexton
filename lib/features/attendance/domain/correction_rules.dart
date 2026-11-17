import '../../../core/constants/app_constants.dart';
import '../../../core/errors/validation_codes.dart';
import '../../profile/domain/entities/shift_detail.dart';
import 'entities/time_correction_type.dart';

/// The window a corrected time must sit in: minutes from the corrected
/// day's midnight, [to] past 1440 for a part that runs into the next day.
class CorrectionWindow {
  const CorrectionWindow({
    required this.from,
    required this.to,
    this.overnight = false,
  });

  final int from;
  final int to;

  /// The part runs past midnight (its end is on the next day).
  final bool overnight;

  /// Where [time] (a time of day) falls on the corrected day's clock: the
  /// same day, the next (a night part's 05:50), or the evening before (a
  /// 00:10 part's 23:50 early clock-in), whichever puts it in the window.
  /// Outside it on every day, it is left where an overnight part's times
  /// go: after midnight when before the start, else the same day.
  int place(Duration time, {required int startMinutes}) {
    final t = time.inMinutes;
    for (final candidate in [t, t + 1440, t - 1440]) {
      if (candidate >= from && candidate <= to) return candidate;
    }
    return overnight && t < startMinutes ? t + 1440 : t;
  }
}

/// The "forgot to scan" rules the form checks before sending (#43), the ones
/// the server would refuse anyway: how far back, which times each type
/// needs, and that each time sits in the chosen part's window. Plain Dart.
class CorrectionRules {
  const CorrectionRules._();

  /// The dates that may be corrected: from today minus
  /// [AppConstants.timeCorrectionMaxAgeDays] (owner's decision 16: 30) to
  /// today. No future dates.
  static ({DateTime earliest, DateTime latest}) lookBack(DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    return (
      earliest: DateTime(
        day.year,
        day.month,
        day.day - AppConstants.timeCorrectionMaxAgeDays,
      ),
      latest: day,
    );
  }

  /// Whether [date] may be corrected on [today]: inside [lookBack].
  static bool inLookBack(DateTime date, DateTime today) {
    final range = lookBack(today);
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(range.earliest) && !day.isAfter(range.latest);
  }

  /// A link's `YYYY-MM-DD`, read strictly: null for any other shape, or a
  /// date that does not stay itself (`2026-10-32`, `2026-13-01`).
  static DateTime? parseDate(String? text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text ?? '');
    if (match == null) return null;
    final y = int.parse(match[1]!);
    final m = int.parse(match[2]!);
    final d = int.parse(match[3]!);
    final date = DateTime(y, m, d);
    return date.year == y && date.month == m && date.day == d ? date : null;
  }

  /// [part]'s window on [date] (its weekday row's times and minutes when
  /// HR set one): from its start less the early minutes to its end plus the
  /// late minutes. An overnight part (it ends next day, or its end is not
  /// after its start) has its end on the next day. Null when the part's
  /// times are not known: the server then decides.
  static CorrectionWindow? window(ShiftDetail part, DateTime date) {
    final times = part.timesOn(date);
    final start = _minutesOf(times.start);
    final end = _minutesOf(times.end);
    if (start == null || end == null) return null;
    final minutes = part.minutesOn(date);
    // Overnight as the server decides it: the end is not after the start
    // (`ends_next_day` is not what it goes by).
    final overnight = end <= start;
    final endOn = overnight ? end + 1440 : end;
    return CorrectionWindow(
      from: start - minutes.early,
      to: endOn + minutes.late,
      overnight: overnight,
    );
  }

  /// What is wrong with the times, as a [ValidationCode], or null. In the
  /// server's order: a time the type needs is missing; a time outside the
  /// part's window; the clock-out not after the clock-in.
  ///
  /// `wrong_time` needs at least one of the two. [part] null (not known)
  /// skips the window check.
  static String? check({
    required TimeCorrectionType type,
    required Duration? clockIn,
    required Duration? clockOut,
    required ShiftDetail? part,
    required DateTime date,
  }) {
    final inTime = type.needsClockIn ? clockIn : null;
    final outTime = type.needsClockOut ? clockOut : null;
    final missing = switch (type) {
      TimeCorrectionType.forgotClockIn => inTime == null,
      TimeCorrectionType.forgotClockOut => outTime == null,
      TimeCorrectionType.both => inTime == null || outTime == null,
      TimeCorrectionType.wrongTime => inTime == null && outTime == null,
    };
    if (missing) return ValidationCode.correctionTimeRequired;

    final window = part == null ? null : CorrectionRules.window(part, date);
    final start = part == null ? null : _minutesOf(part.timesOn(date).start);
    int placed(Duration t) => window == null || start == null
        ? t.inMinutes
        : window.place(t, startMinutes: start);

    if (window != null) {
      for (final t in [inTime, outTime]) {
        if (t == null) continue;
        final at = placed(t);
        if (at < window.from || at > window.to) {
          return ValidationCode.correctionOutsideWindow;
        }
      }
    }

    if (inTime != null &&
        outTime != null &&
        placed(outTime) <= placed(inTime)) {
      return ValidationCode.correctionInvalidTimes;
    }
    return null;
  }

  /// `HH:mm` of [minutes] past midnight (past 1440 counts from the next
  /// midnight), with Latin digits.
  static String hhmm(int minutes) {
    final m = minutes % 1440;
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final mm = (m % 60).toString().padLeft(2, '0');
    return '$h:$mm';
  }

  static int? _minutesOf(String? raw) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw ?? '');
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }
}
