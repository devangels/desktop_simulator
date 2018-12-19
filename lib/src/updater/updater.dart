import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

void main(List<String> arguments) {
  Updater u = Updater(true);
  u.tryUpdating();
}

// TODO linux and mac
class Updater {
  Updater(this.verbose);


  String get ps => Platform.pathSeparator;

  final bool verbose;

  final String engineHashFile = "last_engine.stamp";


  printV(String it) {
    if(verbose) {
      stdout.write(it);
    }
  }

  // TODO take a look at how to tools handle verbosity
  Future tryUpdating() async {

    printV("Seaching for Flutter...");
    ProcessResult results = await Process.run('where flutter', []);

    String res = results.stdout;
    if(res == null ||res.isEmpty) {
      throw Exception("Flutter could not be found in path\n"
          "Check to see if where flutter returns a vailid result. \n"
          "If you are on windows, simply add Flutter to your path");
    }
    String firstLine = res.split("\n")[0];
    List<String> it = p.context.split(firstLine);
    String directory = it.getRange(0, it.length - 1).join("$ps");
    printV("Found Flutter at $directory\n");

    printV("Seaching for engine hash...\n");
    String engineHash = await _getEngineHash(directory);
    printV("Found engine hash: $engineHash\n");

    if(!_needsUpdate(engineHash)) {
      printV("Didn't need update, finished\n");
      return;
    }


    File icuDat = _getICUDatFile(directory);

    printV("Copying ${icuDat.path} to ${File("icudtl.dat").absolute.path} ...\n");

    await icuDat.copy("icudtl.dat");

    File engineZip = await _downloadEngine(engineHash);
    File extractedEngine = _extractEngine(engineZip);
    printV("Finished extracting the engine, cleaning up ...\n");
    await engineZip.delete();

    _saveEngineHash(engineHash);

  }

  void _saveEngineHash(String hash) {
    File lastEngineVersion = File(engineHashFile);

    if(!lastEngineVersion.existsSync()) {
      lastEngineVersion.createSync();
    }
    lastEngineVersion.writeAsStringSync(hash, flush: true);
  }


  bool _needsUpdate(String flutterEngineHash) {
    File lastEngineVersion = File(engineHashFile);

    // No last version, download and set up
    if(!lastEngineVersion.existsSync()) {
      printV("Didnt find $engineHashFile, updating ...\n");
      return true;
    }

    return flutterEngineHash != lastEngineVersion.readAsStringSync();
  }

  Future<String> _getEngineHash(String flutterPath) async {
    String pathToEngineHash = "$flutterPath${ps}cache${ps}engine.stamp";
    File engineFile = File(pathToEngineHash);
    if(!engineFile.existsSync()) {
      throw Exception("Could not find engine.stamp at the following location: \n"
          "$pathToEngineHash .\n"
          "This file contains the Flutter engine version which it is compiled against \n"
          "if you can't find the file there something with your Flutter installation might be wrong \n"
          "run 'flutter doctor'");
    }
    return await engineFile.readAsString();
  }


  //TODO this is window only atm
  File _getICUDatFile(String flutterPath) {
    String pathToIcu = "$flutterPath${ps}cache${ps}artifacts${ps}engine${ps}windows-x64${ps}icudtl.dat";
    File file =  File(pathToIcu);
    if(!file.existsSync()) {
      throw Exception("icudtl.dat could not be found at location: \n"
          "$pathToIcu . \n"
          "please check if the file is there. If it's not this might indicate something is wrong \n"
          "with your Flutter installation. Run 'flutter doctor'");
    }
    return file;
  }


  File _extractEngine(File zipFile) {
    printV("Extracting the flutter_engine.dll ...\n");

    // Read the Zip file from disk.
    List<int> bytes = zipFile.readAsBytesSync();

    // Decode the Zip file
    Archive archive = new ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (ArchiveFile file in archive) {
      String filename = file.name;
      if (file.isFile && filename == "flutter_engine.dll") {
        printV("Found flutter_engine.dll in archive\n");
        List<int> data = file.content;
        return File(filename)
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
    String url = 'https://storage.googleapis.com/flutter_infra/flutter/$engineHash/windows-x64/windows-x64-embedder.zip';
    printV("Downloading $url ...\n");
    HttpClientRequest request = await HttpClient().getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    int contentLength = response.contentLength;
    printV("Need to download $contentLength bytes\n");

    int currentBytes = 0;
    int currentPercentage = 0;
    await response.map<List<int>>((it) {
  //    print("Received ${it.length} bytes");
      currentBytes += it.length;
      int newPercentage = ((currentBytes / contentLength) * 100).floor();
      if(currentPercentage != newPercentage) {
        printV("\rAt $newPercentage %");
      }
      currentPercentage = newPercentage;

      return it;
    }).pipe(embedder.openWrite());
    // The first \n is because we didn't put a \n above
    printV("\nFinished downloading the engine zip\n");
    return embedder;
  }

}