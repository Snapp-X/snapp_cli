import 'package:args/command_runner.dart';
import 'package:snapp_debugger/commands/delete_command.dart';
import 'package:snapp_debugger/commands/list_command.dart';
import 'package:snapp_debugger/commands/add_command.dart';
import 'package:snapp_debugger/utils/flutter_sdk.dart';

class SnappDebuggerCommandRunner extends CommandRunner<int> {
  SnappDebuggerCommandRunner({required this.flutterSdkManager})
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
    addCommand(
      DeleteCommand(
        flutterSdkManager: flutterSdkManager,
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
        platform: flutterSdkManager.platform,
      ),
    );
  }

  final FlutterSdkManager flutterSdkManager;
}
