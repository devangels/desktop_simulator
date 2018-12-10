import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';

void main(List<String> arguments) {
  Updater u = Updater();
  u.tryUpdating();
}

class Updater {



  String get ps => Platform.pathSeparator;

  void tryUpdating() async {

    // Search for Flutter
    ProcessResult results = await Process.run('where flutter', []);

    String res = results.stdout;
    String firstLine = res.split("\n")[0];

    print("Ok $firstLine");
    List<String> it = firstLine.split("$ps");
    String directory = it.getRange(0, it.length - 1).join("$ps");


    String engineHash = await _getEngineHash(directory);
    print("Found hash: $engineHash");

    File icuDat = _getICUDatFile(directory);

    icuDat.copy("F:/flutter-simulator-dart/desktop_simulator${ps}icudtl.dat");

   // _downloadEngine(engineHash);

  }



  Future<String> _getEngineHash(String flutterPath) async {
    String pathToEngineHash = "$flutterPath${ps}cache${ps}engine.stamp";
    File engineFile = File(pathToEngineHash);
    return await engineFile.readAsString();
  }

  //TODO this is window only atm
  File _getICUDatFile(String flutterPath) {
    return File("$flutterPath${ps}cache${ps}artifacts${ps}engine${ps}windows-x64${ps}icudtl.dat");
  }



  // LINUS https://storage.googleapis.com/flutter_infra/flutter/FLUTTER_ENGINE/linux-x64/linux-x64-embedder
  // MAC https://storage.googleapis.com/flutter_infra/flutter/FLUTTER_ENGINE/darwin-x64/FlutterEmbedder.framework.zip.
  /// Return the handle to a compressed engine .zip file
  Future<File> _downloadEngine(String engineHash) async {
    File embedder = File('windows-x64-embedder.zip');
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse('https://storage.googleapis.com/flutter_infra/flutter/$engineHash/windows-x64/windows-x64-embedder.zip'));
    HttpClientResponse response = await request.close();
    int contentLength = response.contentLength;
    print("Need to download $contentLength bytes");
    await response.map<List<int>>((it) {
      print("Received ${it.length} bytes");
      return it;
    }).pipe(embedder.openWrite());
    return embedder;
  }



  bool _needsUpdate() {

  }



  void _update() {

  }
}