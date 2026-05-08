import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<Map<String, String>> _headers({bool jsonBody = true}) async {
    final token = await _tokenStorage.readToken();
    return {
      if (jsonBody) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> postEmpty(String path) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<void> delete(String path) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );
    if (response.statusCode >= 400) {
      _decode(response);
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> uploadTest({
    required String title,
    required int branchId,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
    required int timeLimitMinutes,
    required String pdfPath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/tests'));
    request.headers.addAll(await _headers(jsonBody: false));
    request.fields.addAll({
      'title': title,
      'branchId': '$branchId',
      'scheduledStart': scheduledStart.toIso8601String(),
      'scheduledEnd': scheduledEnd.toIso8601String(),
      'timeLimitMinutes': '$timeLimitMinutes',
    });
    request.files.add(await http.MultipartFile.fromPath('pdf', pdfPath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  Future<dynamic> replacePdf({
    required int testId,
    required String pdfPath,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiConfig.baseUrl}/tests/$testId/pdf'));
    request.headers.addAll(await _headers(jsonBody: false));
    request.files.add(await http.MultipartFile.fromPath('pdf', pdfPath));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body?['message'] ?? 'Request failed');
    }
    return body;
  }
}
