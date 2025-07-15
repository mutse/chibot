import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionUtils {
  // 使用一个固定的盐值来确保加密的一致性
  static const String _fixedSalt = 'ChibotConfig2024';
  // AES encryption key derived from app-specific string
  static const String _encryptionKey = 'Chibot2024SecureConfigExportKey32';
  
  // 使用SHA-256加盐加密
  static String encrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    
    final saltedText = '$plaintext$_fixedSalt';
    final bytes = utf8.encode(saltedText);
    final digest = sha256.convert(bytes);
    
    // 返回格式: salt:hash
    return '$_fixedSalt:${digest.toString()}';
  }
  
  // 验证加密的文本（用于解密）
  static bool verify(String plaintext, String encryptedText) {
    if (plaintext.isEmpty || encryptedText.isEmpty) return false;
    
    final parts = encryptedText.split(':');
    if (parts.length != 2) return false;
    
    final salt = parts[0];
    final hash = parts[1];
    
    final saltedText = '$plaintext$salt';
    final bytes = utf8.encode(saltedText);
    final digest = sha256.convert(bytes);
    
    return digest.toString() == hash;
  }
  
  // 尝试解密（通过暴力破解的方式）
  static String? decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return null;
    
    final parts = encryptedText.split(':');
    if (parts.length != 2) return null;
    
    // 这里我们无法直接解密SHA-256，所以返回null
    // 在实际应用中，你可能需要使用对称加密算法如AES
    return null;
  }
  
  // 检查文本是否已加密
  static bool isEncrypted(String text) {
    if (text.isEmpty) return false;
    final parts = text.split(':');
    return parts.length == 2 && parts[1].length == 64; // SHA-256 hash is 64 characters
  }
  
  // AES encryption for API keys
  static String aesEncrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    
    try {
      // Generate random IV
      final iv = _generateRandomBytes(16);
      
      // Derive key from fixed string
      final key = _deriveKey(_encryptionKey);
      
      // Encrypt using AES-CBC
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(true, params);
      
      final plaintextBytes = _padPKCS7(utf8.encode(plaintext), 16);
      final encryptedBytes = _processBlocks(cipher, plaintextBytes);
      
      // Combine IV and encrypted data
      final combined = Uint8List(iv.length + encryptedBytes.length);
      combined.setAll(0, iv);
      combined.setAll(iv.length, encryptedBytes);
      
      return base64.encode(combined);
    } catch (e) {
      // Fallback to simple encryption if AES fails
      return simpleEncrypt(plaintext);
    }
  }
  
  // AES decryption for API keys
  static String? aesDecrypt(String encryptedText) {
    if (encryptedText.isEmpty) return null;
    
    try {
      final combined = base64.decode(encryptedText);
      
      if (combined.length < 16) {
        // Try simple decryption for backward compatibility
        return simpleDecrypt(encryptedText);
      }
      
      // Extract IV and encrypted data
      final iv = combined.sublist(0, 16);
      final encryptedData = combined.sublist(16);
      
      // Derive key from fixed string
      final key = _deriveKey(_encryptionKey);
      
      // Decrypt using AES-CBC
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(false, params);
      
      final decryptedBytes = _processBlocks(cipher, encryptedData);
      final unpaddedBytes = _removePKCS7Padding(decryptedBytes);
      
      return utf8.decode(unpaddedBytes);
    } catch (e) {
      // Fallback to simple decryption for backward compatibility
      return simpleDecrypt(encryptedText);
    }
  }
  
  // 创建一个简单的可逆加密（用于演示和向后兼容）
  static String simpleEncrypt(String plaintext) {
    if (plaintext.isEmpty) return '';
    
    // 使用简单的Base64编码，在实际应用中应该使用更强的加密
    final bytes = utf8.encode(plaintext);
    return base64.encode(bytes);
  }
  
  // 简单的解密
  static String? simpleDecrypt(String encryptedText) {
    if (encryptedText.isEmpty) return null;
    
    try {
      final bytes = base64.decode(encryptedText);
      return utf8.decode(bytes);
    } catch (e) {
      return null;
    }
  }
  
  // Helper methods for AES encryption
  
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }
  
  static Uint8List _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes);
  }
  
  static Uint8List _padPKCS7(List<int> data, int blockSize) {
    final padding = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + padding);
    paddedData.setAll(0, data);
    for (int i = data.length; i < paddedData.length; i++) {
      paddedData[i] = padding;
    }
    return paddedData;
  }
  
  static Uint8List _removePKCS7Padding(Uint8List data) {
    if (data.isEmpty) return data;
    final padding = data.last;
    if (padding < 1 || padding > 16) return data;
    
    for (int i = data.length - padding; i < data.length; i++) {
      if (data[i] != padding) return data;
    }
    
    return data.sublist(0, data.length - padding);
  }
  
  static Uint8List _processBlocks(BlockCipher cipher, Uint8List data) {
    final blockSize = cipher.blockSize;
    final numBlocks = (data.length / blockSize).ceil();
    final output = Uint8List(numBlocks * blockSize);
    
    for (int i = 0; i < numBlocks; i++) {
      final offset = i * blockSize;
      cipher.processBlock(data, offset, output, offset);
    }
    
    return output;
  }
} 