import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'helper.dart';
import 'dart:convert'; // Added for base64Encode
import 'dart:typed_data'; // Added for Uint8List
import 'dart:developer' as developer;

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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page', restorationId: 'myhomepage'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.restorationId});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String? restorationId;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RestorationMixin {
  final RestorableInt _counter = RestorableInt(0);
  final RestorableInt _length = RestorableInt(0);
  final RestorableString _filename = RestorableString("");
  final RestorableString _fileBytesPreview = RestorableString("");

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
    developer.log("_incrementCounter() call");
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    // FilePickerResult? result; // Original line, commented out for enabling file picker
    developer.log("_incrementCounter() result: $result");
    String? filename;
    String? b64BytesPreview;
    int? length;

    if (result != null) {
      File file = File(result.files.single.path!);
      filename = file.path;
      length = await file.length();
      developer.log("file path: ${basename(filename)}, file size: ${length.toHumanReadableFileSize()}");

      // Read the first 100 bytes
      try {
        List<int> firstBytesList = [];
        await for (var chunk in file.openRead(0, 100)) {
          firstBytesList.addAll(chunk);
          if (firstBytesList.length >= 100) break;
        }
        Uint8List bytesToEncode = Uint8List.fromList(firstBytesList);
        b64BytesPreview = base64Encode(bytesToEncode);
        developer.log("First 100 bytes (b64): $b64BytesPreview");
      } catch (e) {
        developer.log("Error reading file bytes: $e");
        // Keep previous preview if reading new one fails
        b64BytesPreview = _fileBytesPreview.value;
      }
    } else {
      developer.log("cancelled file picker");
      // User cancelled the picker - retain existing values by not setting them to null
    }
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter.value++; // Increment counter regardless of file pick success, as per original logic
      if (result != null) { // Only update file info if a file was actually picked
        if (filename != null) {
          _filename.value = filename;
        }
        if (length != null) {
          _length.value = length;
        }
        if (b64BytesPreview != null) {
          _fileBytesPreview.value = b64BytesPreview;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times: ${_counter.value}',
            ),
            Text(
              'Filename: ${basename(_filename.value)} with size ${_length.value.toHumanReadableFileSize()}',
            ),
            const SizedBox(height: 10),
            const Text('File content preview (first 100 bytes):'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _fileBytesPreview.value.isEmpty
                    ? "N/A"
                    : (() {
                        try {
                          // Attempt to decode as UTF-8, allow malformed to prevent crashes on binary data
                          return utf8.decode(base64Decode(_fileBytesPreview.value), allowMalformed: true);
                        } catch (e) {
                          // If base64 decoding itself fails or other error
                          developer.log("Error decoding preview string: $e");
                          return "Invalid preview data";
                        }
                      })(),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

}
