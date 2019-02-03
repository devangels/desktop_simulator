import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/flutter/message_codec.dart';
import 'package:desktop_simulator/src/flutter/message_codecs.dart';
import 'package:desktop_simulator/src/simulator_window.dart';
import 'dart:math' as math;


// https://fuchsia.googlesource.com/garnet/+/master/public/fidl/fuchsia.ui.input/input_event_constants.fidl
int glfwModToFuchsia(int mod) {
  switch(mod) {
    case 1:
      // Shift
      return 6;
    case 2:
      // Control
      return 24;
    case 4:
      // Alt
      return 96;
    case 8:
      // Super
      return 384;
    default:
      return mod;
  }
}
// TODO move this somewhere else
abstract class Result {
  void success(Map object);

  void error(String var1, String var2, Object var3);

  void notImplemented();
}

// TODO this needs cleanup
class ResultImpl implements Result {
  ResultImpl(this._engine, this.codec, this.channel, this.method);

  final FlutterEngine _engine;

  final JSONMethodCodec codec;

  final String method;

  final String channel;

  @override
  void error(String var1, String var2, Object var3) {
    throw UnimplementedError();
  }

  @override
  void notImplemented() {
    throw UnimplementedError();
  }

  @override
  void success(Map object) {
    _engine.sendPlatformMessage(channel, codec.encodeMethodCall(MethodCall(method, object)));
  }
}

/// A plugin which has access to the [NativeView] the the underlying OS.
///
///
abstract class Plugin {
  Plugin(this.nativeView);

  final NativeView nativeView;

  String get channel;

  void init();

  void onMethodCall(MethodCall methodCall, Result result);
}

mixin SendPointerEventMixin {
  NativeView get nativeView;

  void _sendPointerEvent(PointerPhase phase, double x, double y) {
    final timestamp = Duration(microseconds: (Glfw.instance.time * 1000000).toInt());
    nativeView.engine.sendPointerEvent(PointerEvent(phase, timestamp, x, y));
  }
}

class TextInputPlugin extends Plugin {
  TextInputPlugin(NativeView nativeView) : super(nativeView);

  int _clientId;
  String _text;

  String get _nullSafeText => _text ?? "";

  @override
  String get channel => 'flutter/textinput';

  @override
  void init() {
    nativeView.window.setKeyCallback(_onKey);
  }

