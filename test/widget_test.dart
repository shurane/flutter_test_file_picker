// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:async';
import 'dart:convert'; // For utf8.encode
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Assuming main.dart is in lib/
// Adjust the import path if your project structure is different.
import 'package:flutter_test_file_picker/main.dart' as app; // aliased to app
import 'package:flutter_test_file_picker/helper.dart'; // For FileSizeExtensions if needed directly, main.dart already imports it

// --- Mock File Data ---
final mockTextBytes = Uint8List.fromList(utf8.encode("Hello Widget Test!\nThis is line two."));
const String mockTextFileName = "mock_text_file.txt";

final mockJsonBytes = Uint8List.fromList(utf8.encode('{"name": "Flutter Test", "count": 1, "isAwesome": true}'));
const String mockJsonFileName = "mock_data.json";

final mockCodeBytes = Uint8List.fromList(utf8.encode('void main() {\n  print("Testing!");\n}'));
const String mockCodeFileName = "mock_code.dart";

final mockImageBytes = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01
]);
const String mockImageFileName = "mock_image.png";

final mockAudioBytes = Uint8List.fromList([
  0x52, 0x49, 0x46, 0x46, 0x24, 0x00, 0x00, 0x00, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6D, 0x74, 0x20, 0x10, 0x00, 0x00, 0x00, 0x01, 0x00, 0x02, 0x00
]);
const String mockAudioFileName = "mock_audio.wav";

final mockVideoBytes = Uint8List.fromList([
  0x00, 0x00, 0x00, 0x14, 0x66, 0x74, 0x79, 0x70, 0x6D, 0x70, 0x34, 0x32, 0x00, 0x00, 0x00, 0x00
]);
const String mockVideoFileName = "mock_video.mp4";

final mockEmptyBytes = Uint8List(0);
const String mockEmptyFileName = "empty.txt";

// --- Fake FilePickerPlatform (Simplified Structure) ---
class FakeFilePickerPlatform extends FilePickerPlatform {
  FilePickerResult? mockResultToReturn;
  bool pickFilesCalled = false;
  // Add other flags if needed:
  // bool clearTemporaryFilesCalled = false;
  // bool getDirectoryPathCalled = false;
  // bool saveFileCalled = false;

  void setMockResult(FilePickerResult? result) {
    mockResultToReturn = result;
    pickFilesCalled = false; // Reset for verification
  }

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    pickFilesCalled = true;
    return mockResultToReturn;
  }

  @override
  Future<bool?> clearTemporaryFiles() async {
    // clearTemporaryFilesCalled = true;
    return true; // Mock behavior
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    String? initialDirectory, // Ensure this matches FilePickerPlatform
    bool lockParentWindow = false,
  }) async {
    // getDirectoryPathCalled = true;
    return null; // Mock behavior
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool lockParentWindow = false,
    Uint8List? bytes,
  }) async {
    // saveFileCalled = true;
    return null; // Mock behavior
  }
}

