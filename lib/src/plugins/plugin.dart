


import 'package:desktop_simulator/src/flutter/message_codec.dart';

abstract class Plugin {

  Plugin();


 // final Flutter flutter;

  void init();

  void onMethodCall(MethodCall call);

  String get channel;

}