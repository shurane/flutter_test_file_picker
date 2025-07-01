import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_file_picker/helper.dart'; // Adjust path if your project name is different or helper is elsewhere

void main() {
  group('formatBytesAsHexdump Tests', () {
    test('formats an empty list correctly', () {
      final bytes = Uint8List.fromList([]);
      expect(formatBytesAsHexdump(bytes), equals('N/A'));
    });

    test('formats a short list (less than one line) correctly', () {
      final bytes = Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]); // "Hello"
      // Expected: Offset   Hex (16 bytes wide)          Chars
      //           00000000 48 65 6c 6c 6f                  |Hello|
      // Manually calculating padding:
      // 5 bytes * 3 chars/byte ("XX ") = 15 chars for hex.
      // One group of 8, so 0 extra spaces between groups.
      // Total width for hex part is 16*3 + (16/8 - 1) = 48 + 1 = 49.
      // LineBytesHex part: "48 65 6c 6c 6f " (15 chars)
      // Padded to 49: "48 65 6c 6c 6f                                  " (15 + 34 spaces)
      final expected = '00000000  48 65 6c 6c 6f                                 |Hello|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('formats exactly one full line (16 bytes) correctly', () {
      final bytes = Uint8List.fromList(
          List.generate(16, (i) => i + 0x30)); // '0' through '?' (0x30 to 0x3F)
      // 0123456789:;<=>?
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  30 31 32 33 34 35 36 37  38 39 3a 3b 3c 3d 3e 3f  |0123456789:;<=>?|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('formats multiple lines with a partial last line correctly', () {
      // 20 bytes: 1 full line, 1 partial line with 4 bytes
      final bytes = Uint8List.fromList(List.generate(20, (i) => i));
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|\n' +
          '00000010  10 11 12 13                                       |....|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('handles non-printable characters correctly', () {
      final bytes = Uint8List.fromList([0x01, 0x02, 0x41, 0x42, 0x7F, 0x80, 0xFF]); // SOH, STX, A, B, DEL, unicode, unicode
      // Expected: Offset   Hex (16 bytes wide)          Chars
      //           00000000 01 02 41 42 7f 80 ff            |..AB...|
      // Hex part: "01 02 41 42 7f 80 ff " (20 chars)
      // Padded to 49: "01 02 41 42 7f 80 ff                         " (20 + 29 spaces)
      final expected = '00000000  01 02 41 42 7f 80 ff                           |..AB...|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('formats all zero bytes correctly (18 bytes)', () {
      final bytes = Uint8List.fromList(List.filled(18, 0));
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|\n' +
          '00000010  00 00                                            |..|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('formats all 0xFF bytes correctly (17 bytes)', () {
      final bytes = Uint8List.fromList(List.filled(17, 0xFF));
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  ff ff ff ff ff ff ff ff  ff ff ff ff ff ff ff ff  |................|\n' +
          '00000010  ff                                               |.|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

     test('formats 32 bytes (exactly two full lines) correctly', () {
      final bytes = Uint8List.fromList(List.generate(32, (i) => i));
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  00 01 02 03 04 05 06 07  08 09 0a 0b 0c 0d 0e 0f  |................|\n' +
          '00000010  10 11 12 13 14 15 16 17  18 19 1a 1b 1c 1d 1e 1f  |................|\n';
      expect(formatBytesAsHexdump(bytes), equals(expected));
    });

    test('formats bytesPerLine parameter correctly (e.g., 8 bytes per line)', () {
      final bytes = Uint8List.fromList(List.generate(20, (i) => i + 0x41)); // 'A' through 'T'
      // Expected for 8 bytes per line
      // 00000000  41 42 43 44 45 46 47 48  |ABCDEFGH|
      // 00000008  49 4a 4b 4c 4d 4e 4f 50  |IJKLMNOP|
      // 00000010  51 52 53 54              |QRST|
      // Padding for 8 bytes per line: 8*3 = 24. No extra group space.
      final expected =
          // ignore: prefer_adjacent_string_concatenation
          '00000000  41 42 43 44 45 46 47 48  |ABCDEFGH|\n' +
          '00000008  49 4a 4b 4c 4d 4e 4f 50  |IJKLMNOP|\n' +
          '00000010  51 52 53 54              |QRST|\n';
      expect(formatBytesAsHexdump(bytes, bytesPerLine: 8), equals(expected));
    });

  });
}
