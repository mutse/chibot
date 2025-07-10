abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  
  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  
  @override
  String toString() {
    return 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class ApiException extends AppException {
  final int statusCode;
  final Map<String, dynamic>? responseData;
  
  const ApiException(
    super.message,
    this.statusCode, {
    super.code,
    super.originalError,
    super.stackTrace,
    this.responseData,
  });
  
  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)${code != null ? ' (Code: $code)' : ''}';
  }
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() {
    return 'NetworkException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class ValidationException extends AppException {
  final String field;
  
  const ValidationException(
    super.message,
    this.field, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() {
    return 'ValidationException: $message (Field: $field)${code != null ? ' (Code: $code)' : ''}';
  }
}

class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() {
    return 'StorageException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
  
  @override
  String toString() {
    return 'ConfigurationException: $message${code != null ? ' (Code: $code)' : ''}';
  }
}