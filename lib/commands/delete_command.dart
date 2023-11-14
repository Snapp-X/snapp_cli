// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/command_runner/command_runner.dart';
import 'package:snapp_cli/commands/base_command.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class DeleteCommand extends BaseSnappCommand {
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
    /// check if the user has provided a device id with the -d option
    if (globalResults!.wasParsed(deviceIdOption)) {
      final deviceId = globalResults!.stringArg(deviceIdOption)!;

      return _deleteDeviceWithId(deviceId);
    }

    /// if the user didn't provide a device id, then we will show an interactive
    /// prompt to select a device to delete
    return _interactiveDeleteDevice();
  }

  /// Delete device with id [deviceId] from the Flutter SDK
  int _deleteDeviceWithId(String deviceId) {
    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    customDevicesConfig.remove(deviceId);
    logger.printStatus(
        'Successfully removed device with id "$deviceId" from config at "${customDevicesConfig.configPath}"');

    return 0;
  }

  int _interactiveDeleteDevice() {
    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

Before you can delete a device, you need to add one first.
''',
      );
    }

    final devices = {
      for (var e in customDevicesConfig.devices) '${e.id} : ${e.label}': e.id
    };

    final selectedDevice = Select(
      prompt: 'Select a device to delete',
      options: devices.keys.toList(),
    ).interact();

    final deviceKey = devices.keys.elementAt(selectedDevice);

    final deviceId = devices[deviceKey];

    if (deviceId == null) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    return _deleteDeviceWithId(deviceId);
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
