import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient({TokenStorage? tokenStorage}) : _tokenStorage = tokenStorage ?? TokenStorage();

  final TokenStorage _tokenStorage;

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.readToken();
    return {
      'Content-Type': 'application/json',
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

  Future<String> downloadPdf(int testId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tests/$testId/pdf'),
      headers: await _headers(),
    );
    if (response.statusCode >= 400) {
      throw Exception('PDF is not available now');
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/polyht_test_$testId.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(body?['message'] ?? 'Request failed');
    }
    return body;
  }
}
