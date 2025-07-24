import 'package:encrypt/encrypt.dart';

class Crypto {
  final Encrypter encrypter;
  final IV iv;

  Crypto(String key)
      : iv = IV.fromLength(16),
        encrypter = Encrypter(AES(Key.fromUtf8(key)));

  String encrypt(String plaintext) {
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    return encrypted.base64;
  }

  String decrypt(String ciphertext) {
    final decrypted = encrypter.decrypt64(ciphertext, iv: iv);
    return decrypted;
  }
}