// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:snapp_debugger/command_runner/command_runner.dart';
import 'package:snapp_debugger/commands/base_command.dart';
import 'package:flutter_tools/src/base/io.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

const _ipOption = 'ip';

class UpdateIpCommand extends BaseDebuggerCommand {
  UpdateIpCommand({
    required super.customDevicesConfig,
    required super.logger,
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
    if (argResults!.options.length < 2) {
      missingRequiredOption();
    }

    if (wasProvided(deviceIdOption)) {
      missingRequiredOption();
    }

    final deviceId = stringArg(deviceIdOption)!;

    if (wasProvided(_ipOption)) {
      missingRequiredOption();
    }

    final ip = stringArg(_ipOption)!;

    final isIpValid = InternetAddress.tryParse(ip) != null;

    if (!isIpValid) {
      usageException('Ip address passed to this command is not valid');
    }

    if (!customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${customDevicesConfig.configPath}"');
    }

    _changeIp(deviceId, ip);

    return 0;
  }

  void missingRequiredOption() {
    usageException(
      '''
Update IP command requires a device id and an IP address
You can run this command like this:

${runner!.executableName} $name -d <device-id> -i <ip-address>

''',
    );
  }

  void _changeIp(String deviceId, String newIp) {
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
  }

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
}
