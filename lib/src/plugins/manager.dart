

import 'package:desktop_simulator/src/flutter_engine.dart';
import 'package:desktop_simulator/src/plugins/plugin.dart';

abstract class PluginManager {

  void init();

  void registerPlugin(Plugin plugin);

  void handleMethodCall(PlatformMessage message);

}


class PluginManagerImpl extends PluginManager {


  Map<String, Plugin> _plugins = {};

  @override
  void init() {
    // TODO: implement init
  }

  @override
  void registerPlugin(Plugin plugin) {
    if(_plugins.containsKey(plugin.channel)) {
      throw Exception("Plugin ${plugin.channel} could not be added \n"
          "because it already was registered before");
    }
    _plugins[plugin.channel] = plugin;
  }


  @override
  void handleMethodCall(PlatformMessage message) {
    // TODO: implement handleMethodCall
  }

}