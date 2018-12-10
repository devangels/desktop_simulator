import 'dart:math' as math;

import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/flutter/message_codec.dart';
import 'package:desktop_simulator/src/flutter/message_codecs.dart';

final jsonMethodCodec = const JSONMethodCodec();

class DesktopWindow implements EngineDelegate {
  DesktopWindow._();

  Window _window;
  FlutterEngine _engine;

  bool _dragging = false;
  int _clientId;
  String _text;

  static const pixelRatio = 1.5;

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

    final _instance = DesktopWindow._();
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
    _instance._engine.sendWindowMetricsEvent(WindowMetricsEvent(width, height, pixelRatio));
    _instance._engine.flushPendingTasks();
    window.setWindowSizeCallback(_instance._onSizeChanged);
    window.setKeyCallback(_instance._onKey);
    window.setMouseButtonCallback(_instance._onMouseButton);
    window.setScrollCallback(_instance._onScroll);
    window.centerOnMonitor();
    return _instance;
  }

  void _onSizeChanged(Window window, int width, int height) {
    _engine.sendWindowMetricsEvent(WindowMetricsEvent(width, height, pixelRatio));
  }

  void _onMouseButton(Window window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_1) {
      if (_dragging) {
        if (action == GLFW_RELEASE) {
          _dragging = false;
        }
      } else if (action == GLFW_PRESS) {
        final pt = _window.getCursorPos();
        _sendPointerEvent(PointerPhase.down, pt.x, pt.y);
        _window.setCursorPosCallback(_onCursorPosChanged);
      } else if (action == GLFW_RELEASE) {
        final pt = _window.getCursorPos();
        _sendPointerEvent(PointerPhase.up, pt.x, pt.y);
        _window.setCursorPosCallback(null);
      }
    }
  }

  void _onCursorPosChanged(Window window, double x, double y) {
    _sendPointerEvent(PointerPhase.move, x, y);
  }

  void _sendPointerEvent(PointerPhase phase, double x, double y) {
    final timestamp = Duration(microseconds: (Glfw.instance.time * 1000000).toInt());
    _engine.sendPointerEvent(PointerEvent(phase, timestamp, x, y));
  }

  void _onScroll(Window window, double xOffset, double yOffset) {
    print('$this.onScroll($window, $xOffset, $yOffset)');
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
    } else if (message.channel == 'flutter/desktop') {
      switch (methodCall.method) {
        case 'title_drag_start':
          // Windows Only!
          final pt = _window.getCursorPos();
          _sendPointerEvent(PointerPhase.up, pt.x, pt.y);
          _window.setCursorPosCallback(null);
          win32ReleaseCapture();
          win32SendMessage(_window.getWin32Handle(), 0x00A1 /*WM_NCLBUTTONDOWN*/, 2 /*HTCAPTION*/, 0);
          break;

        case 'minimize':
          _window.iconify();
          break;

        case 'maximize':
          if (_window.getWindowAttribute(GLFW_MAXIMIZED) != 0) {
            _window.restore();
          } else {
            _window.maximize();
          }
          break;

        case 'close':
          _window.shouldClose = true;
          break;
      }
    } else if (message.channel == 'flutter/textinput') {
      switch (methodCall.method) {
        case 'TextInput.setClient':
          _clientId = methodCall.arguments[0];
          break;
        case 'TextInput.clearClient':
          _clientId = -1;
          break;
        case 'TextInput.setEditingState':
          _text = methodCall.arguments['text'];
          // composingBase, composingExtent
          break;
      }
    }
  }

  void _onKey(Window window, int key, int scanCode, int action, int mods) {
    print('$this.onKey($window, $key, $scanCode, $action, $mods)');
    if (_clientId != -1 && (action == GLFW_RELEASE || action == GLFW_REPEAT)) {
      if ((key >= GLFW_KEY_A && key <= GLFW_KEY_Z) || key == GLFW_KEY_SPACE) {
        int charCode = key;
        if ((mods & 1) == 0) {
          charCode |= 0x20;
        }
        _text = _text + String.fromCharCode(charCode);
      } else if (key == GLFW_KEY_BACKSPACE) {
        _text = _text.substring(0, math.max(0, _text.length - 1));
      }

      final textUpdate = new MethodCall("TextInputClient.updateEditingState", [
        _clientId,
        {
          'text': _text,
          "selectionBase": _text.length,
          "selectionExtent": _text.length,
          "composingBase": _text.length,
          "composingExtent": _text.length,
        },
      ]);
      _engine.sendPlatformMessage('flutter/textinput', jsonMethodCodec.encodeMethodCall(textUpdate));
    }
  }

  @override
  String toString() => 'DesktopWindow(${identityCode(this)})';
}
