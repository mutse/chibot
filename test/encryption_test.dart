import 'package:flutter_test/flutter_test.dart';
import 'package:chibot/utils/encryption_utils.dart';

void main() {
  group('EncryptionUtils Tests', () {
    test('AES encrypt and decrypt should work correctly', () {
      const testApiKey = 'sk-1234567890abcdef';
      
      // Test encryption
      final encrypted = EncryptionUtils.aesEncrypt(testApiKey);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(testApiKey)));
      
      // Test decryption
      final decrypted = EncryptionUtils.aesDecrypt(encrypted);
      expect(decrypted, equals(testApiKey));
    });

    test('AES encrypt should handle empty strings', () {
      const emptyString = '';
      
      final encrypted = EncryptionUtils.aesEncrypt(emptyString);
      expect(encrypted, equals(''));
      
      final decrypted = EncryptionUtils.aesDecrypt(encrypted);
      expect(decrypted, isNull);
    });

    test('AES decryption should handle invalid input', () {
      const invalidEncrypted = 'invalid-base64';
      
      final decrypted = EncryptionUtils.aesDecrypt(invalidEncrypted);
      expect(decrypted, isNull);
    });

    test('Simple encrypt/decrypt should still work for backward compatibility', () {
      const testApiKey = 'sk-1234567890abcdef';
      
      // Test simple encryption
      final encrypted = EncryptionUtils.simpleEncrypt(testApiKey);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(testApiKey)));
      
      // Test simple decryption
      final decrypted = EncryptionUtils.simpleDecrypt(encrypted);
      expect(decrypted, equals(testApiKey));
    });

    test('AES decryption should fallback to simple decryption for old data', () {
      const testApiKey = 'sk-1234567890abcdef';
      
      // Create data encrypted with simple method
      final simpleEncrypted = EncryptionUtils.simpleEncrypt(testApiKey);
      
      // AES decryption should still work (fallback)
      final decrypted = EncryptionUtils.aesDecrypt(simpleEncrypted);
      expect(decrypted, equals(testApiKey));
    });

    test('Multiple encryptions should produce different results', () {
      const testApiKey = 'sk-1234567890abcdef';
      
      final encrypted1 = EncryptionUtils.aesEncrypt(testApiKey);
      final encrypted2 = EncryptionUtils.aesEncrypt(testApiKey);
      
      // Should be different because of random IV
      expect(encrypted1, isNot(equals(encrypted2)));
      
      // But both should decrypt to the same value
      final decrypted1 = EncryptionUtils.aesDecrypt(encrypted1);
      final decrypted2 = EncryptionUtils.aesDecrypt(encrypted2);
      
      expect(decrypted1, equals(testApiKey));
      expect(decrypted2, equals(testApiKey));
    });

    test('Long API keys should be handled correctly', () {
      const longApiKey = 'sk-proj-1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      
      final encrypted = EncryptionUtils.aesEncrypt(longApiKey);
      expect(encrypted, isNotEmpty);
      
      final decrypted = EncryptionUtils.aesDecrypt(encrypted);
      expect(decrypted, equals(longApiKey));
    });

    test('Special characters in API keys should be handled correctly', () {
      const specialApiKey = 'sk-1234567890abcdef!@#\$%^&*()_+-=[]{}|;:,.<>?';
      
      final encrypted = EncryptionUtils.aesEncrypt(specialApiKey);
      expect(encrypted, isNotEmpty);
      
      final decrypted = EncryptionUtils.aesDecrypt(encrypted);
      expect(decrypted, equals(specialApiKey));
    });
  });
}