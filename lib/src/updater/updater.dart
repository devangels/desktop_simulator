import 'dart:io';
import 'package:archive/archive.dart';

void main(List<String> arguments) {
  Updater u = Updater();
  u.tryUpdating();
}

class Updater {

  String get ps => Platform.pathSeparator;

  void tryUpdating() async {
    if(_needsUpdate()) {
      await _update();
    }
  }


  void _update() async {
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

    File engineZip = await _downloadEngine(engineHash);
    File extractedEngine = _extractEngine(engineZip);
  }


  bool _needsUpdate() {

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


  File _extractEngine(File zipFile) {
    // Read the Zip file from disk.
    List<int> bytes = zipFile.readAsBytesSync();

    // Decode the Zip file
    Archive archive = new ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (ArchiveFile file in archive) {
      String filename = file.name;
      if (file.isFile && filename == "flutter_engine.dll") {
        List<int> data = file.content;
        return File('out/' + filename)
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
        // Found the file
      }
    }

    throw Exception("Could not find flutter_engine.dll in the zup archive");
  }

  // LINUX https://storage.googleapis.com/flutter_infra/flutter/FLUTTER_ENGINE/linux-x64/linux-x64-embedder
  // MAC https://storage.googleapis.com/flutter_infra/flutter/FLUTTER_ENGINE/darwin-x64/FlutterEmbedder.framework.zip.
  /// Return the handle to a compressed engine .zip file
  Future<File> _downloadEngine(String engineHash) async {
    File embedder = File('windows-x64-embedder.zip');
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse('https://storage.googleapis.com/flutter_infra/flutter/$engineHash/windows-x64/windows-x64-embedder.zip'));
    HttpClientResponse response = await request.close();
    int contentLength = response.contentLength;
    print("Need to download $contentLength bytes");

    int currentBytes = 0;
    int currentPercentage = 0;
    await response.map<List<int>>((it) {
  //    print("Received ${it.length} bytes");
      currentBytes += it.length;
      int newPercentage = ((currentBytes / contentLength) * 100).floor();
      if(currentPercentage != newPercentage) {
        print("At $newPercentage %");
      }
      currentPercentage = newPercentage;

      return it;
    }).pipe(embedder.openWrite());
    print("finished downloading");
    return embedder;
  }

}