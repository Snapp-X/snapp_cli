// ignore_for_file: implementation_imports

import 'package:args/command_runner.dart';
import 'package:snapp_cli/commands/delete_command.dart';
import 'package:snapp_cli/commands/list_command.dart';
import 'package:snapp_cli/commands/add_command.dart';
import 'package:snapp_cli/commands/update_ip_command.dart';
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
    // List command to list all custom devices
    addCommand(
      ListCommand(
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
      ),
    );

    // Add command to add a new custom device
    addCommand(
      AddCommand(
        flutterSdkManager: flutterSdkManager,
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        platform: flutterSdkManager.platform,
        logger: flutterSdkManager.logger,
      ),
    );

    // Delete command to delete a custom device
    addCommand(
      DeleteCommand(
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
      ),
    );

    // Update IP command to update the IP address of a custom device
    addCommand(
      UpdateIpCommand(
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
      ),
    );
  }

  final FlutterSdkManager flutterSdkManager;
}
