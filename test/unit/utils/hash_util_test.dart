import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noscall/utils/hash_util.dart';

void main() {
  group('HashUtil', () {
    group('sha256String', () {
      test('returns known hash for empty string', () {
        // SHA256("") in hex
        const expected =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        expect(HashUtil.sha256String(''), expected);
      });

      test('returns known hash for "hello"', () {
        const expected =
            '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
        expect(HashUtil.sha256String('hello'), expected);
      });

      test('returns 64-character hex string', () {
        final result = HashUtil.sha256String('test');
        expect(result.length, 64);
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(result), isTrue);
      });

      test('same input produces same hash', () {
        const input = 'consistent';
        expect(
          HashUtil.sha256String(input),
          HashUtil.sha256String(input),
        );
      });

      test('different inputs produce different hashes', () {
        expect(
          HashUtil.sha256String('a'),
          isNot(HashUtil.sha256String('b')),
        );
      });
    });

    group('sha256Bytes', () {
      test('returns known hash for empty bytes', () {
        const expected =
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
        expect(HashUtil.sha256Bytes(Uint8List(0)), expected);
      });

      test('returns same hash as sha256String for UTF-8 encoded string', () {
        const s = 'hello';
        final bytes = Uint8List.fromList(s.codeUnits);
        expect(
          HashUtil.sha256Bytes(bytes),
          HashUtil.sha256String(s),
        );
      });

      test('returns 64-character hex string', () {
        final result = HashUtil.sha256Bytes(Uint8List.fromList([1, 2, 3]));
        expect(result.length, 64);
        expect(RegExp(r'^[a-f0-9]+$').hasMatch(result), isTrue);
      });

      test('different byte lists produce different hashes', () {
        expect(
          HashUtil.sha256Bytes(Uint8List.fromList([0])),
          isNot(HashUtil.sha256Bytes(Uint8List.fromList([1]))),
        );
      });
    });
  });
}
