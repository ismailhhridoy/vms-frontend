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
  final Map<String, String>? validationErrors;

  const ApiException(this.message, [this.statusCode, this.validationErrors]);

  /// Returns a clean, user-facing error message
  String get userFriendlyMessage {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.values.join('\n');
    }
    return message;
  }

  @override
  String toString() => userFriendlyMessage;
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
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    Uri uri = Uri.parse('$_baseUrl$path');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final cleanParams = <String, String>{};
      queryParameters.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          cleanParams[key] = value.toString().trim();
        }
      });
      if (cleanParams.isNotEmpty) {
        uri = uri.replace(queryParameters: cleanParams);
      }
    }

    try {
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(AppConfig.requestTimeout);
      return _handleResponse(response, fromJsonT);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Unable to connect to backend server ($e). Please verify the backend is running.',
      );
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
      throw ApiException(
        'Unable to connect to backend server ($e). Please verify the backend is running.',
      );
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
      throw ApiException(
        'Unable to connect to backend server ($e). Please verify the backend is running.',
      );
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
      throw ApiException(
        'Unable to connect to backend server ($e). Please verify the backend is running.',
      );
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    Map<String, dynamic>? decoded;
    try {
      if (response.body.isNotEmpty) {
        final parsed = jsonDecode(response.body);
        if (parsed is Map<String, dynamic>) {
          decoded = parsed;
        }
      }
    } catch (_) {
      // Body is not JSON
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded != null) {
        return ApiResponse.fromJson(decoded, fromJsonT);
      }
      return ApiResponse<T>(
        success: true,
        message: 'Success',
        data: null,
      );
    }

    // Error response handling
    if (decoded != null) {
      final message = decoded['message'] as String? ?? 'Request failed';
      Map<String, String>? fieldErrors;
      if (decoded['data'] is Map<String, dynamic>) {
        final rawErrors = decoded['data'] as Map<String, dynamic>;
        fieldErrors = rawErrors.map((k, v) => MapEntry(k, v.toString()));
      }
      throw ApiException(message, response.statusCode, fieldErrors);
    }

    throw ApiException(
      'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Unknown error'}',
      response.statusCode,
    );
  }
}
