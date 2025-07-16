import 'package:steel_crypt/steel_crypt.dart';

class Crypto {
  final String key;
  final String iv;

  Crypto({required this.key, required this.iv});

  String encrypt(String plaintext) {
    final encrypter = AesCrypt(key: key, iv: iv, padding: Padding.pkcs7);
    return encrypter.encrypt(inp: plaintext);
  }

  String decrypt(String ciphertext) {
    final decrypter = AesCrypt(key: key, iv: iv, padding: Padding.pkcs7);
    return decrypter.decrypt(enc: ciphertext);
  }
}
