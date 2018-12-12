# desktop_simulator

Desktop embedder written in dart.

## Why is this written in Dart?
Dart is an awesome language. But that's not the only reason!
Because people writing Flutter apps are already familiar
with Dart, they will have an easy time writing plugins for
desktop. 

Compared to Android and iOS where you have to first learn
Java/Kotlin/ObjectiveC/Swift writing plugins for desktop is as simple
as interfacing C code with Dart and doing the logic there.

The interfacing will get event easier with Dart 
supporting FFI (https://github.com/dart-lang/sdk/issues/34452).

Another reason is: Dart runs cross platform and can bit JIT compiled.
This means we get out of the box cross platform support without having to
explicitly write for each platform. 
Because Dart can be JIT compiled working one the native side is as easy as 
restarting the app (it may even be possible to support hot-reloads of native code in the future).

All of this also leads to a richer Dart ecosystem which we all strive for. 
More people using Dart means more people open sourcing code which enhances the whole
ecosystem.

## Installation
We aimed for the easies installation process we could think of.

TODO make this.

So we decided to stay close to how Flutter itself is installed.

### 1. Clone is repository
```
git clone x...x...x
```
### 2. Run flutter-desktop setup
This will create a few environment variables in your system
```
flutter-desktop setup
```

### 3. Override the default target platform in your app
```dart
    import 'package:flutter/foundation.dart'
        show debugDefaultTargetPlatformOverride;

    void main() {
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      runApp(new MyApp());
    }
```

### Run any app!
Go to the root of your project and type:
```
flutter-desktop run
```
Hot reloading will work out of the box.

### IDE support
If you want to have the same IDE experience as working with the emulator. 
Then you will have to use our Flutter branch until the tooling is merged
into Flutter.

To do this do the following...



## Roadmap

- Wrap the Window, Linux and Mac API with dart 
    (https://github.com/AllenDang/w32) and expose as
    a single API to dart and ultimately Flutter
- Write widgets for every desktop use case


