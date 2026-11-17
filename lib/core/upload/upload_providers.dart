import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';
import 'data/upload_remote_data_source.dart';
import 'data/upload_repository_impl.dart';
import 'domain/upload_attachment_usecase.dart';
import 'domain/upload_repository.dart';

// File upload (`POST /uploads`), shared by every feature that sends a file:
// leave documents, off-site proof, the "forgot to scan" photo.

final uploadRemoteDataSourceProvider = Provider<UploadRemoteDataSource>(
  (ref) => UploadRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final uploadRepositoryProvider = Provider<UploadRepository>(
  (ref) =>
      UploadRepositoryImpl(remote: ref.watch(uploadRemoteDataSourceProvider)),
);

final uploadAttachmentUseCaseProvider = Provider<UploadAttachmentUseCase>(
  (ref) => UploadAttachmentUseCase(ref.watch(uploadRepositoryProvider)),
);