  @override
  void onMethodCall(MethodCall methodCall, Result result) {
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

  void _onKey(Window window, int key, int scanCode, int action, int mods) {
    print('$this.onKey($window, $key, $scanCode, $action, $mods)');
    if (_clientId != -1 && (action == GLFW_RELEASE || action == GLFW_REPEAT)) {
      if ((key >= GLFW_KEY_A && key <= GLFW_KEY_Z) || key == GLFW_KEY_SPACE) {
        int charCode = key;
        if ((mods & 1) == 0) {
          charCode |= 0x20;
        }
        _text = _nullSafeText + String.fromCharCode(charCode);
      } else if (key == GLFW_KEY_BACKSPACE) {
        _text = _nullSafeText.substring(0, math.max(0, _text.length - 1));
      }

      final textUpdate = new MethodCall("TextInputClient.updateEditingState", [
        _clientId,
        {
          'text': _text,
          "selectionBase": _nullSafeText.length,
          "selectionExtent": _nullSafeText.length,
          "composingBase": _nullSafeText.length,
          "composingExtent": _nullSafeText.length,
        },
      ]);

      // TODO abstract this into a Response object like Flutter does
      nativeView.engine.sendPlatformMessage('flutter/textinput', jsonMethodCodec.encodeMethodCall(textUpdate));

      // Also sending raw events

      //final rawUpdate = new MethodCall("")
    }

    if (action == GLFW_RELEASE || action == GLFW_PRESS || action == GLFW_REPEAT) {
      String keyType;
      if (action == GLFW_PRESS) {
        keyType = 'keydown';
      } else if (action == GLFW_RELEASE) {
        keyType = 'keyup';
      } else if(action == GLFW_REPEAT) {
        keyType = 'keydown';
      } else {
        print("Not up or down, action was $action");
        return;
      }

      print("THE MODS IS $mods");

      // Do I need this? https://www.glfw.org/docs/latest/group__keys.html
      // "These key codes are inspired by the USB HID Usage Tables v1.12 (p. 53-60), but re-arranged to map to 7-bit ASCII for printable keys (function keys are put in the 256+ range)."
      switch(key) {
        case GLFW_KEY_BACKSPACE:
          print("Sending backspace");
          sendRawKey(0x2A, mods, keyType);
          break;
        case GLFW_KEY_ENTER:
          sendRawKey(0x28, mods, keyType);
          break;
        case GLFW_KEY_A:
          sendRawKey(0x04, mods, keyType);
          break;
        case GLFW_KEY_E:
          sendRawKey(0x08, mods, keyType);
          break;
        case GLFW_KEY_K:
          sendRawKey(0x0E, mods, keyType);
          break;
        case GLFW_KEY_T:
          sendRawKey(0x17, mods, keyType);
          break;
        case GLFW_KEY_Y:
          sendRawKey(0x1C, mods, keyType);
          break;
        case GLFW_KEY_Z:
          sendRawKey(0x1D, mods, keyType);
          break;
        case GLFW_KEY_LEFT:
          sendRawKey(0x50, mods, keyType);
          break;
        case GLFW_KEY_RIGHT:
          sendRawKey(0x4F, mods, keyType);
          break;
        case GLFW_KEY_UP:
          sendRawKey(0x52, mods, keyType);
          break;
        case GLFW_KEY_DOWN:
          sendRawKey(0x51, mods, keyType);
          break;
      }

    }
  }

  void sendRawKey(int hid, int mods, String keyType) {
    print("THE MODS IS $mods");
    final rawEvent = {'keymap': 'fuchsia', 'codePoint': 0, 'modifiers': glfwModToFuchsia(mods), 'hidUsage': hid, 'type': keyType};
    nativeView.engine.sendPlatformMessage('flutter/keyevent', jsonMessageCodec.encodeMessage(rawEvent));
  }
}

class RawTextInputPlugin extends Plugin {
  RawTextInputPlugin(NativeView nativeView) : super(nativeView);

  @override
  String get channel => 'flutter/keyevent';

  @override
  void init() {
    nativeView.window.setRawKeyCallback(_onRawKey);
  }

  @override
  void onMethodCall(MethodCall methodCall, Result result) {}

  void _onRawKey(Window window, int codePoint, int mods) {
    print('$this.onRawKey($window, $codePoint, $mods)');
    final rawEvent = {'keymap': 'fuchsia', 'codePoint': codePoint, 'modifiers': glfwModToFuchsia(mods), 'type': 'keydown'};

    nativeView.engine.sendPlatformMessage(channel, jsonMessageCodec.encodeMessage(rawEvent));
  }
}

class DesktopPlugin extends Plugin with SendPointerEventMixin {
  DesktopPlugin(NativeView nativeView) : super(nativeView);

  @override
  String get channel => 'flutter/desktop';

  bool _dragging = false;

  @override
  void init() {
    nativeView.engine.sendWindowMetricsEvent(WindowMetricsEvent(nativeView.width, nativeView.height, nativeView.pixelRatio2));
    nativeView.window.setWindowSizeCallback(_onSizeChanged);
    nativeView.window.setScrollCallback(_onScroll);
    nativeView.window.setMouseButtonCallback(_onMouseButton);
    nativeView.window.setCursorPosCallback(_onCursorPosChanged);
  }

  void _onSizeChanged(Window window, int width, int height) {
    nativeView.engine.sendWindowMetricsEvent(WindowMetricsEvent(width, height, nativeView.pixelRatio2));
  }

