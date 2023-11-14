// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/command_runner/command_runner.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:flutter_tools/src/base/io.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

const _ipOption = 'ip';

class UpdateIpCommand extends BaseSnappCommand {
  UpdateIpCommand({
    required super.flutterSdkManager,
  }) {
    argParser.addOption(
      _ipOption,
      abbr: 'i',
      help: 'The IP address of the remote device',
    );
  }

  @override
  String get description => 'Update the IP address of the remote device';

  @override
  String get name => 'update-ip';

  @override
  FutureOr<int>? run() {
    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

Before you can update a device, you need to add one first.
''',
      );
    }

    String? deviceId;
    if (globalResults!.wasParsed(deviceIdOption)) {
      deviceId = globalResults!.stringArg(deviceIdOption)!;
    }

    String? ip;
    if (argResults!.wasParsed(_ipOption)) {
      ip = argResults!.stringArg(_ipOption)!;
    }

    if (deviceId != null && ip != null) {
      if (!_isValidIpAddr(ip)) {
        usageException('Ip address passed to this command is not valid');
      }

      return _updateIp(deviceId, ip);
    }

    return _interactiveUpdateIp(deviceId, ip);
  }

  int _interactiveUpdateIp(String? deviceId, String? ip) {
    if (deviceId == null) {
      final devices = {
        for (var e in customDevicesConfig.devices) '${e.id} : ${e.label}': e.id
      };

      logger.printStatus('Please select a device to update its IP address.');

      final selectedDevice = Select(
        prompt: 'Target device',
        options: devices.keys.toList(),
      ).interact();

      final deviceKey = devices.keys.elementAt(selectedDevice);

      deviceId = devices[deviceKey];
    }

    if (deviceId == null) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    if (ip == null) {
      logger.printStatus(
        'Please enter the new IP-address of the device. (example: 192.168.1.101)',
      );

      final String newIp = Input(
        prompt: 'New IP-address:',
        validator: (s) {
          if (_isValidIpAddr(s)) {
            return true;
          }
          throw ValidationError('Invalid IP-address. Please try again.');
        },
      ).interact();

      ip = newIp;
    }

    return _updateIp(deviceId, ip);
  }

  int _updateIp(String deviceId, String newIp) {
    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    final currentDeviceConfig = customDevicesConfig.devices
        .firstWhere((element) => element.id == deviceId);

    final oldIp = _findOldIpInPingCommand(currentDeviceConfig.pingCommand);

    if (oldIp == null) {
      throwToolExit(
        '''
Couldn't find device old IP in pingCommand for the device with id "$deviceId" in config at "${customDevicesConfig.configPath}"
This could be because of a malformed ping command
Or Maybe you entered a host name instead of IpAddress in add command
        ''',
      );
    }

    final newDeviceConfig = _replaceNewIp(currentDeviceConfig, oldIp, newIp);

    final newDeviceRemoved = customDevicesConfig.remove(currentDeviceConfig.id);

    if (!newDeviceRemoved) {
      throwToolExit(
        'Something went wrong in removing old device process. Device id: "$deviceId" in config at "${customDevicesConfig.configPath}"',
      );
    }

    customDevicesConfig.add(newDeviceConfig);

    logger.printStatus(
      'IP address of device with id "$deviceId" successfully changed from "$oldIp" to "$newIp" in config at "${customDevicesConfig.configPath}"',
    );

    return 0;
  }

  bool _isValidIpAddr(String s) => InternetAddress.tryParse(s) != null;

  /// find ip v4 and v6 in ping command
  String? _findOldIpInPingCommand(List<String> pingCommand) {
    return pingCommand.firstWhereOrNull(
      (element) => InternetAddress.tryParse(element) != null,
    );
  }

  CustomDeviceConfig _replaceNewIp(
    CustomDeviceConfig device,
    String oldIp,
    String newIp,
  ) {
    final newDevice = device.copyWith();

    final newPingCommand = _replaceNewIpInCommand(
      newDevice.pingCommand,
      oldIp,
      newIp,
    );

    final newPostBuildCommand = _replaceNewIpInCommand(
      newDevice.postBuildCommand,
      oldIp,
      newIp,
    );

    final newInstallCommand = _replaceNewIpInCommand(
      newDevice.installCommand,
      oldIp,
      newIp,
    );

    final newUninstallCommand = _replaceNewIpInCommand(
      newDevice.uninstallCommand,
      oldIp,
      newIp,
    );

    final newRunDebugCommand = _replaceNewIpInCommand(
      newDevice.runDebugCommand,
      oldIp,
      newIp,
    );

    final newForwardPortCommand = _replaceNewIpInCommand(
      newDevice.forwardPortCommand,
      oldIp,
      newIp,
    );

    final newScreenshotCommand = _replaceNewIpInCommand(
      newDevice.screenshotCommand,
      oldIp,
      newIp,
    );

    return newDevice.copyWith(
      pingCommand: newPingCommand,
      postBuildCommand: newPostBuildCommand,
      installCommand: newInstallCommand,
      uninstallCommand: newUninstallCommand,
      runDebugCommand: newRunDebugCommand,
      forwardPortCommand: newForwardPortCommand,
      screenshotCommand: newScreenshotCommand,
    );
  }

  List<String>? _replaceNewIpInCommand(
    List<String>? command,
    String oldIp,
    String newIp,
  ) =>
      command?.map((item) {
        final hasOldInText = item.contains(oldIp);

        if (hasOldInText) {
          return item.replaceAll(oldIp, newIp);
        }
        return item;
      }).toList();

  void missingRequiredOption() {
    usageException(
      '''
Update IP command requires a device id and an IP address
You can run this command like this:

${runner!.executableName} $name -d <device-id> -i <ip-address>

''',
    );
  }
}
