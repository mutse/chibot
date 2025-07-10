import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/exceptions.dart';
import '../core/logger.dart';
import '../constants/app_constants.dart';

abstract class BaseApiService {
  final String baseUrl;
  final String apiKey;
  final Duration timeout;
  final int maxRetries;
  final http.Client? _client;

  BaseApiService({
    required this.baseUrl,
    required this.apiKey,
    this.timeout = AppConstants.requestTimeout,
    this.maxRetries = AppConstants.maxRetries,
    http.Client? client,
  }) : _client = client ?? http.Client();

  http.Client get client => _client ?? http.Client();

  // Abstract methods to be implemented by subclasses
  String get providerName;
  Map<String, String> getHeaders();
  void validateResponse(http.Response response);

  // Common API methods
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeRequest(() => client.get(uri, headers: getHeaders()));
  }

  Future<http.Response> post(String endpoint, {Object? body, Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeRequest(() => client.post(uri, headers: getHeaders(), body: body));
  }

  Future<http.Response> put(String endpoint, {Object? body, Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeRequest(() => client.put(uri, headers: getHeaders(), body: body));
  }

  Future<http.Response> delete(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeRequest(() => client.delete(uri, headers: getHeaders()));
  }

  // Streaming request method
  Future<http.StreamedResponse> postStream(String endpoint, {Object? body, Map<String, String>? queryParams}) async {
    final uri = _buildUri(endpoint, queryParams);
    return _executeStreamRequest(() {
      final request = http.Request('POST', uri);
      request.headers.addAll(getHeaders());
      if (body != null) {
        if (body is String) {
          request.body = body;
        } else if (body is Map || body is List) {
          request.body = jsonEncode(body);
        }
      }
      return client.send(request);
    });
  }

  // Execute request with retry logic and error handling
  Future<http.Response> _executeRequest(Future<http.Response> Function() request) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        logInfo('Making API request (attempt $attempt/$maxRetries)');
        
        final response = await request().timeout(timeout);
        
        logInfo('API response: ${response.statusCode}');
        
        validateResponse(response);
        return response;
        
      } on TimeoutException catch (e) {
        lastException = NetworkException(
          'Request timeout after ${timeout.inSeconds} seconds',
          code: 'TIMEOUT',
          originalError: e,
        );
        logWarning('Request timeout (attempt $attempt/$maxRetries)', error: e);
        
      } on http.ClientException catch (e) {
        lastException = NetworkException(
          'Network error: ${e.message}',
          code: 'NETWORK_ERROR',
          originalError: e,
        );
        logWarning('Network error (attempt $attempt/$maxRetries)', error: e);
        
      } on ApiException catch (e) {
        // Don't retry API errors (4xx, 5xx)
        logError('API error: ${e.message}', error: e);
        rethrow;
        
      } catch (e) {
        lastException = ApiException(
          'Unexpected error: ${e.toString()}',
          0,
          code: 'UNEXPECTED_ERROR',
          originalError: e,
        );
        logError('Unexpected error (attempt $attempt/$maxRetries)', error: e);
      }
      
      // Wait before retry (exponential backoff)
      if (attempt < maxRetries) {
        final delay = Duration(milliseconds: 1000 * attempt);
        logInfo('Retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
      }
    }
    
    // All retries failed
    logError('All retry attempts failed for $providerName API');
    throw lastException!;
  }

  // Execute streaming request with error handling
  Future<http.StreamedResponse> _executeStreamRequest(Future<http.StreamedResponse> Function() request) async {
    try {
      logInfo('Making streaming API request');
      
      final response = await request().timeout(timeout);
      
      logInfo('Streaming API response: ${response.statusCode}');
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final responseBody = await response.stream.bytesToString();
        _handleErrorResponse(response.statusCode, responseBody);
      }
      
      return response;
      
    } on TimeoutException catch (e) {
      logError('Streaming request timeout', error: e);
      throw NetworkException(
        'Streaming request timeout after ${timeout.inSeconds} seconds',
        code: 'STREAM_TIMEOUT',
        originalError: e,
      );
      
    } on http.ClientException catch (e) {
      logError('Streaming network error', error: e);
      throw NetworkException(
        'Streaming network error: ${e.message}',
        code: 'STREAM_NETWORK_ERROR',
        originalError: e,
      );
      
    } catch (e) {
      logError('Unexpected streaming error', error: e);
      throw ApiException(
        'Unexpected streaming error: ${e.toString()}',
        0,
        code: 'STREAM_UNEXPECTED_ERROR',
        originalError: e,
      );
    }
  }

  // Build URI with query parameters
  Uri _buildUri(String endpoint, Map<String, String>? queryParams) {
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    
    final uri = Uri.parse('$cleanBaseUrl/$cleanEndpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    
    return uri;
  }

  // Handle error responses
  void _handleErrorResponse(int statusCode, String responseBody) {
    String errorMessage = 'Request failed with status $statusCode';
    String? errorCode;
    Map<String, dynamic>? responseData;
    
    try {
      responseData = jsonDecode(responseBody) as Map<String, dynamic>;
      
      // Try to extract error message from common response formats
      if (responseData['error'] != null) {
        final error = responseData['error'];
        if (error is String) {
          errorMessage = error;
        } else if (error is Map) {
          errorMessage = error['message'] ?? error['description'] ?? errorMessage;
          errorCode = error['code']?.toString();
        }
      } else if (responseData['message'] != null) {
        errorMessage = responseData['message'];
      } else if (responseData['detail'] != null) {
        errorMessage = responseData['detail'];
      }
      
    } catch (e) {
      logWarning('Failed to parse error response', error: e);
      errorMessage = 'Request failed with status $statusCode: $responseBody';
    }
    
    throw ApiException(
      errorMessage,
      statusCode,
      code: errorCode ?? 'HTTP_$statusCode',
      responseData: responseData,
    );
  }

  // Validate API key
  void validateApiKey() {
    if (apiKey.isEmpty) {
      throw ConfigurationException(
        'API key is required for $providerName',
        code: 'MISSING_API_KEY',
      );
    }
  }

  // Clean up resources
  void dispose() {
    _client?.close();
  }
}