import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HashUtil {
  static String sha256Bytes(Uint8List bytes) {
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String sha256String(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}