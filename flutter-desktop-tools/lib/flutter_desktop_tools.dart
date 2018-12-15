import 'dart:convert';
import 'dart:io';




class SimulatorManager {


  String get _jsonPath => '${Platform.environment['FLUTTER_DART_SIMULATOR']}${Platform.pathSeparator}simulator-configs.json';


  File _getConfigFile() {
    File file = File(_jsonPath);
    if(!file.existsSync()) {
      file.createSync();
    }
    return file;
  }

  List<dynamic> _loadSimulators(File file)  {
    Map<String, dynamic> configJson = json.decode(file.readAsStringSync());
    List<dynamic> simulators = [];

    if(configJson.containsKey('devices')) {
      simulators = configJson['devices'];
    }

    return simulators;
  }

  void _saveSimulators(File file, List<dynamic> simulators) {
    String resultString = jsonEncode({
      'devices': simulators,
    });

    file.writeAsStringSync(resultString);
  }

  Future addAddSimulator(String name, int height, int width) async {
    File configFile = _getConfigFile();
    List<dynamic> simulators = _loadSimulators(configFile);

    simulators.add({
      'name': name,
      'width': width,
      'height': height,
    });

    _saveSimulators(configFile, simulators);
  }

  Future removeSimulator(String name) async {
    File configFile = _getConfigFile();
    List<dynamic> simulators = _loadSimulators(configFile);

    if(simulators.singleWhere((it) => it['name'] == name, orElse: null) == null) {
      throw Exception('There is no simulator named $name, nothing has been done.');
    }
    simulators.removeWhere((it) => it['name'] == name);
    _saveSimulators(configFile, simulators);
  }

  Future listSimulators() async {
    File configFile = _getConfigFile();
    List<dynamic> simulators = _loadSimulators(configFile);

    if(simulators.length == 0) {
      print('No simulator found,\n'
          'create one with "flutter-desktop devices add --name="Simulator" --width=400 --height=500"');
    }
    simulators.forEach((simulator) {
      print('Name: ${simulator['name']}, width: ${simulator['width']}, height: ${simulator['height']}');
    });

  }


}