import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_session_notifier.dart';
import '../../domain/approver_access.dart';

/// Hands an employee's own page of someone else's request over to the
/// approver's page (#53: a push opens the by-id page; the push carries no
/// owner). Once [loaded] holds the request, already or later, and its owner
/// ([ownerOf]) is not the user and the user may open the approver's page
/// ([ApproverAccess.opensAsApprover]), this page is replaced by [location]
/// with the request as `extra`.
///
/// At most once, and only while this page is on top: GoRouter's `replace`
/// acts on the top of the stack, so a page under another one waits until it
/// is on top again.
class ApproverHandOver<T extends Object> extends ConsumerStatefulWidget {
  const ApproverHandOver({
    super.key,
    required this.loaded,
    required this.ownerOf,
    required this.location,
    required this.child,
    this.attendance = false,
  });

  final ProviderListenable<T?> loaded;
  final String? Function(T request) ownerOf;
  final String location;
  final bool attendance;
  final Widget child;

  @override
  ConsumerState<ApproverHandOver<T>> createState() =>
      _ApproverHandOverState<T>();
}

class _ApproverHandOverState<T extends Object>
    extends ConsumerState<ApproverHandOver<T>> {
  T? _latest;
  bool _ready = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<T?>(widget.loaded, (_, next) {
      _latest = next;
      if (_ready) _tryHandOver();
    }, fireImmediately: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ready = true;
    // Depends on the route, so it runs again when this page comes on top.
    _tryHandOver();
  }

  bool get _onTop => ModalRoute.of(context)?.isCurrent ?? false;

  void _tryHandOver() {
    final request = _latest;
    if (_done || request == null || !_onTop) return;
    final user = ref.read(authSessionProvider).valueOrNull?.user;
    if (!ApproverAccess.opensAsApprover(
      ownerId: widget.ownerOf(request),
      user: user,
      attendance: widget.attendance,
    )) {
      return;
    }
    _done = true;
    // Not during a build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_onTop) {
        _done = false;
        return;
      }
      context.replace(widget.location, extra: request);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Registers the dependency on the route (see didChangeDependencies).
    ModalRoute.of(context);
    return widget.child;
  }
}
