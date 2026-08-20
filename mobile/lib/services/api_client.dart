import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin wrapper over the SpeciesTrace FastAPI backend. Every method returns
/// decoded JSON (Map or List) or throws [ApiNetworkException] /
/// [ApiHttpException]. Callers decide how to react to each — the repository
/// layer treats network exceptions as a cue to fall back to local storage.
class ApiClient {
  String baseUrl;
  String? authToken;
  final Duration timeout;

  ApiClient({required this.baseUrl, this.authToken, this.timeout = const Duration(seconds: 6)});

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final full = '$normalizedBase$path';
    final uri = Uri.parse(full);
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v.toString())),
    });
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  Future<dynamic> _send(String method, Uri uri, {Object? body}) async {
    try {
      late http.Response response;
      final encodedBody = body != null ? jsonEncode(body) : null;
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(timeout);
          break;
        case 'POST':
          response = await http.post(uri, headers: _headers, body: encodedBody).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported method $method');
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return null;
        return jsonDecode(response.body);
      }
      String message = 'Request failed (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          message = decoded['detail'].toString();
        }
      } catch (_) {
        // Non-JSON error body; keep the generic message.
      }
      throw ApiHttpException(response.statusCode, message);
    } on ApiHttpException {
      rethrow;
    } on TimeoutException {
      throw ApiNetworkException('Connection to $baseUrl timed out');
    } on FormatException {
      throw ApiNetworkException('Received an invalid response from $baseUrl');
    } catch (e) {
      // Covers http.ClientException, SocketException (native), and any
      // browser fetch/XHR failure surfaced on web — all mean "unreachable".
      throw ApiNetworkException('Could not reach $baseUrl ($e)');
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) => _send('GET', _uri(path, query));

  Future<dynamic> post(String path, {Object? body}) => _send('POST', _uri(path), body: body ?? {});

  Future<bool> ping() async {
    try {
      await get('/');
      return true;
    } catch (_) {
      return false;
    }
  }
}
