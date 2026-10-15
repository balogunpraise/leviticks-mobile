import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Same backend the web app talks to (`NEXT_PUBLIC_API_BASE_URL` /
/// `NEXT_PUBLIC_API_PATH` in pamweb-next's `.env.production`) — the QA API host,
/// not `qa.leviticks.com` itself (that's the website; the API lives on the
/// `qa-api` subdomain, confirmed via its live Swagger UI).
const String _apiBaseUrl = 'https://qa-api.leviticks.com';
const String _apiPath = 'api/v1';

String getApiBaseUrl() => '$_apiBaseUrl/$_apiPath/';

class RawHttpResult {
  RawHttpResult({required this.statusCode, required this.body, required this.isSuccess});

  final int statusCode;
  final String body;
  final bool isSuccess;
}

/// Thin REST client mirroring `src/lib/http.ts` (`apiGet`/`apiPost`/`apiPostRaw`
/// /`apiPostFormData`) so the request shape stays identical to the web app.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<RawHttpResult> _rawRequest(
    String method,
    String endpoint, {
    String? token,
    Object? body,
    Map<String, String>? headersOverride,
  }) async {
    try {
      final uri = Uri.parse(getApiBaseUrl() + endpoint);
      late http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: _headers(token));
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: headersOverride ?? _headers(token),
            body: body,
          );
          break;
        default:
          throw UnsupportedError('Unsupported method $method');
      }
      return RawHttpResult(
        statusCode: response.statusCode,
        body: response.body,
        isSuccess: response.statusCode >= 200 && response.statusCode < 300,
      );
    } catch (error) {
      return RawHttpResult(statusCode: 0, body: error.toString(), isSuccess: false);
    }
  }

  T? _parse<T>(RawHttpResult result, T Function(dynamic json) fromJson) {
    if (result.body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(result.body);
      return fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<T?> get<T>(String endpoint, T Function(dynamic json) fromJson, {String? token}) async {
    final result = await _rawRequest('GET', endpoint, token: token);
    return _parse(result, fromJson);
  }

  Future<T?> post<T>(
    String endpoint,
    T Function(dynamic json) fromJson, {
    Object? body,
    String? token,
  }) async {
    final result = await postRaw(endpoint, body: body, token: token);
    return _parse(result, fromJson);
  }

  Future<RawHttpResult> postRaw(String endpoint, {Object? body, String? token}) {
    return _rawRequest(
      'POST',
      endpoint,
      token: token,
      body: body == null ? null : jsonEncode(body),
    );
  }

  /// Fetches a binary response (e.g. a QR code PNG) with the auth header.
  /// Returns null on any non-2xx response or network error.
  Future<Uint8List?> getBytes(String endpoint, {String? token}) async {
    try {
      final uri = Uri.parse(getApiBaseUrl() + endpoint);
      final response = await _client.get(uri, headers: token != null ? {'Authorization': 'Bearer $token'} : null);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }
}
