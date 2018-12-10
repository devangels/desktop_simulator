import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/flutter/message_codec.dart';
import 'package:desktop_simulator/src/flutter/message_codecs.dart';
import 'package:desktop_simulator/src/simulator_window.dart';
import 'dart:math' as math;


// TODO move this somewhere else
abstract class Result {

  void success(Map object);

  void error(String var1,  String var2, Object var3);

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

  void init();

  void onMethodCall(MethodCall methodCall, Result result);

  String get channel;

}


mixin SendPointerEventMixin on Plugin {

  void _sendPointerEvent(PointerPhase phase, double x, double y) {
    final timestamp = Duration(microseconds: (Glfw.instance.time * 1000000).toInt());
    nativeView.engine.sendPointerEvent(PointerEvent(phase, timestamp, x, y));
  }
}

class TextInputPlugin extends Plugin {

  TextInputPlugin(NativeView nativeView) : super(nativeView);

  int _clientId;
  String _text;


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
      // TODO abstract this into a Response object like Flutter does
      nativeView.engine.sendPlatformMessage('flutter/textinput', jsonMethodCodec.encodeMethodCall(textUpdate));
    }
  }

}


class MousePlugin extends Plugin with SendPointerEventMixin {
  MousePlugin(NativeView nativeView) : super(nativeView);


  bool _dragging = false;

  // Has no channel because it cannot receive input
  @override
  String get channel => "";

  @override
  void init() {
    nativeView.window.setMouseButtonCallback(_onMouseButton);
  }

  void _onCursorPosChanged(Window window, double x, double y) {
    _sendPointerEvent(PointerPhase.move, x, y);
  }


  void _onMouseButton(Window window, int button, int action, int mods) {
    if (button == GLFW_MOUSE_BUTTON_1) {
      if (_dragging) {
        if (action == GLFW_RELEASE) {
          _dragging = false;
        }
      } else if (action == GLFW_PRESS) {
        final pt = nativeView.window.getCursorPos();
        _sendPointerEvent(PointerPhase.down, pt.x, pt.y);
        nativeView.window.setCursorPosCallback(_onCursorPosChanged);
      } else if (action == GLFW_RELEASE) {
        final pt = nativeView.window.getCursorPos();
        _sendPointerEvent(PointerPhase.up, pt.x, pt.y);
        nativeView.window.setCursorPosCallback(null);
      }
    }
  }

  @override
  void onMethodCall(MethodCall methodCall, Result result) {}

}

class DesktopPlugin extends Plugin with SendPointerEventMixin{
  DesktopPlugin(NativeView nativeView) : super(nativeView);


  @override
  String get channel => 'flutter/desktop';

  @override
  void init() {
    nativeView.engine.sendWindowMetricsEvent(WindowMetricsEvent(nativeView.width, nativeView.height, nativeView.pixelRatio2));
    nativeView.window.setWindowSizeCallback(_onSizeChanged);
    nativeView.window.setScrollCallback(_onScroll);

  }


  void _onSizeChanged(Window window, int width, int height) {
    nativeView.engine.sendWindowMetricsEvent(WindowMetricsEvent(width, height, nativeView.pixelRatio2));
  }


  void _onScroll(Window window, double xOffset, double yOffset) {
    print('$this.onScroll($window, $xOffset, $yOffset)');

    final timestamp = Duration(microseconds: (Glfw.instance.time * 1000000).toInt());
    final scollUpdate = new MethodCall("onPositionChanged",
      {
        'timeStamp': timestamp,
        "physicalX": xOffset,
        "physicalY": yOffset,
      },
    );
    nativeView.engine.sendPlatformMessage(channel, jsonMethodCodec.encodeMethodCall(scollUpdate));
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

class PlatformPlugin extends Plugin {
  PlatformPlugin(NativeView nativeView) : super(nativeView);

  @override
  String get channel => 'flutter/platform';

  @override
  void init() {

  }

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