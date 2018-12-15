import 'package:flutter_desktop_tools/flutter_desktop_tools.dart' as flutter_desktop_tools;
import 'package:args/args.dart';
import 'package:flutter_desktop_tools/flutter_desktop_tools.dart';


main(List<String> arguments) async {

  print("Got into the script with args: $arguments");

  ArgParser parser = ArgParser();
  ArgParser deviceParser = parser.addCommand('devices');

  ArgParser listParser = deviceParser.addCommand('list');


  ArgParser addParser = deviceParser.addCommand('add');
  addParser.addOption("name");
  addParser.addOption("width");
  addParser.addOption("height");


  ArgParser removeParser = deviceParser.addCommand('remove');
  removeParser.addOption("name");

  ArgResults results = parser.parse(arguments);


  ArgResults commandResult = results.command;

  // TODO if this becomes more, split up in nice command runner system
  if(commandResult.name == 'devices') {
    ArgResults deviceResult = commandResult.command;
    SimulatorManager simulatorManager = SimulatorManager();
    if(deviceResult.name == 'list') {
      await simulatorManager.listSimulators();
    } else if (deviceResult.name == 'add') {
      if(!deviceResult.wasParsed("name")) {
        print("No name specified!");
        return;
      }
      if(!deviceResult.wasParsed('width')) {
        print("No width specified!");
        return;
      }
      if(!deviceResult.wasParsed('height')) {
        print("No height specified!");
        return;
      }

      await simulatorManager.addAddSimulator(deviceResult['name'], int.parse(deviceResult['height']), int.parse(deviceResult['width']));

    } else if(deviceResult.name == 'remove') {
      if(!deviceResult.wasParsed("name")) {
        print("No name specified!");
        return;
      }
      await simulatorManager.removeSimulator(deviceResult['name']);
    }
  }
}
