import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/network/api_client.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/attendance/attendance_providers.dart';
import 'package:next_on/features/attendance/data/datasources/offsite_remote_data_source.dart';
import 'package:next_on/features/attendance/domain/entities/attendance_day.dart';
import 'package:next_on/features/attendance/domain/entities/offsite_method.dart';
import 'package:next_on/features/attendance/domain/next_punch.dart';
import 'package:next_on/features/attendance/domain/usecases/get_waiting_offsite_usecase.dart';
import 'package:next_on/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:next_on/features/attendance/presentation/widgets/attendance_copy.dart';
import 'package:next_on/l10n/generated/app_localizations_en.dart';
import 'package:next_on/l10n/generated/app_localizations_lo.dart';

import '../../support/attendance_test_doubles.dart';

class _StubAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [
          {
            'id': 'off-1',
            'method': 'check_in',
            'status': 'pending',
            'scan_timestamp': '2026-11-17 08:00:00',
            'scan_date': '2026-11-17',
            'session_order': 1,
            'reason': 'Client visit',
            'created_at': '2026-11-17T01:00:00Z',
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A waiting off-site check-in on the card (#41).
void main() {
  group('reading the waiting scans', () {
    test(
      'GET offsite-requests/my?status=pending&month=YYYY-MM, each row read',
      () async {
        final adapter = _StubAdapter();
        final source = OffsiteRemoteDataSourceImpl(
          ApiClient(dio: Dio()..httpClientAdapter = adapter),
        );

        final rows = await source.waiting(month: '2026-11');

        expect(adapter.last!.path, endsWith('/offsite-requests/my'));
        expect(adapter.last!.queryParameters['status'], 'pending');
        expect(adapter.last!.queryParameters['month'], '2026-11');
        expect(rows.single.method, OffsiteMethod.checkIn);
        expect(rows.single.sessionOrder, 1);
        expect(rows.single.scanTimestamp, DateTime(2026, 11, 17, 8));
      },
    );

    test('this month; on the 1st, last month too (a night shift from the '
        'evening before)', () async {
      final repository = FakeOffsiteRepository();
      final use = GetWaitingOffsiteUseCase(repository);

      await use(DateTime(2026, 11, 17));
      expect(repository.waitingMonths, ['2026-11']);

      repository.waitingMonths.clear();
      await use(DateTime(2026, 1, 1, 6));
      expect(repository.waitingMonths, ['2026-01', '2025-12']);
    });
  });

  group('the card', () {
    late FakeAttendanceRepository attendance;
    late FakeOffsiteRepository offsite;
    late ProviderContainer container;

    setUp(() {
      attendance = FakeAttendanceRepository();
      offsite = FakeOffsiteRepository();
      container = ProviderContainer(
        overrides: [
          attendanceRepositoryProvider.overrideWithValue(attendance),
          offsiteRepositoryProvider.overrideWithValue(offsite),
          punchLocationSourceProvider.overrideWithValue(
            FakePunchLocationSource(),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    Future<AttendanceNotifier> ready() async {
      container.listen(attendanceNotifierProvider, (_, _) {});
      final notifier = container.read(attendanceNotifierProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      return notifier;
    }

    final now = DateTime.now();
    final checkIn = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(now.year, now.month, now.day, 8, 5),
    );

    test(
      'a waiting check-in: the slide says clock out, as an off-site one',
      () async {
        offsite.waitingResult = Result.success([checkIn]);
        await ready();

        final state = container.read(attendanceNotifierProvider);
        expect(state.nextAction, ClockAction.clockOut);
        expect(state.next, isA<OffsiteClockOut>());
      },
    );

    test('the three reads start together: each before any answers', () async {
      final today = Completer<void>();
      final waiting = Completer<void>();
      attendance.holdToday = today;
      offsite.holdWaiting = waiting;

      await ready();

      expect(attendance.todayCalls, 1);
      expect(attendance.openOtCalls, 1);
      expect(offsite.waitingMonths, hasLength(1));
      today.complete();
      waiting.complete();
    });

    test(
      'a failed waiting read: the card goes by the record, no error',
      () async {
        offsite.waitingResult = const Result.failure(
          Failure.network(message: 'offline'),
        );
        await ready();

        final state = container.read(attendanceNotifierProvider);
        expect(state.today.hasError, isFalse);
        expect(state.waitingOffsite, isEmpty);
        expect(state.nextAction, ClockAction.clockIn);
      },
    );

    test('each load (a resume, after a punch) reads the waiting scans again; '
        'the per-second check does not', () async {
      final notifier = await ready();
      expect(offsite.waitingMonths, hasLength(1));

      for (var i = 0; i < 5; i++) {
        notifier.refreshIfNewDay();
      }
      await Future<void>.delayed(Duration.zero);
      expect(offsite.waitingMonths, hasLength(1));

      await notifier.loadToday();
      expect(offsite.waitingMonths, hasLength(2));
    });

    test(
      'approved meanwhile: the record has the open session and wins',
      () async {
        offsite.waitingResult = Result.success([checkIn]);
        attendance.today = Result.success(_openToday());
        await ready();

        expect(
          container.read(attendanceNotifierProvider).next,
          isA<NormalClockOut>(),
        );
      },
    );
  });

  group('the card\'s line', () {
    final checkIn = waitingOffsite(
      method: OffsiteMethod.checkIn,
      at: DateTime(2026, 11, 17, 8, 5),
    );

    test('a check-in to clock out of: its time, waiting', () {
      expect(
        AttendanceCopy.offsiteWaiting(
          AppLocalizationsLo(),
          OffsiteClockOut(checkIn),
        ),
        'ລົງເວລາເຂົ້ານອກພື້ນທີ່ເວລາ 08:05: ລໍຖ້າອະນຸມັດ',
      );
      expect(
        AttendanceCopy.offsiteWaiting(
          AppLocalizationsEn(),
          OffsiteClockOut(checkIn),
        ),
        'Check-in outside the area at 08:05: waiting for approval',
      );
    });

    test('both waiting: says so', () {
      expect(
        AttendanceCopy.offsiteWaiting(
          AppLocalizationsLo(),
          WaitingBoth(checkIn),
        ),
        'ລົງເວລາເຂົ້າ ແລະ ອອກ ນອກພື້ນທີ່: ລໍຖ້າອະນຸມັດ',
      );
    });

    test('a normal punch: no line', () {
      expect(
        AttendanceCopy.offsiteWaiting(
          AppLocalizationsEn(),
          const NormalClockIn(),
        ),
        isNull,
      );
    });
  });
}

/// Today's record with a session clocked in at 08:00 and still open.
AttendanceDay _openToday() {
  final now = DateTime.now();
  return AttendanceDay(
    sessions: [
      AttendanceSession(
        partStartTime: '08:00',
        partEndTime: '12:00',
        clockIn: DateTime(now.year, now.month, now.day, 8),
      ),
    ],
  );
}
