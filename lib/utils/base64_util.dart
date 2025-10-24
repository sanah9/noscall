import 'dart:convert';
import 'dart:typed_data';

class BASE64 {
  static bool check(String input) {
    try {
      base64Decode(input);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Uint8List? toData(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return null;
    }
  }

  static String fromData(Uint8List data) {
    return base64Encode(data);
  }
}