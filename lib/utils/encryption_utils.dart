import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionUtils {
  // 使用一个固定的盐值来确保加密的一致性
  static const String _fixedSalt = 'ChibotConfig2024';
  
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
  
  // 创建一个简单的可逆加密（用于演示）
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
} 