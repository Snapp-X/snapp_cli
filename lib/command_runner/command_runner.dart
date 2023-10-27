import 'package:args/command_runner.dart';
import 'package:snapp_debugger/commands/delete_command.dart';
import 'package:snapp_debugger/commands/list_command.dart';
import 'package:snapp_debugger/commands/add_command.dart';
import 'package:snapp_debugger/commands/update_ip_command.dart';
import 'package:snapp_debugger/utils/flutter_sdk.dart';

class SnappDebuggerCommandRunner extends CommandRunner<int> {
  SnappDebuggerCommandRunner({required this.flutterSdkManager})
      : super(
          'snapp_debugger',
          'A command-line tool to manage custom devices for flutter',
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
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
      ),
    );
    addCommand(
      UpdateIpCommand(
        customDevicesConfig: flutterSdkManager.customDeviceConfig,
        logger: flutterSdkManager.logger,
      ),
    );
  }

  final FlutterSdkManager flutterSdkManager;
}
