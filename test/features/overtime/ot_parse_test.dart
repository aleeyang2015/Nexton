import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/features/overtime/data/models/ot_parse.dart';

/// The small readers behind the OT models. The server sends two time
/// formats in one answer, and fields of the wrong type or none at all; none
/// of that may crash a read.
void main() {
  group('wallClock: "YYYY-MM-DD HH:MM:SS", Lao wall-clock time, no zone', () {
    test('"2026-11-11 09:30:00" is 09:30 on 11 November, on the phone\'s '
        'clock: not 16:30, not 02:30', () {
      final time = OtJson.wallClock('2026-11-11 09:30:00')!;

      expect(time.isUtc, isFalse);
      expect(
        [time.year, time.month, time.day, time.hour, time.minute, time.second],
        [2026, 11, 11, 9, 30, 0],
      );
    });

    test('a value that does carry a zone is read as that moment', () {
      final time = OtJson.wallClock('2026-11-11T09:30:00+07:00')!;

      expect(time.isUtc, isFalse);
      expect(
        time.toUtc(),
        DateTime.utc(2026, 11, 11, 2, 30),
      );
    });

    test('a time that does not exist is null, not rolled over', () {
      expect(OtJson.wallClock('2026-11-11 25:99:00'), isNull);
      expect(OtJson.wallClock('2026-11-11 24:00:00'), isNull);
      expect(OtJson.wallClock('2026-02-30 09:00:00'), isNull);
    });

    test('without seconds, or with a T, it is still read', () {
      expect(OtJson.wallClock('2026-11-11 09:30'), DateTime(2026, 11, 11, 9, 30));
      expect(
        OtJson.wallClock('2026-11-11T09:30:00'),
        DateTime(2026, 11, 11, 9, 30),
      );
    });

    test('null, empty, garbage and a number are null', () {
      expect(OtJson.wallClock(null), isNull);
      expect(OtJson.wallClock(''), isNull);
      expect(OtJson.wallClock('yesterday'), isNull);
      expect(OtJson.wallClock(20261111), isNull);
    });
  });

  group('instant: RFC 3339 with its offset', () {
    test('"2026-11-14T18:00:00+07:00" is that moment, shown on the phone\'s '
        'clock', () {
      final time = OtJson.instant('2026-11-14T18:00:00+07:00')!;

      expect(time.isUtc, isFalse);
      expect(time.toUtc(), DateTime.utc(2026, 11, 14, 11));
    });

    test('null, empty, garbage and a number are null', () {
      expect(OtJson.instant(null), isNull);
      expect(OtJson.instant(''), isNull);
      expect(OtJson.instant('soon'), isNull);
      expect(OtJson.instant(1731582000), isNull);
    });
  });

  group('date: a calendar day, no time', () {
    test('"2026-11-14" is 14 November, midnight, with no zone shift', () {
      final day = OtJson.date('2026-11-14')!;

      expect(day, DateTime(2026, 11, 14));
      expect(day.isUtc, isFalse);
    });

    test('a day sent with a time and an offset keeps its own date', () {
      expect(OtJson.date('2026-11-14T23:30:00+07:00'), DateTime(2026, 11, 14));
    });

    test('a day that does not exist is null, not rolled over', () {
      expect(OtJson.date('2026-02-30'), isNull);
      expect(OtJson.date('2026-02-29'), isNull);
      expect(OtJson.date('2026-13-45'), isNull);
      expect(OtJson.date('2028-02-29'), DateTime(2028, 2, 29));
    });

    test('null, garbage and a number are null', () {
      expect(OtJson.date(null), isNull);
      expect(OtJson.date('14/11/2026'), isNull);
      expect(OtJson.date(20261114), isNull);
    });
  });

  group('the plain readers never throw', () {
    test('str and nonEmpty', () {
      expect(OtJson.str('a'), 'a');
      expect(OtJson.str(5), isNull);
      expect(OtJson.nonEmpty(''), isNull);
      expect(OtJson.nonEmpty('x'), 'x');
      expect(OtJson.nonEmpty(null), isNull);
    });

    test('intOf: a whole number, or null; never a cast that throws', () {
      expect(OtJson.intOf(3), 3);
      expect(OtJson.intOf(3.0), 3);
      expect(OtJson.intOf(3.7), isNull);
      expect(OtJson.intOf('3'), isNull);
      expect(OtJson.intOf(null), isNull);
      expect(OtJson.intOf(double.nan), isNull);
      expect(OtJson.intOf(double.infinity), isNull);
    });

    test('boolOf: a bool, else the fallback', () {
      expect(OtJson.boolOf(true), isTrue);
      expect(OtJson.boolOf('true'), isFalse);
      expect(OtJson.boolOf(null, fallback: true), isTrue);
    });

    test('objects: the maps of a list, nothing else', () {
      expect(OtJson.objects(null), isEmpty);
      expect(OtJson.objects('x'), isEmpty);
      expect(
        OtJson.objects([
          {'a': 1},
          'x',
          2,
          {'b': 2},
        ]),
        [
          {'a': 1},
          {'b': 2},
        ],
      );
    });

    test('object: a map, or null', () {
      expect(OtJson.object({'id': 'e'}), {'id': 'e'});
      expect(OtJson.object('e'), isNull);
      expect(OtJson.object(null), isNull);
    });
  });
}
