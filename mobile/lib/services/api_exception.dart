/// Thrown when the server was reachable and responded, but with an error
/// status (validation failure, auth failure, not found, etc). Callers should
/// surface [message] to the user rather than silently falling back offline.
class ApiHttpException implements Exception {
  final int statusCode;
  final String message;

  ApiHttpException(this.statusCode, this.message);

  @override
  String toString() => 'ApiHttpException($statusCode): $message';
}

/// Thrown when the request could not reach the server at all (timeout,
/// connection refused, DNS failure, offline). Callers may fall back to the
/// local offline-first cache when this is thrown.
class ApiNetworkException implements Exception {
  final String message;

  ApiNetworkException(this.message);

  @override
  String toString() => 'ApiNetworkException: $message';
}
