import 'package:desktop_simulator/desktop_simulator.dart';
import 'package:desktop_simulator/src/flutter/message_codec.dart';
import 'package:desktop_simulator/src/simulator_window.dart';
import 'dart:math' as math;


/// A plugin which has access to the [NativeView] the the underlying OS.
///
///
abstract class Plugin {

  Plugin(this.nativeView);


  final NativeView nativeView;

  void init();

  void onMethodCall(MethodCall methodCall);

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
  void onMethodCall(MethodCall methodCall) {
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

class DesktopPlugin extends Plugin with SendPointerEventMixin{
  DesktopPlugin(NativeView nativeView) : super(nativeView);


  @override
  String get channel => 'flutter/desktop';

  @override
  void init() {
  }

  @override
  void onMethodCall(MethodCall methodCall) {
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