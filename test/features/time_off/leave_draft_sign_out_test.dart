import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:next_on/core/errors/failure.dart';
import 'package:next_on/core/upload/domain/local_file.dart';
import 'package:next_on/core/upload/upload_providers.dart';
import 'package:next_on/core/utils/result.dart';
import 'package:next_on/features/auth/domain/entities/auth_session.dart';
import 'package:next_on/features/auth/presentation/providers/auth_session_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_notifier.dart';
import 'package:next_on/features/time_off/presentation/providers/leave_request_form_state.dart';
import 'package:next_on/features/time_off/time_off_providers.dart';

import '../../support/auth_test_doubles.dart';
import '../../support/leave_test_doubles.dart';
import '../../support/upload_test_doubles.dart';

/// A leave draft belongs to the user who wrote it (#83): on a shared phone
/// the next login must not find the last user's dates, reason or files.
void main() {
  /// Who is signed in, as the form sees it; null is signed out.
  final signedInAs = StateProvider<String?>((ref) => 'user-a');

  late ProviderContainer container;
  late FakeLeaveRepository repository;
  late FakeUploads uploads;

  setUp(() {
    repository = FakeLeaveRepository();
    uploads = FakeUploads();
    container = ProviderContainer(
      overrides: [
        leaveRepositoryProvider.overrideWithValue(repository),
        uploadRepositoryProvider.overrideWithValue(uploads),
        leaveDraftOwnerProvider.overrideWith((ref) => ref.watch(signedInAs)),
      ],
    );
    addTearDown(container.dispose);
  });

  LeaveRequestFormNotifier form([String? id]) =>
      container.read(leaveRequestFormNotifierProvider(id).notifier);
  LeaveRequestFormState state([String? id]) =>
      container.read(leaveRequestFormNotifierProvider(id));

  /// User A's unsent draft: a type, two days, a reason and a file.
  Future<void> fillDraft() async {
    form()
      ..setLeaveType('lt-annual')
      ..setDates([DateTime(2026, 11, 18), DateTime(2026, 11, 19)])
      ..setReason('Doctor');
    await form().addFile(
      const LocalFile(path: '/phone/cert.jpg', name: 'cert.jpg'),
    );
    expect(state().files, hasLength(1));
  }

  /// A sign-out, then a sign-in some time later, with no screen reading the
  /// form in between (the signed-in screens are gone).
  Future<void> signOutThenInAs(String user) async {
    container.read(signedInAs.notifier).state = null;
    await Future<void>.delayed(Duration.zero);
    container.read(signedInAs.notifier).state = user;
    await Future<void>.delayed(Duration.zero);
  }

  test('the next user to sign in gets an empty form, not the last user\'s '
      'draft', () async {
    await fillDraft();

    await signOutThenInAs('user-b');

    expect(state(), const LeaveRequestFormState());
  });

  test('signing out alone already drops it', () async {
    await fillDraft();

    container.read(signedInAs.notifier).state = null;

    expect(state(), const LeaveRequestFormState());
  });

  test('the same user signing in again starts clean too: a sign-out ends '
      'the draft', () async {
    await fillDraft();

    await signOutThenInAs('user-a');

    expect(state(), const LeaveRequestFormState());
  });

  test('a form editing a request is dropped as well', () async {
    form('req-7').seed(sampleLeaveRequest(id: 'req-7', reason: 'Trip'));
    expect(state('req-7').isEditing, isTrue);

    await signOutThenInAs('user-b');

    expect(state('req-7'), const LeaveRequestFormState());
  });

  test('while the same user stays signed in the draft is kept, as before: '
      'it outlives the screen', () async {
    await fillDraft();

    // Nothing watches the form (the user is on another screen).
    await Future<void>.delayed(Duration.zero);

    expect(state().reason, 'Doctor');
    expect(state().dates, hasLength(2));
    expect(state().files, hasLength(1));
  });

  test('an upload still running when the next user has signed in does not '
      'land in their form, even before they open it', () async {
    uploads.hold = Completer<void>();
    final hold = uploads.hold!;
    final uploading = form().addFile(
      const LocalFile(path: '/phone/cert.jpg', name: 'cert.jpg'),
    );

    // Nobody reads the form in between: the next user has not opened it.
    await signOutThenInAs('user-b');
    hold.complete();
    await uploading;

    expect(state().files, isEmpty);
    expect(state().uploadingFiles, 0);
    expect(state().fileFailure, isNull);
  });

  test('an upload that fails after the next user signed in says nothing on '
      'their form', () async {
    uploads
      ..hold = Completer<void>()
      ..answer = const Result.failure(Failure.network(message: 'offline'));
    final hold = uploads.hold!;
    final uploading = form().addFile(
      const LocalFile(path: '/phone/cert.jpg', name: 'cert.jpg'),
    );

    await signOutThenInAs('user-b');
    hold.complete();
    await uploading;

    expect(state().fileFailure, isNull);
    expect(state().uploadingFiles, 0);
  });

  test('a send still on its way when the next user has started their own '
      'draft leaves that draft alone', () async {
    await fillDraft();
    repository.holdSubmit = Completer<void>();
    final hold = repository.holdSubmit!;
    final sending = form().submit();

    await signOutThenInAs('user-b');
    form()
      ..setLeaveType('lt-sick')
      ..setReason('B\'s own');
    hold.complete();

    expect(await sending, isFalse);
    expect(state().reason, 'B\'s own');
    expect(state().leaveTypeId, 'lt-sick');
    expect(state().submission.hasError, isFalse);
    expect(state().submission.isLoading, isFalse);
  });

  test('wired to the real session: signing out, then another user signing '
      'in, empties the form', () async {
    final session = _Session();
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => session),
        leaveRepositoryProvider.overrideWithValue(repository),
        uploadRepositoryProvider.overrideWithValue(uploads),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authSessionProvider.future);
    c.read(leaveRequestFormNotifierProvider(null).notifier).setReason('A');
    expect(c.read(leaveRequestFormNotifierProvider(null)).reason, 'A');

    session.set(const AuthSession.unauthenticated());
    await Future<void>.delayed(Duration.zero);
    session.set(AuthSession.signedIn(testUser(id: 'user-b')));
    await Future<void>.delayed(Duration.zero);

    expect(
      c.read(leaveRequestFormNotifierProvider(null)),
      const LeaveRequestFormState(),
    );
  });

  test('the same user\'s details read again (the App resumes) keep the '
      'draft', () async {
    final session = _Session();
    final c = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWith(() => session),
        leaveRepositoryProvider.overrideWithValue(repository),
        uploadRepositoryProvider.overrideWithValue(uploads),
      ],
    );
    addTearDown(c.dispose);
    await c.read(authSessionProvider.future);
    c.read(leaveRequestFormNotifierProvider(null).notifier).setReason('A');

    // A new copy of the same user, as `/auth/me` gives on resume.
    session.set(AuthSession.signedIn(testUser(modules: const ['core_hr'])));
    await Future<void>.delayed(Duration.zero);

    expect(c.read(leaveRequestFormNotifierProvider(null)).reason, 'A');
  });

  group('whose draft it is follows the session', () {
    ProviderContainer withSession(AuthSessionNotifier Function() session) {
      final c = ProviderContainer(
        overrides: [authSessionProvider.overrideWith(session)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('signed in: the user\'s id', () async {
      final c = withSession(_SignedIn.new);
      await c.read(authSessionProvider.future);

      expect(c.read(leaveDraftOwnerProvider), testUser().id);
    });

    test('signed out: no one', () async {
      final c = withSession(_SignedOut.new);
      await c.read(authSessionProvider.future);

      expect(c.read(leaveDraftOwnerProvider), isNull);
    });
  });
}

/// A session a test moves by hand.
class _Session extends AuthSessionNotifier {
  @override
  Future<AuthSession> build() async => AuthSession.signedIn(testUser());

  void set(AuthSession session) => state = AsyncValue.data(session);
}

class _SignedOut extends AuthSessionNotifier {
  @override
  Future<AuthSession> build() async => const AuthSession.unauthenticated();
}

class _SignedIn extends AuthSessionNotifier {
  @override
  Future<AuthSession> build() async => AuthSession.signedIn(testUser());
}
