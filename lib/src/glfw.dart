import 'dart:math' show Point, Rectangle;

import 'dart-ext:flutter_simulator';

export 'package:desktop_simulator/src/glfw_const.dart';

// FIXME: callbacks to be updated with enums?
typedef WindowSizeFunc = void Function(Window window, int width, int height);
typedef KeyFunc = void Function(Window window, int key, int scanCode, int action, int mods);
typedef MouseButtonFunc = void Function(Window window, int button, int action, int mods);
typedef CursorPosFunc = void Function(Window window, double xpos, double ypos);
typedef ScrollFunc = void Function(Window window, double xOffset, double yOffset);
typedef RawKeyFunc = void Function(Window window, int codePoint, int mods);

final glfw = Glfw.instance;

class Glfw {
  static final Glfw instance = const Glfw();

  const Glfw();

  bool init() native 'glfwInit';

  void terminate() native 'glfwTerminate';

  String get version native 'glfwGetVersionString';

  double get time native 'glfwGetTime';

  Monitor get primaryMonitor native 'glfwGetPrimaryMonitor';

  set clipboard(String value) native 'glfwSetClipboardString';

  String get clipboard native 'glfwGetClipboardString';

  static void waitEventsTimeout(double timeout) native 'glfwWaitEventsTimeout';

  static void windowHint(int hint, int value) native 'glfwWindowHint';

  static Window createWindow(int width, int height, String title, Monitor monitor, Window share) native 'glfwCreateWindow';
}

class Window {
  static final None = const Window(0);
  const Window(this._nativePtr);
  final int _nativePtr;

  int get nativePtr => _nativePtr;

  String toString() => 'Window(0x${_nativePtr.toRadixString(16)})';

  set shouldClose(bool value) native 'glfwSetWindowShouldClose';
  bool get shouldClose native 'glfwWindowShouldClose';

  void setUserData<T>(T data) native 'glfwSetWindowUserPointer';

  T getUserData<T>() native 'glfwGetWindowUserPointer';

  Rectangle<int> get size native 'glfwGetWindowSize';

  void setPosition(int xPos, int yPos) native 'glfwSetWindowPos';

  /// Specify GLFW_DONT_CARE for parameters you don't want to set.
  void setSizeLimits(int minWidth, int minHeight, int maxWidth, int maxHeight) native 'glfwSetWindowSizeLimits';

  Point<double> getCursorPos() native "glfwGetCursorPos";

  // TODO is causes a tiny memory leak until glfwTerminate is called. This should be returned to Dart to destroy.
  void setCursor(int cursorCode) native "glfwSetCursor";

  void setTitle(String title) native "glfwSetWindowTitle";

  void iconify() native "glfwIconifyWindow";

  void restore() native "glfwRestoreWindow";

  void maximize() native "glfwMaximizeWindow";

  int getWin32Handle() native "glfwGetWin32Window";

  int getWindowAttribute(int attribute) native "glfwGetWindowAttrib";

  //TODO implement set cursor

  void centerOnMonitor() {
    final videoMode = glfw.primaryMonitor.videoMode;
    final size = this.size;
    final x = (videoMode.width - size.width) ~/ 2;
    final y = (videoMode.height - size.height) ~/ 2;
    setPosition(x, y);
  }

  WindowSizeFunc setWindowSizeCallback(WindowSizeFunc windowSizeFn) native 'glfwSetWindowSizeCallback';

  KeyFunc setKeyCallback(KeyFunc keyFn) native 'glfwSetKeyCallback';

  RawKeyFunc setRawKeyCallback(RawKeyFunc rawKeyFn) native 'glfwSetRawKeyCallback';

  MouseButtonFunc setMouseButtonCallback(MouseButtonFunc mouseButtonFn) native 'glfwSetMouseButtonCallback';

  CursorPosFunc setCursorPosCallback(CursorPosFunc cursorPosFn) native "glfwSetCursorPosCallback";

  ScrollFunc setScrollCallback(ScrollFunc scrollFn) native 'glfwSetScrollCallback';

  void dispose() native 'glfwDestroyWindow';
}

class Monitor {
  static final None = const Monitor(0);

  const Monitor(this._nativePtr);

  final int _nativePtr;

  String toString() => 'Monitor(0x${_nativePtr.toRadixString(16)})';

  VideoMode get videoMode native 'glfwGetVideoMode';
}

class VideoMode {
  const VideoMode(
    this.width,
    this.height,
    this.redBits,
    this.greenBits,
    this.blueBits,
    this.refreshRate,
  );

  final int width;
  final int height;
  final int redBits;
  final int greenBits;
  final int blueBits;
  final int refreshRate;
}
