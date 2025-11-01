/// Custom exceptions for settings import/export operations
///
/// These exceptions provide specific error types and helpful messages
/// for better error handling and user feedback during config management

/// Base exception for all settings-related errors
abstract class SettingsException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  SettingsException({
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    final buf = StringBuffer('SettingsException: $message');
    if (details != null) {
      buf.write('\nDetails: $details');
    }
    return buf.toString();
  }
}

/// Thrown when the XML format is invalid or corrupted
class InvalidSettingsException extends SettingsException {
  InvalidSettingsException({
    required String message,
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    details: details,
    stackTrace: stackTrace,
  );

  factory InvalidSettingsException.malformedXml(String? reason) {
    return InvalidSettingsException(
      message: 'Invalid settings format',
      details: 'The configuration file has an invalid or corrupted XML structure. $reason',
    );
  }

  factory InvalidSettingsException.missingRequiredField(String fieldName) {
    return InvalidSettingsException(
      message: 'Missing required field: $fieldName',
      details: 'The configuration file is missing the required field "$fieldName".',
    );
  }

  factory InvalidSettingsException.invalidDataType(String fieldName, String expectedType) {
    return InvalidSettingsException(
      message: 'Invalid data type for $fieldName',
      details: 'Field "$fieldName" should be of type $expectedType.',
    );
  }
}

/// Thrown when settings version is incompatible with current app version
class SettingsVersionMismatchException extends SettingsException {
  final int exportedVersion;
  final int currentVersion;

  SettingsVersionMismatchException({
    required this.exportedVersion,
    required this.currentVersion,
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: 'Settings version mismatch',
    details: details ??
      'The configuration file was exported with version $exportedVersion, '
      'but your app supports version $currentVersion. '
      'Some settings may not be compatible.',
    stackTrace: stackTrace,
  );
}

/// Thrown when API key decryption fails
class DecryptionFailedException extends SettingsException {
  DecryptionFailedException({
    required String message,
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    details: details ?? 'Failed to decrypt sensitive data. The configuration file may be corrupted.',
    stackTrace: stackTrace,
  );

  factory DecryptionFailedException.keyDecryptionFailed(String keyName) {
    return DecryptionFailedException(
      message: 'Failed to decrypt $keyName',
      details: 'Could not decrypt the "$keyName". The configuration file may be corrupted or encrypted with a different key.',
    );
  }
}

/// Thrown when validation of settings fails
class SettingsValidationException extends SettingsException {
  final List<String> validationErrors;

  SettingsValidationException({
    required String message,
    required this.validationErrors,
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    details: details,
    stackTrace: stackTrace,
  );

  factory SettingsValidationException.fromErrors(List<String> errors) {
    return SettingsValidationException(
      message: 'Settings validation failed',
      validationErrors: errors,
      details: 'Found ${errors.length} validation error(s):\n' + errors.map((e) => '  • $e').join('\n'),
    );
  }
}

/// Thrown when import/export operation is cancelled by user
class SettingsOperationCancelledException extends SettingsException {
  SettingsOperationCancelledException({
    String message = 'Settings operation cancelled',
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    details: details ?? 'The operation was cancelled by the user.',
    stackTrace: stackTrace,
  );
}

/// Thrown when file I/O operations fail during import/export
class SettingsFileException extends SettingsException {
  SettingsFileException({
    required String message,
    String? filePath,
    String? details,
    StackTrace? stackTrace,
  }) : super(
    message: message,
    details: details ?? (filePath != null ? 'File: $filePath' : null),
    stackTrace: stackTrace,
  );

  factory SettingsFileException.fileNotFound(String filePath) {
    return SettingsFileException(
      message: 'Configuration file not found',
      filePath: filePath,
      details: 'The file "$filePath" does not exist.',
    );
  }

  factory SettingsFileException.permissionDenied(String filePath) {
    return SettingsFileException(
      message: 'Permission denied',
      filePath: filePath,
      details: 'Unable to access "$filePath". Please check file permissions.',
    );
  }

  factory SettingsFileException.failedToWrite(String filePath) {
    return SettingsFileException(
      message: 'Failed to write configuration file',
      filePath: filePath,
      details: 'Could not write to "$filePath". Check available disk space and permissions.',
    );
  }

  factory SettingsFileException.failedToRead(String filePath) {
    return SettingsFileException(
      message: 'Failed to read configuration file',
      filePath: filePath,
      details: 'Could not read from "$filePath". The file may be corrupted.',
    );
  }
}
