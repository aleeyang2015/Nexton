/// Parsers for the backend's standard JSON envelope.
///
/// Success: `{ "success": true, "data": … }` — `data`/`error`/`meta` are
/// `omitempty`, so a plain success carries no `error` or `meta` key at all.
/// Failure: `{ "success": false, "error": { code, message, details? } }`.
/// A 422 additionally carries top-level `message` and `errors: { field: [msg] }`.
///
/// Everything here tolerates a flat (un-enveloped) body, because a few
/// endpoints answer without the wrapper.
class ApiEnvelope {
  ApiEnvelope._();

  /// Pulls the `data` object out of [body], or returns [body] itself when the
  /// response is flat. Throws [FormatException] when neither shape fits.
  static Map<String, dynamic> unwrapObject(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Expected a JSON object response');
    }

    final data = body['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    // Flat body — but never mistake an error envelope for payload.
    if (body.containsKey('error') || body['success'] == false) {
      throw const FormatException('Response carries an error, not data');
    }

    return Map<String, dynamic>.from(body);
  }
}

/// The `error` object of a failed envelope, plus the Laravel-style 422 fields.
class ApiError {
  final String? code;
  final String? message;

  /// 422 only: `{ field: [message, …] }`, flattened to the first message.
  final Map<String, String> fieldErrors;

  const ApiError({this.code, this.message, this.fieldErrors = const {}});

  /// The field a 422 points at, or null when the error is not field-scoped.
  String? get firstField => fieldErrors.isEmpty ? null : fieldErrors.keys.first;

  /// Best available human-readable message.
  String? get bestMessage =>
      message ?? (fieldErrors.isEmpty ? null : fieldErrors.values.first);

  /// Reads an error body. Returns null when [body] is not a recognisable
  /// error envelope.
  static ApiError? tryParse(dynamic body) {
    if (body is! Map) return null;

    String? code;
    String? message;

    final error = body['error'];
    if (error is Map) {
      code = error['code'] as String?;
      message = error['message'] as String?;
    } else if (error is String) {
      message = error;
    }

    // 422 puts the summary at the top level.
    message ??= body['message'] as String?;

    final fieldErrors = <String, String>{};
    final errors = body['errors'];
    if (errors is Map) {
      errors.forEach((key, value) {
        final text = value is List
            ? value.whereType<String>().firstOrNull
            : value as String?;
        if (text != null) fieldErrors[key.toString()] = text;
      });
    }

    if (code == null && message == null && fieldErrors.isEmpty) return null;

    return ApiError(code: code, message: message, fieldErrors: fieldErrors);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
