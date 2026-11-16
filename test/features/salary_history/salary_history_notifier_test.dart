import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/salary_history/domain/entities/payslip_record.dart';
import 'package:next_on/features/salary_history/presentation/providers/salary_history_notifier.dart';
import 'package:next_on/features/salary_history/presentation/providers/salary_history_state.dart';
import 'package:next_on/features/salary_history/salary_history_providers.dart';

import '../../support/salary_test_doubles.dart';

void main() {
  final thisYear = DateTime.now().year;
  late FakeSalaryRepository repository;
  late ProviderContainer container;

  final paid = samplePayslipRecord(id: 'p-paid', periodMonth: 9);
  final approved = samplePayslipRecord(
    id: 'p-approved',
    periodMonth: 10,
    status: PayslipRunStatus.approved,
    paymentStatus: PayslipPaymentStatus.pending,
    paid: false,
  );
  final failed = samplePayslipRecord(
    id: 'p-failed',
    periodMonth: 8,
    status: PayslipRunStatus.paid,
    paymentStatus: PayslipPaymentStatus.failed,
    paid: false,
  );

  setUp(() {
    repository = FakeSalaryRepository()
      ..myPayslipsResult = Result.success([approved, paid, failed]);
    container = ProviderContainer(
      overrides: [salaryRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  SalaryHistoryState state() => container.read(salaryHistoryNotifierProvider);
  SalaryHistoryNotifier notifier() =>
      container.read(salaryHistoryNotifierProvider.notifier);

  Future<void> settle() async {
    container.listen(salaryHistoryNotifierProvider, (_, _) {});
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('loading', () {
    test('asks for this year\'s payslips and keeps the server\'s order',
        () async {
      await settle();

      expect(repository.myPayslipsYears, [thisYear]);
      expect(state().year, thisYear);
      expect(state().all.map((p) => p.id), ['p-approved', 'p-paid', 'p-failed']);
    });

    test('no payslips (a login with no employee record) is an empty list, '
        'not an error', () async {
      repository.myPayslipsResult = const Result.success([]);

      await settle();

      expect(state().payslips.hasError, isFalse);
      expect(state().all, isEmpty);
    });

    test('a failed load is kept as the failure, and retry asks again',
        () async {
      const offline = Failure.network(message: 'offline');
      repository.myPayslipsResult = const Result.failure(offline);
      await settle();
      expect(state().payslips.error, offline);

      repository.myPayslipsResult = Result.success([paid]);
      notifier().retry();
      await settle();

      expect(repository.myPayslipsYears, [thisYear, thisYear]);
      expect(state().all, [paid]);
    });

    test('a company without payroll: the refusal keeps its code', () async {
      const refusal = Failure.validation(
        message: 'payroll is not active',
        code: 'MODULE_NOT_ACTIVE',
      );
      repository.myPayslipsResult = const Result.failure(refusal);

      await settle();

      expect(state().payslips.error, refusal);
    });
  });

  group('the year', () {
    test('stepping back asks for that year and clears the list', () async {
      await settle();

      notifier().previousYear();
      expect(state().year, thisYear - 1);
      expect(state().payslips.isLoading, isTrue);
      await settle();

      expect(repository.myPayslipsYears, [thisYear, thisYear - 1]);
    });

    test('there is no year after this one', () async {
      await settle();

      notifier().nextYear();
      await settle();

      expect(state().year, thisYear);
      expect(repository.myPayslipsYears, [thisYear]);
    });

    test('an answer for a year the user has left is dropped', () async {
      final slow = Completer<void>();
      repository
        ..holdMyPayslips = slow
        ..myPayslipsByYear = (year) => Result.success([
          samplePayslipRecord(id: 'of-$year'),
        ]);
      container.listen(salaryHistoryNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      // Both years are asked for while neither has answered.
      notifier().previousYear();
      await Future<void>.delayed(Duration.zero);
      slow.complete();
      await settle();

      expect(state().year, thisYear - 1);
      expect(state().all.map((p) => p.id), ['of-${thisYear - 1}']);
    });

    test('an older answer for the same year, arriving late with a failure, '
        'does not replace the list that is showing', () async {
      final first = Completer<Result<List<PayslipRecord>>>();
      final late = _QueuedRepository([first.future], Result.success([paid]));
      final c = ProviderContainer(
        overrides: [salaryRepositoryProvider.overrideWithValue(late)],
      );
      addTearDown(c.dispose);
      c.listen(salaryHistoryNotifierProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);

      // Back a year and forward again: this year is asked for a second time
      // while its first answer is still on its way.
      c.read(salaryHistoryNotifierProvider.notifier).previousYear();
      c.read(salaryHistoryNotifierProvider.notifier).nextYear();
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c.read(salaryHistoryNotifierProvider).all, [paid]);

      first.complete(const Result.failure(Failure.network(message: 'offline')));
      for (var i = 0; i < 4; i++) {
        await Future<void>.delayed(Duration.zero);
      }

      final after = c.read(salaryHistoryNotifierProvider);
      expect(after.payslips.hasError, isFalse);
      expect(after.all, [paid]);
    });

    test('the chosen chip is kept across a year switch; the open rows are '
        'not', () async {
      await settle();
      notifier()
        ..setFilter(SalaryHistoryFilter.paid)
        ..toggleExpanded(0);

      notifier().previousYear();
      await settle();

      expect(state().filter, SalaryHistoryFilter.paid);
      expect(state().expandedIndexes, isEmpty);
    });
  });

  group('the chips', () {
    test('All shows every payslip of the year', () async {
      await settle();

      expect(state().filter, SalaryHistoryFilter.all);
      expect(state().filtered, [approved, paid, failed]);
    });

    test('Paid keeps the payslips whose run is paid, and sends no request',
        () async {
      await settle();

      notifier().setFilter(SalaryHistoryFilter.paid);

      expect(state().filtered.map((p) => p.id), ['p-paid', 'p-failed']);
      // The summary card's source is untouched by the chip.
      expect(state().all, hasLength(3));
      expect(repository.myPayslipsYears, [thisYear]);
    });

    test('Paid goes by the run\'s status, as the issue says: a paid run '
        'whose payment failed is listed (with its red pill), an approved '
        'one is not', () async {
      final approvedFailed = samplePayslipRecord(
        id: 'p-approved-failed',
        status: PayslipRunStatus.approved,
        paymentStatus: PayslipPaymentStatus.failed,
        paid: false,
      );
      repository.myPayslipsResult = Result.success([failed, approvedFailed]);
      await settle();

      notifier().setFilter(SalaryHistoryFilter.paid);

      expect(state().filtered.map((p) => p.id), ['p-failed']);
    });

    test('there are two chips: no "pending"', () {
      expect(SalaryHistoryFilter.values, [
        SalaryHistoryFilter.all,
        SalaryHistoryFilter.paid,
      ]);
    });

    test('changing the chip closes the open rows', () async {
      await settle();
      notifier().toggleExpanded(1);
      expect(state().expandedIndexes, {1});

      notifier().setFilter(SalaryHistoryFilter.paid);

      expect(state().expandedIndexes, isEmpty);
    });
  });
}

/// Answers the first calls from [queue], in order, and every later one with
/// [then].
class _QueuedRepository extends FakeSalaryRepository {
  _QueuedRepository(this.queue, this.then);

  final List<Future<Result<List<PayslipRecord>>>> queue;
  final Result<List<PayslipRecord>> then;

  @override
  FutureResult<List<PayslipRecord>> myPayslips(int year) =>
      queue.isEmpty ? Future.value(then) : queue.removeAt(0);
}
