import 'dart:typed_data'; // Needed for Uint8List

// thank you @MikePote: https://stackoverflow.com/a/76902150/198348
extension FileSizeExtensions on num {
  /// method returns a human readable string representing a file size
  /// size can be passed as number or as string
  /// the optional parameter 'round' specifies the number of numbers after comma/point (default is 2)
  /// the optional boolean parameter 'useBase1024' specifies if we should count in 1024's (true) or 1000's (false). e.g. 1KB = 1024B (default is true)
  String toHumanReadableFileSize({int round = 2, bool useBase1024 = true}) {
    const List<String> affixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

    num divider = useBase1024 ? 1024 : 1000;

    num size = this;
    num runningDivider = divider;
    num runningPreviousDivider = 0;
    int affix = 0;

    while (size >= runningDivider && affix < affixes.length - 1) {
      runningPreviousDivider = runningDivider;
      runningDivider *= divider;
      affix++;
    }

    String result = (runningPreviousDivider == 0 ? size : size / runningPreviousDivider).toStringAsFixed(round);

    //Check if the result ends with .00000 (depending on how many decimals) and remove it if found.
    if (result.endsWith("0" * round)) result = result.substring(0, result.length - round - 1);

    return "$result ${affixes[affix]}";
  }
}

// Helper function to format bytes as a hexdump
// Moved from main.dart
String formatBytesAsHexdump(Uint8List bytes, {int bytesPerLine = 16}) {
  if (bytes.isEmpty) {
    return "N/A";
  }

  final StringBuffer hexDump = StringBuffer();
  for (int i = 0; i < bytes.length; i += bytesPerLine) {
    // Offset
    hexDump.write('${i.toRadixString(16).padLeft(8, '0')}  ');

    // Hex bytes
    final StringBuffer lineBytesHex = StringBuffer();
    final StringBuffer lineChars = StringBuffer();
    for (int j = 0; j < bytesPerLine; j++) {
      if (i + j < bytes.length) {
        final byte = bytes[i + j];
        lineBytesHex.write('${byte.toRadixString(16).padLeft(2, '0')} ');
        // Printable ASCII characters or '.'
        if (byte >= 32 && byte <= 126) {
          lineChars.write(String.fromCharCode(byte));
        } else {
          lineChars.write('.');
        }
      } else {
        // Pad if line is shorter than bytesPerLine
        lineBytesHex.write('   ');
      }
      if ((j + 1) % 8 == 0 && j < bytesPerLine -1) lineBytesHex.write(' '); // Extra space after 8 bytes
    }
    hexDump.write(lineBytesHex.toString().padRight(bytesPerLine * 3 + (bytesPerLine ~/ 8 -1))); // Adjust padding
    hexDump.write(' |$lineChars|\n');
  }
  return hexDump.toString();
}