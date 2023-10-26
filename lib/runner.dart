import 'package:args/command_runner.dart';
import 'package:raspberry_device/commands/list_command.dart';
import 'package:raspberry_device/commands/add_command.dart';
import 'package:raspberry_device/utils/flutter_sdk.dart';

class Runner extends CommandRunner<int> {
  Runner({required this.flutterSdkManager})
      : super(
          'raspberry_device',
          'A command-line tool to add your rasp',
        ) {
    addCommand(ListCommand(flutterSdkManager: flutterSdkManager));
    addCommand(
      AddCommand(
        flutterSdkManager: flutterSdkManager,
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        terminal: flutterSdkManager.terminal,
        platform: flutterSdkManager.platform,
        logger: flutterSdkManager.logger,
      ),
    );
  }

  final FlutterSdkManager flutterSdkManager;
}