  void _onScroll(Window window, double xOffset, double yOffset) {
    print('$this.onScroll($window, $xOffset, $yOffset)');

    final timestamp = Duration(microseconds: (Glfw.instance.time * 1000000).toInt());
    final scollUpdate = new MethodCall(
      "onScrolled",
      {
        'timeStamp': timestamp.inMicroseconds,
        "xOffset": xOffset,
        "yOffset": yOffset,
      },
    );
    nativeView.engine.sendPlatformMessage(channel, jsonMethodCodec.encodeMethodCall(scollUpdate));
  }

  void _onMouseButton(Window window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_1) {
      if (action == GLFW_PRESS) {
        final pt = nativeView.window.getCursorPos();
        _sendPointerEvent(PointerPhase.down, pt.x, pt.y);
        _dragging = true;
      } else if (action == GLFW_RELEASE) {
        final pt = nativeView.window.getCursorPos();
        _sendPointerEvent(PointerPhase.up, pt.x, pt.y);
        _dragging = false;
      }
    }
  }

  void _onCursorPosChanged(Window window, double x, double y) {
    if (_dragging) {
      _sendPointerEvent(PointerPhase.move, x, y);
    }

    Map hoverEvent = {
      "physicalX": x,
      "physicalY": y,
    };
    nativeView.engine.sendPlatformMessage(channel, jsonMethodCodec.encodeMethodCall(MethodCall("onPositionChanged", hoverEvent)));
  }

  @override
  void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case 'title_drag_start':
        // Windows Only!
        final pt = nativeView.window.getCursorPos();
        _sendPointerEvent(PointerPhase.up, pt.x, pt.y);
        nativeView.window.setCursorPosCallback(null);
        win32ReleaseCapture();
        win32SendMessage(nativeView.window.getWin32Handle(), 0x00A1 /*WM_NCLBUTTONDOWN*/, 2 /*HTCAPTION*/, 0);
        break;

      case 'minimize':
        nativeView.window.iconify();
        break;

      case 'maximize':
        if (nativeView.window.getWindowAttribute(GLFW_MAXIMIZED) != 0) {
          nativeView.window.restore();
        } else {
          nativeView.window.maximize();
        }
        break;
      case 'close':
        nativeView.window.shouldClose = true;
        break;
    }
  }
}

class CursorPlugin extends Plugin {
  CursorPlugin(NativeView nativeView) : super(nativeView);

  static const Map cursors = {
    "Arrow": 0x00036001,
    "Beam": 0x00036002,
    "Crosshair": 0x00036003,
    "Hand": 0x00036004,
    "ResizeX": 0x00036005,
    "ResizeY": 0x00036006,
  };

  @override
  String get channel => "Cursor";

  @override
  void init() {}

  @override
  void onMethodCall(MethodCall methodCall, Result result) {
    if (methodCall.method == "changeCursor") {
      nativeView.window.setCursor(cursors[methodCall.arguments["cursor"]]);
    } else if (methodCall.method == "resetCursor") {
      nativeView.window.setCursor(cursors["Arrow"]);
    }
  }
}

class PlatformPlugin extends Plugin {
  PlatformPlugin(NativeView nativeView) : super(nativeView);

  @override
  String get channel => 'flutter/platform';

  @override
  void init() {}

  @override
  void onMethodCall(MethodCall methodCall, Result result) {
    switch (methodCall.method) {
      case 'SystemChrome.setApplicationSwitcherDescription':
        String label = methodCall.arguments['label'];
        int primaryColor = methodCall.arguments['primaryColor'];
        nativeView.window.setTitle(label);
        result.success(null);
        break;
      case 'SystemSound.play':
        var soundType = methodCall.arguments.toString();
        if (soundType == 'SystemSoundType.click') {
          // System.Media.SystemSounds.Beep.Play();
        }
        break;
    }
  }
}
