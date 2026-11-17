import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/overtime/domain/entities/ot_request.dart';
import 'package:next_on/features/overtime/overtime_providers.dart';
import 'package:next_on/features/overtime/presentation/providers/ot_detail_notifier.dart';

import '../../support/overtime_test_doubles.dart';

/// One OT request, loaded by its id, for the request page.
void main() {
  late FakeOtRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeOtRepository();
    container = ProviderContainer(
      overrides: [otRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  final provider = otDetailNotifierProvider('ot-1');

  Future<OtRequest> load() {
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  const offline = Failure.network(message: 'offline');
  const gone = Failure.network(message: 'not found', statusCode: 404);

  test('loads the request by its id', () async {
    final ot = await load();

    expect(repository.requestIds, ['ot-1']);
    expect(ot.id, 'ot-1');
  });

  test('a failed first load is the state\'s error', () async {
    repository.requestAnswer = (_) => const Result.failure(offline);

    await expectLater(load(), throwsA(offline));
    expect(container.read(provider).error, offline);
  });

  test('refresh: a new copy replaces the old', () async {
    await load();
    repository.requestAnswer = (id) =>
        Result.success(sampleOt(id, status: OtStatus.approved));

    final failure = await container.read(provider.notifier).refresh();

    expect(failure, isNull);
    expect(container.read(provider).valueOrNull?.status, OtStatus.approved);
  });

  test('refresh that fails for want of signal keeps the request on screen, '
      'and says so', () async {
    await load();
    repository.requestAnswer = (_) => const Result.failure(offline);

    final failure = await container.read(provider.notifier).refresh();

    expect(failure, offline);
    expect(container.read(provider).hasError, isFalse);
    expect(container.read(provider).valueOrNull?.id, 'ot-1');
  });

  test('refresh that says the request is gone (404) replaces it', () async {
    await load();
    repository.requestAnswer = (_) => const Result.failure(gone);

    await container.read(provider.notifier).refresh();

    expect(container.read(provider).error, gone);
  });

  test('an older refresh answering late does not put the old copy back',
      () async {
    await load();
    final slow = Completer<void>();
    repository
      ..holdRequest = slow
      ..requestAnswer = (id) => Result.success(sampleOt(id));
    final first = container.read(provider.notifier).refresh();

    repository.requestAnswer = (id) =>
        Result.success(sampleOt(id, status: OtStatus.cancelled));
    await container.read(provider.notifier).refresh();
    slow.complete();
    await first;

    expect(container.read(provider).valueOrNull?.status, OtStatus.cancelled);
  });

  test('replace shows an answer at once, with no second request', () async {
    await load();

    container
        .read(provider.notifier)
        .replace(sampleOt('ot-1', status: OtStatus.cancelled));

    expect(container.read(provider).valueOrNull?.status, OtStatus.cancelled);
    expect(repository.requestIds, ['ot-1']);
  });

  test('replace with another request\'s copy is ignored', () async {
    await load();

    container.read(provider.notifier).replace(sampleOt('ot-2'));

    expect(container.read(provider).valueOrNull?.id, 'ot-1');
  });

  test('replace overtakes a refresh still on its way', () async {
    await load();
    final slow = Completer<void>();
    repository.holdRequest = slow;
    final pending = container.read(provider.notifier).refresh();

    container
        .read(provider.notifier)
        .replace(sampleOt('ot-1', status: OtStatus.cancelled));
    slow.complete();
    await pending;

    expect(container.read(provider).valueOrNull?.status, OtStatus.cancelled);
  });
}
