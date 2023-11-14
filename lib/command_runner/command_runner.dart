// ignore_for_file: implementation_imports

import 'package:args/command_runner.dart';
import 'package:snapp_cli/commands/devices/devices_command.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';

const deviceIdOption = FlutterGlobalOptions.kDeviceIdOption;

class SnappCliCommandRunner extends CommandRunner<int> {
  SnappCliCommandRunner({required this.flutterSdkManager})
      : super(
          'snapp_cli',
          'A command-line tool to manage custom devices for flutter',
        ) {
    // Add the device id option to all commands
    argParser.addOption(
      deviceIdOption,
      abbr: 'd',
      help: 'Target device id or name (prefixes allowed).',
    );

    // Add the devices command to the command runner
    addCommand(DevicesCommand(flutterSdkManager: flutterSdkManager));
  }

  final FlutterSdkManager flutterSdkManager;
}