void main() {
  late FakeFilePickerPlatform fakeFilePickerPlatform;

  setUp(() {
    fakeFilePickerPlatform = FakeFilePickerPlatform();
    FilePicker.platform = fakeFilePickerPlatform;
  });

  // Helper function to create FilePickerResult from bytes
  FilePickerResult createMockFilePickerResult(String fileName, Uint8List fileBytes) {
    return FilePickerResult([
      PlatformFile(
        name: fileName,
        size: fileBytes.length,
        bytes: fileBytes, // Providing bytes directly
        path: '/dummy/path/$fileName', // Path is not strictly needed by app's current logic but good to have
      ),
    ]);
  }

  // Helper function to test file selection and UI update
  Future<void> testFileSelectionUI( // Renamed from _testFileSelection
    WidgetTester tester,
    String testDesc,
    String fileName,
    Uint8List fileBytes,
  ) async {
    fakeFilePickerPlatform.setMockResult(createMockFilePickerResult(fileName, fileBytes));

    await tester.pumpWidget(const app.MyApp());

    // Verify initial state (optional, could be in a separate test)
    expect(find.textContaining('Filename: N/A', findRichText: true), findsOneWidget);
    expect(find.text('N/A', skipOffstage: false), findsWidgets); // For hexdump and possibly filename

    // Tap the FAB to pick a file
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle(); // Let animations and async operations complete

    // Verify that pickFiles was called
    expect(fakeFilePickerPlatform.pickFilesCalled, isTrue);

    // Verify filename display
    expect(find.textContaining('Filename: $fileName', findRichText: true), findsOneWidget);
    // Verify size display
    expect(find.textContaining('with size ${fileBytes.length.toHumanReadableFileSize()}', findRichText: true), findsOneWidget);

    // Verify hexdump display
    final expectedHexdump = formatBytesAsHexdump(fileBytes); // Changed from app.formatBytesAsHexdump
    // Find the Text widget for the hexdump using its Key.
    final hexdumpFinder = find.byKey(const Key('hexdump_preview_text'));

    // For very long hexdumps, ensure the widget is found and then check its data.
    // Scrolling might be needed if the hexdump widget itself is virtualized, but Text usually isn't.
    expect(hexdumpFinder, findsOneWidget);
    final hexdumpTextWidget = tester.widget<Text>(hexdumpFinder);
    expect(hexdumpTextWidget.data, equals(expectedHexdump));
  }

  group('File Preview Widget Tests', () {
    testWidgets('Selects and displays text file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Text File', mockTextFileName, mockTextBytes);
    });

    testWidgets('Selects and displays JSON file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'JSON File', mockJsonFileName, mockJsonBytes);
    });

    testWidgets('Selects and displays code file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Code File', mockCodeFileName, mockCodeBytes);
    });

    testWidgets('Selects and displays image file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Image File', mockImageFileName, mockImageBytes);
    });

    testWidgets('Selects and displays audio file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Audio File', mockAudioFileName, mockAudioBytes);
    });

    testWidgets('Selects and displays video file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Video File', mockVideoFileName, mockVideoBytes);
    });

    testWidgets('Selects and displays empty file preview correctly', (WidgetTester tester) async {
      await testFileSelectionUI(tester, 'Empty File', mockEmptyFileName, mockEmptyBytes);
      // Specific check for empty file's hexdump area if "N/A" is displayed differently
      final hexdumpFinder = find.byKey(const Key('hexdump_preview_text')); // Using key now
      expect(tester.widget<Text>(hexdumpFinder).data, equals("N/A"));
    });

    testWidgets('File picker cancellation retains previous state', (WidgetTester tester) async {
      // First, select a file
      await testFileSelectionUI(tester, 'Initial File', mockTextFileName, mockTextBytes); // Fixed: _testFileSelection -> testFileSelectionUI

      // Store expected values before cancellation
      final expectedFilename = 'Filename: $mockTextFileName';
      final expectedSize = mockTextBytes.length.toHumanReadableFileSize();
      final expectedHexdump = formatBytesAsHexdump(mockTextBytes); // Fixed: app.formatBytesAsHexdump -> formatBytesAsHexdump

      // Set up picker to return null (cancelled)
      fakeFilePickerPlatform.setMockResult(null);

      // Tap the FAB again
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify that pickFiles was called
      expect(fakeFilePickerPlatform.pickFilesCalled, isTrue);

      // Verify UI still shows the previous file's data (filename, size, hexdump)
      // The counter would have incremented, this test focuses on file data.
      expect(find.textContaining(expectedFilename, findRichText: true), findsOneWidget);
      expect(find.textContaining('with size $expectedSize', findRichText: true), findsOneWidget);

      final hexdumpFinder = find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Text));
      expect(tester.widget<Text>(hexdumpFinder).data, equals(expectedHexdump));
    });

    testWidgets('Initial state shows N/A for file info and hexdump', (WidgetTester tester) async {
      await tester.pumpWidget(const app.MyApp());
      expect(find.textContaining('Filename: N/A', findRichText: true), findsOneWidget);
      expect(find.textContaining('with size 0 B', findRichText: true), findsOneWidget);

      final hexdumpFinder = find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Text));
      expect(hexdumpFinder, findsOneWidget);
      expect(tester.widget<Text>(hexdumpFinder).data, equals('N/A'));
    });
  });
}
