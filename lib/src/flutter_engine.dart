import 'dart:nativewrappers';
import 'dart:typed_data';

import 'package:desktop_simulator/src/glfw.dart';
import 'package:meta/meta.dart';

import 'dart-ext:flutter_simulator';

String identityCode(Object obj) => '0x${obj.hashCode.toRadixString(16).padLeft(8, '0')}';

void win32ReleaseCapture() native 'win32ReleaseCapture';
void win32SendMessage(int hWnd, int Msg, int wParam, int lParam) native 'win32SendMessage';

class FlutterEngine extends NativeFieldWrapperClass1 {
  FlutterEngine._();

  static FlutterEngine create(Window window, EngineDelegate delegate, EngineArgs args) native "feCreate";

  void shutdown() native "feShutdown";

  bool sendWindowMetricsEvent(WindowMetricsEvent event) native "feSendWindowMetricsEvent";

  bool sendPointerEvent(PointerEvent event) native "feSendPointerEvent";

  bool sendPlatformMessage(String channel, ByteData data) native "feSendPlatformMessage";

  bool flushPendingTasks() native "feFlushPendingTasksNow";

  String toString() => "FlutterEngine(${identityCode(this)})";
}

abstract class EngineDelegate {
  void platformMessage(PlatformMessage message);
}

class EngineArgs {
  const EngineArgs({
    @required this.assetsPath,
    this.mainPath = '',
    this.packagesPath = '',
    @required this.icuDataPath,
    @required this.commandLineArgs,
  });

  /// The path to the |flutter_assets| directory containing project assets.
  final String assetsPath;

  /// The path to the Dart file containing the |main| entry point.
  final String mainPath;

  /// The path to the |.packages| for the project.
  final String packagesPath;

  /// The path to the |icudtl.dat| file for the project.
  final String icuDataPath;

  /// The command line arguments used to initialize the project.
  final List<String> commandLineArgs;

  @override
  String toString() => 'EngineArgs(${identityCode(this)}){$assetsPath, $mainPath, $packagesPath, $icuDataPath, $commandLineArgs}';
}

class WindowMetricsEvent {
  const WindowMetricsEvent(this.width, this.height, this.pixelRatio);

  /// Physical width of the window.
  final int width;

  /// Physical height of the window.
  final int height;

  /// Scale factor for the physical screen.
  final double pixelRatio;

  @override
  String toString() => 'WindowMetricsEvent(${identityCode(this)}){$width, $height, $pixelRatio}';
}

enum PointerPhase {
  cancel,
  up,
  down,
  move,
}

class PointerEvent {
  const PointerEvent(this.phase, this.timestamp, this.x, this.y);

  final PointerPhase phase;
  final Duration timestamp;
  final double x;
  final double y;

  @override
  String toString() => 'PointerEvent(${identityCode(this)}){$phase, $timestamp, $x, $y}';
}

class PlatformMessage extends NativeFieldWrapperClass2 {
  PlatformMessage._(this.channel, this.message);

  final String channel;
  final Uint8List message;

  ByteData get asByteData => message.buffer.asByteData();

  bool responseSuccess() => respond(null);

  bool respond(ByteData data) native "feSendPlatformMessageResponse";

  @override
  String toString() => 'PlatformMessage(${identityCode(this)}){$channel, ${String.fromCharCodes(message)}}';
}
