// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:snapp_debugger/command_runner/command_runner.dart';
import 'package:snapp_debugger/commands/base_command.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class DeleteCommand extends BaseDebuggerCommand {
  DeleteCommand({
    required super.customDevicesConfig,
    required super.logger,
  });

  @override
  final String description = 'Delete a custom device from the Flutter SDK';

  @override
  final String name = 'delete';

  @override
  FutureOr<int>? run() {
    if (!globalResults!.wasParsed(deviceIdOption)) {
      missingRequiredOption();
    }

    final deviceId = globalResults!.stringArg(deviceIdOption)!;

    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    customDevicesConfig.remove(deviceId);
    logger.printStatus(
        'Successfully removed device with id "$deviceId" from config at "${customDevicesConfig.configPath}"');

    return 0;
  }

  void missingRequiredOption() {
    usageException(
      '''
Delete command requires a device id
You can run this command like this:

${runner!.executableName} $name -d <device-id>

''',
    );
  }
}
