import 'dart:nativewrappers';
import 'dart-ext:flutter_simulator';


class CallbackTest extends NativeFieldWrapperClass1 {

  static CallbackTest create(CallbackDelegate delegate) native "ctCreate";

  CallbackTest._();

  void test() native "ctTest";
}

abstract class CallbackDelegate {
  int callbackTest(int value);
}
