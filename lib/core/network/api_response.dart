import 'dart:convert';

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

  /// Pulls a `data` **array** out of [body] — the shape every paginated list
  /// endpoint answers with — or accepts a bare top-level array.
  ///
  /// An empty list is a legitimate answer (a day with no records), so this
  /// returns `[]` rather than throwing when `data` is present but empty.
  static List<Map<String, dynamic>> unwrapList(dynamic body) {
    if (body is List) {
      return body.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    if (body is! Map) {
      throw const FormatException('Expected a JSON list response');
    }

    if (body.containsKey('error') || body['success'] == false) {
      throw const FormatException('Response carries an error, not data');
    }

    final data = body['data'];
    if (data is List) {
      return data.whereType<Map>().map(Map<String, dynamic>.from).toList();
    }

    // Some list endpoints nest the page under `data.items` / `data.data`.
    if (data is Map) {
      for (final key in const ['items', 'data', 'records', 'results']) {
        final nested = data[key];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList();
        }
      }
    }

    throw const FormatException('Expected a JSON list response');
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
  ///
  /// A call that asked for bytes (the payslip PDF) gets its error as bytes
  /// too: they are read as UTF-8 JSON first, so the code is not lost.
  static ApiError? tryParse(dynamic body) {
    if (body is List<int>) body = _jsonOf(body);
    if (body is! Map) return null;

    String? code;
    String? message;

    final error = body['error'];
    if (error is Map) {
      // Text only: a code or message of another kind is no code at all,
      // not a crash while reading the error.
      code = _textOf(error['code']);
      message = _textOf(error['message']);
    } else if (error is String) {
      message = error;
    }

    // 422 puts the summary at the top level.
    message ??= _textOf(body['message']);

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

  static String? _textOf(Object? value) => value is String ? value : null;

  /// [bytes] as JSON, or null when they are not UTF-8 JSON (a PDF, an HTML
  /// error page from a proxy).
  static Object? _jsonOf(List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
