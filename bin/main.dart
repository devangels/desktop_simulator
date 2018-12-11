import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/simulator_window.dart';


void main(List<String> arguments) {

  // First arg is asset path
  // the rest can be forwarded to commandLineArgs

  String assetPath;
  if(arguments.length > 0) {
    assetPath = arguments[0];
  } else {
    print("Could not find Flutter assets");
    return;
  }
  List<String> cmdArgs = arguments.sublist(1);


  if (glfw.init()) {
    final window = DesktopWindow.createSnapshotMode(
      width: 375, height: 625, title: "Flutter Demo",
      assetPath: assetPath, icuDataPath: "icudtl.dat",
      commandLineArgs: cmdArgs,
    //  commandLineArgs: [ "app", "--dart-non-checked-mode" ],
    );
    window.run();
    glfw.terminate();
  }

  /*
  if (glfw.init()) {
    print('GLFW: ${glfw.version}');
    glfw.windowHint(GLFW_RESIZABLE, 1);
    final window = glfw.createWindow(375, 625, "Flutter Demo", Monitor.None, Window.None);
    if (window != Window.None && window != null) {
      window.centerOnMonitor();

      // FlutterEngine engine = FlutterEngine.create(delegate, args);
      // "flutter_assets", "icudtl.dat"

      final test = "hello";
      window.setUserData(test);
      final result = window.getUserData();
      print('userData: ${result} ${test}');
      print('Showing rect ${window.size}');
      while (!window.shouldClose) {
        glfw.waitEventsTimeout(0.1);
      }
      window.dispose();
    } else {
      print('Failed to create window.');
    }
    glfw.terminate();
  } else {
    print('Failed to initialize GLFW.');
  }
  */
}
