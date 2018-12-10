import 'dart:math' as math;

import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/flutter/message_codec.dart';
import 'package:desktop_simulator/src/flutter/message_codecs.dart';
import 'package:desktop_simulator/src/plugins/plugin.dart';

final jsonMethodCodec = const JSONMethodCodec();

/// An interface which is exposed to the plugins.
///
/// This includes everything that is necessary to communicate with the underlying system and the window.
abstract class NativeView {

  Window get window;

  // TODO probably don't want to expose the engine
  FlutterEngine get engine;

  double get pixelRatio2;
  int get height;
  int get width;
}

/// The actual desktop window
///
/// This class is the bridge between the Flutter Engine and GLFW
class DesktopWindow implements EngineDelegate, NativeView {


  DesktopWindow._(this._width, this._height) {
    //TODO not the right place
    plugins.add(TextInputPlugin(this));
    plugins.forEach((it) => it.init());
  }
  Window _window;
  FlutterEngine _engine;

  static const pixelRatio = 1.5;

  Window get window => _window;
  FlutterEngine get engine => _engine;

  int get width => _width;
  int get height => _height;
  double get pixelRatio2 => pixelRatio;

  final int _width;
  final int _height;

  /// TODO make this dynamic
  List<Plugin> plugins = [];

  static DesktopWindow createSnapshotMode({
    int width,
    int height,
    String title,
    String assetPath,
    String icuDataPath,
    List<String> commandLineArgs,
  }) {
    width = (width * pixelRatio).toInt();
    height = (height * pixelRatio).toInt();

    final _instance = DesktopWindow._(width, height);
    //Glfw.windowHint(GLFW_DECORATED, 0);
    Glfw.windowHint(GLFW_RESIZABLE, 1);
    final window = Glfw.createWindow(width, height, title, Monitor.None, Window.None);
    if (window == Window.None) {
      return null;
    }
    _instance._window = window;
    _instance._engine = FlutterEngine.create(
      _instance._window,
      _instance,
      EngineArgs(
        assetsPath: assetPath,
        icuDataPath: icuDataPath,
        commandLineArgs: commandLineArgs,
      ),
    );
    if (_instance._engine == null) {
      print('Failed to create engine!');
      _instance._window.dispose();
      return null;
    }
    _instance._engine.flushPendingTasks();
    window.centerOnMonitor();
    return _instance;
  }




  void run() {
    while (!_window.shouldClose) {
      Glfw.waitEventsTimeout(0.1);
      _engine.flushPendingTasks();
    }
    _engine.shutdown();
    _window.dispose();
  }

  @override
  void platformMessage(PlatformMessage message) {
    final MethodCall methodCall = jsonMethodCodec.decodeMethodCall(message.asByteData);
    if (message.channel == 'flutter/platform') {
      switch (methodCall.method) {
        case 'SystemChrome.setApplicationSwitcherDescription':
          String label = methodCall.arguments['label'];
          int primaryColor = methodCall.arguments['primaryColor'];
          _window.setTitle(label);
          message.responseSuccess();
          break;

        case 'SystemSound.play':
          var soundType = methodCall.arguments.toString();
          if (soundType == 'SystemSoundType.click') {
            // System.Media.SystemSounds.Beep.Play();
          }
          break;
      }
    }
    for(Plugin plugin in plugins) {
      if(message.channel == plugin.channel) {
        plugin.onMethodCall(methodCall);
        break;
      }
    }
  }

  @override
  String toString() => 'DesktopWindow(${identityCode(this)})';
}
