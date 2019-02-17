import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/simulator_window.dart';
import 'package:args/args.dart';
import 'package:desktop_simulator/src/updater/updater.dart';


void main(List<String> arguments) {
  _main(arguments);
}

void _main(List<String> arguments) async {

  // First arg is asset path
  // the rest can be forwarded to commandLineArgs

  ArgParser parser = ArgParser();

  parser.addOption("width", abbr: "w", help: "The width of this window in pixels",
      valueHelp: "WIDTH", defaultsTo: "400");
  parser.addOption("height", abbr: "h", help: "The height of this window in pixels",
      valueHelp: "HEIGHT", defaultsTo: "600");
  parser.addOption("assetsPath", help: "The absolute path to the asset directory "
      "built by runing flutter build asset");
  parser.addOption("title", defaultsTo: "Flutter App");
  // TODO not used right now
  parser.addOption("dpi", help: "The DPI of the app, if not set this is calculated NOT USED RIGHT NOW",
      valueHelp: "DPI");


  /// These are only here because the parser needs ever arguments that is possible. There needs to be a better solution to this

  List<String> restArgs = [];
  parser.addFlag('dart-main', defaultsTo: false);
  parser.addFlag('enable-dart-profiling', defaultsTo: false);
  parser.addFlag('enable-checked-mode', defaultsTo: false);
  parser.addFlag('start-paused', defaultsTo: false);
  parser.addFlag('skia-deterministic-rendering', defaultsTo: false);
  parser.addFlag('use-test-fonts', defaultsTo: false);
  parser.addOption('observatory-port', defaultsTo: "");
  ///


  ArgResults results = parser.parse(arguments);

  ///
  results['dart-main']? restArgs.add('--dart-main'): null;
  results['enable-dart-profiling']? restArgs.add('--enable-dart-profiling'): null;
  results['enable-checked-mode']? restArgs.add('--enable-checked-mode'): null;
  results['start-paused']? restArgs.add('--start-paused'): null;
  results['skia-deterministic-rendering']? restArgs.add('--skia-deterministic-rendering'): null;
  results['use-test-fonts']? restArgs.add('--use-test-fonts'): null;
  restArgs.add('observatory-port=${results['observatory-port']}');
  ///

  String stringWidth = results["width"];
  String stringHeight = results["height"];
  String title = results['title'];

  int width = int.tryParse(stringWidth);
  int height = int.tryParse(stringHeight);

  if(width == null) {
    print('Width "$stringWidth" is not an integer');
    return;
  }
  if(height == null) {
    print('Height "$stringHeight" is not an integer');
    return;
  }

  String assetPath = results["assetsPath"];

  Updater updater = Updater(true);
   await updater.tryUpdating();

  if (glfw.init()) {
    final window = DesktopWindow.createSnapshotMode(
      width: width, height: height, title: title,
      assetPath: assetPath, icuDataPath: "icudtl.dat",
      commandLineArgs: restArgs,
      //  commandLineArgs: [ "app", "--dart-non-checked-mode" ],
    );
    window.run();
    glfw.terminate();
  }
}
