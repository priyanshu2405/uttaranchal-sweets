import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Which login a request should carry.
enum ApiAuth { none, user, staff }

/// Any failure talking to the server, with a message that is safe to show to the customer.
class ApiException implements Exception {
  final String message;
  final int status;
  final Map<String, List<String>> errors;
  const ApiException(this.message, {this.status = 0, this.errors = const {}});

  bool get unauthorized => status == 401;
  bool get offline => status == 0;

  /// First message for a form field, e.g. errorFor('phone').
  String? errorFor(String field) => errors[field]?.first;

  @override
  String toString() => message;
}

/// Thin JSON client for the Laravel API (routes/api.php).
class ApiClient {
  ApiClient({http.Client? client, this.baseUrl = kApiBase}) : _http = client ?? http.Client();

  final http.Client _http;
  final String baseUrl;

  /// Customer login token (from /auth/login or /auth/register).
  String? userToken;

  /// Staff login token (from /staff/login).
  String? staffToken;

  /// Called when the server says a token is no longer valid, so the app can sign that person out.
  void Function(ApiAuth auth)? onUnauthorized;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && '$v'.isNotEmpty) q[k] = '$v';
    });
    return Uri.parse('$baseUrl$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> _headers(ApiAuth auth, Map<String, String>? extra) {
    final h = <String, String>{'Accept': 'application/json', 'Content-Type': 'application/json'};
    final token = switch (auth) {
      ApiAuth.user => userToken,
      ApiAuth.staff => staffToken,
      ApiAuth.none => null,
    };
    if (token != null) h['Authorization'] = 'Bearer $token';
    if (extra != null) h.addAll(extra);
    return h;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query, ApiAuth auth = ApiAuth.user, Map<String, String>? headers}) =>
      _send('GET', path, query: query, auth: auth, headers: headers);

  Future<Map<String, dynamic>> post(String path, [Object? body, ApiAuth auth = ApiAuth.user, Map<String, String>? headers]) =>
      _send('POST', path, body: body, auth: auth, headers: headers);

  Future<Map<String, dynamic>> patch(String path, [Object? body, ApiAuth auth = ApiAuth.user]) => _send('PATCH', path, body: body, auth: auth);

  Future<Map<String, dynamic>> delete(String path, [Object? body, ApiAuth auth = ApiAuth.user]) => _send('DELETE', path, body: body, auth: auth);

  /// Upload a file with form fields (multipart/form-data), e.g. a photo.
  Future<Map<String, dynamic>> upload(String path, {required Map<String, String> fields, required String fileField, required String filePath, ApiAuth auth = ApiAuth.user}) async {
    final req = http.MultipartRequest('POST', _uri(path));
    final headers = _headers(auth, null)..remove('Content-Type');
    req.headers.addAll(headers);
    req.fields.addAll(fields);
    req.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    return _handle(() => _http.send(req).timeout(const Duration(seconds: 60)), auth);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    ApiAuth auth = ApiAuth.user,
    Map<String, String>? headers,
  }) {
    final req = http.Request(method, _uri(path, query))..headers.addAll(_headers(auth, headers));
    if (body != null) req.body = jsonEncode(body);
    return _handle(() => _http.send(req).timeout(const Duration(seconds: 25)), auth);
  }

  Future<Map<String, dynamic>> _handle(Future<http.StreamedResponse> Function() send, ApiAuth auth) async {
    http.Response res;
    try {
      res = await http.Response.fromStream(await send());
    } on SocketException {
      throw const ApiException('No internet connection. Please check your network and try again.');
    } on TimeoutException {
      throw const ApiException('The shop is taking too long to answer. Please try again.');
    } on http.ClientException {
      throw const ApiException('Couldn’t reach the shop. Please try again.');
    }

    Map<String, dynamic> data = const {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else {
          data = {'data': decoded};
        }
      } on FormatException {
        data = const {};
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    final errors = <String, List<String>>{};
    final rawErrors = data['errors'];
    if (rawErrors is Map) {
      rawErrors.forEach((k, v) {
        if (v is List) errors['$k'] = v.map((e) => '$e').toList();
      });
    }
    var message = (data['message'] as String?) ?? '';
    // Laravel's summary reads "X (and 2 more errors)"; the first field error reads better on a phone.
    if (errors.isNotEmpty) message = errors.values.first.first;
    if (message.isEmpty) {
      message = switch (res.statusCode) {
        401 => 'Please sign in again.',
        404 => 'We couldn’t find that.',
        429 => 'Too many attempts. Please wait a minute and try again.',
        >= 500 => 'Something went wrong at the shop’s end. Please try again shortly.',
        _ => 'Something went wrong. Please try again.',
      };
    }
    if (res.statusCode == 401 && auth != ApiAuth.none) onUnauthorized?.call(auth);
    throw ApiException(message, status: res.statusCode, errors: errors);
  }
}
