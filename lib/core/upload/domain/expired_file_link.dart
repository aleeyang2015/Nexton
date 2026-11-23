import '../../errors/failure.dart';

/// The server's code for a file link opened after its hour (#73).
const String linkExpiredCode = 'LINK_EXPIRED';

/// True when a file download was refused because its link is past its
/// hour: links from `POST /uploads` live one hour from the read that gave
/// them, then answer `403 LINK_EXPIRED`; the request must be read again for
/// a new one.
bool isExpiredDownload(Object? failure) =>
    failure is ValidationFailure && failure.code == linkExpiredCode;
