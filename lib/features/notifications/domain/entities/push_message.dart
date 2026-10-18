import 'package:equatable/equatable.dart';

/// A push from the backend, stripped of Firebase types.
class PushMessage extends Equatable {
  final String? title;
  final String? body;

  /// The push's custom key/value payload.
  final Map<String, dynamic> data;

  const PushMessage({this.title, this.body, this.data = const {}});

  /// Data-only pushes carry nothing to show in a banner.
  bool get hasContent =>
      (title?.isNotEmpty ?? false) || (body?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [title, body, data];
}
