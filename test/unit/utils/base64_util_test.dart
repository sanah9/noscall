import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/utils/base64_util.dart';

void main() {
  group('BASE64', () {
    group('check', () {
      test('returns true for valid base64 string', () {
        expect(BASE64.check('SGVsbG8='), isTrue);
        expect(BASE64.check('YWJj'), isTrue);
        expect(BASE64.check(''), isTrue);
      });

      test('returns false for invalid base64 string', () {
        expect(BASE64.check('!!!'), isFalse);
        expect(BASE64.check('SGVsbG8'), isFalse); // invalid padding
        expect(BASE64.check('ab=c'), isFalse);
      });
    });

    group('toData', () {
      test('decodes valid base64 to correct bytes', () {
        final data = BASE64.toData('SGVsbG8=');
        expect(data, isNotNull);
        expect(data!, Uint8List.fromList('Hello'.codeUnits));
      });

      test('decodes empty string to empty list', () {
        final data = BASE64.toData('');
        expect(data, isNotNull);
        expect(data!, isEmpty);
      });

      test('returns null for invalid base64', () {
        expect(BASE64.toData('!!!'), isNull);
        expect(BASE64.toData('not valid base64!!'), isNull);
      });
    });

    group('fromData', () {
      test('encodes bytes to base64 string', () {
        final bytes = Uint8List.fromList('Hello'.codeUnits);
        expect(BASE64.fromData(bytes), 'SGVsbG8=');
      });

      test('encodes empty list to empty string', () {
        expect(BASE64.fromData(Uint8List(0)), '');
      });

      test('roundtrip: toData(fromData(bytes)) equals bytes', () {
        final bytes = Uint8List.fromList([1, 2, 3, 255, 0]);
        final encoded = BASE64.fromData(bytes);
        final decoded = BASE64.toData(encoded);
        expect(decoded, bytes);
      });

      test('roundtrip: fromData(toData(string)) equals string for ASCII', () {
        const s = 'hello world';
        final bytes = Uint8List.fromList(s.codeUnits);
        final b64 = BASE64.fromData(bytes);
        final decoded = BASE64.toData(b64);
        expect(decoded, isNotNull);
        expect(String.fromCharCodes(decoded!), s);
      });
    });
  });
}
