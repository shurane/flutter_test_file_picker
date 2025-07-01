import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'helper.dart';
import 'dart:convert'; // Added for base64Encode
import 'dart:typed_data'; // Added for Uint8List
import 'dart:developer' as developer;

// formatBytesAsHexdump moved to helper.dart

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      restorationScopeId: 'app',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page', restorationId: 'myhomepage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.restorationId});

  final String title;
  final String? restorationId;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RestorationMixin {
  final RestorableInt _counter = RestorableInt(0);
  final RestorableInt _length = RestorableInt(0);
  final RestorableString _filename = RestorableString("");
  final RestorableString _fileBytesPreview = RestorableString(""); // Stores Base64 of first 1024 bytes

  @override
  String? get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_counter, 'counter');
    registerForRestoration(_filename, 'filename');
    registerForRestoration(_length, 'length');
    registerForRestoration(_fileBytesPreview, 'file_bytes_preview');
  }

  @override
  void dispose() {
    _counter.dispose();
    _filename.dispose();
    _length.dispose();
    _fileBytesPreview.dispose();
    super.dispose();
  }

  void _incrementCounter() async {
    const int bytesToRead = 1024;
    developer.log("_incrementCounter() call, attempting to read $bytesToRead bytes");
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    developer.log("_incrementCounter() result: $result");
    String? localFilename;
    String? b64BytesPreview;
    int? localLength;

    if (result != null) {
      File file = File(result.files.single.path!);
      localFilename = file.path;
      localLength = await file.length();
      developer.log("file path: ${basename(localFilename)}, file size: ${localLength.toHumanReadableFileSize()}");

      try {
        List<int> firstBytesList = [];
        await for (var chunk in file.openRead(0, bytesToRead)) {
          firstBytesList.addAll(chunk);
          if (firstBytesList.length >= bytesToRead) break;
        }
        Uint8List bytesToEncode = Uint8List.fromList(firstBytesList);
        b64BytesPreview = base64Encode(bytesToEncode);
        developer.log("First $bytesToRead bytes (b64 length: ${b64BytesPreview.length})");
      } catch (e) {
        developer.log("Error reading file bytes: $e");
        b64BytesPreview = _fileBytesPreview.value; // Keep previous preview on error
      }
    } else {
      developer.log("cancelled file picker");
    }

    setState(() {
      _counter.value++;
      if (result != null) {
        if (localFilename != null) _filename.value = localFilename;
        if (localLength != null) _length.value = localLength;
        if (b64BytesPreview != null) _fileBytesPreview.value = b64BytesPreview;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding( // Added Padding around the main content
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, // Align content to start
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
          children: <Widget>[
            Text(
              'You have pushed the button this many times: ${_counter.value}',
            ),
            Text(
              // Using basename for filename display
              'Filename: ${(_filename.value.isEmpty ? "N/A" : basename(_filename.value))} with size ${_length.value.toHumanReadableFileSize()}',
            ),
            const SizedBox(height: 10),
            const Text('File content preview (first 1024 bytes):'),
            const SizedBox(height: 5),
            Expanded( // Make the hexdump area scrollable
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity, // Ensure Container takes full width for Text
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: Text(
                    _fileBytesPreview.value.isEmpty
                        ? "N/A"
                        : formatBytesAsHexdump(base64Decode(_fileBytesPreview.value)),
                    key: const Key('hexdump_preview_text'), // ADDED KEY
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10.0), // Monospace font for hexdump
                    softWrap: false, // Prevent wrapping in hexdump
                    overflow: TextOverflow.fade, // Should not be needed with SingleChildScrollView
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
