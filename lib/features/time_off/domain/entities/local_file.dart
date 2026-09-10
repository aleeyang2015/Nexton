import 'package:equatable/equatable.dart';

/// A file the user has picked off the device but not yet uploaded — just the
/// on-disk [path] and the original [name]. The picker plugin lives in the
/// presentation layer; the domain only ever sees this plain pair.
class LocalFile extends Equatable {
  final String path;
  final String name;

  const LocalFile({required this.path, required this.name});

  @override
  List<Object?> get props => [path, name];
}
