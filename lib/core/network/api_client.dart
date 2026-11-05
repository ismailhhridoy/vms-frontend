import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final http.Client _client;
  final String _baseUrl;

  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extraHeaders,
    };
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, fromJsonT);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, fromJsonT);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, fromJsonT);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final response = await _client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, fromJsonT);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiResponse.fromJson(decoded, fromJsonT);
    } else {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        throw ApiException(
          decoded['message'] as String? ?? 'Request failed',
          response.statusCode,
        );
      } on FormatException {
        throw ApiException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          response.statusCode,
        );
      }
    }
  }
}
