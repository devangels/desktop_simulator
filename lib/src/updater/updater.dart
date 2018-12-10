
import 'dart:io';

class Updater {



  void tryUpdating() async {

    // Search for Flutter
    ProcessResult results = await Process.run('where flutter', []);

    String res = results.stdout;
    String firstLine = res.split("\n")[0];
    String directoryString = "";

    Directory directory = Directory(directoryString);
    List<FileSystemEntity> entries = directory.listSync();

  //  assert(entries.co)



    print(results.stdout);
  }


  bool _needsUpdate() {

  }



  void _update() {

  }
}