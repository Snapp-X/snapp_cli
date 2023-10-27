// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:snapp_debugger/commands/base_command.dart';
import 'package:flutter_tools/src/base/io.dart';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

class UpdateIpCommand extends BaseCommand {
  UpdateIpCommand({
    required CustomDevicesConfig customDevicesConfig,
    required Logger logger,
  })  : _customDevicesConfig = customDevicesConfig,
        _logger = logger {
    argParser.addOption(
      FlutterGlobalOptions.kDeviceIdOption,
      abbr: 'd',
      help: 'Target device id or name (prefixes allowed).',
    );
    argParser.addOption(
      'ip',
      abbr: 'i',
      help: 'The IP address of the remote device',
    );
  }

  final CustomDevicesConfig _customDevicesConfig;
  final Logger _logger;

  @override
  String get description => 'Update the IP address of the remote device';

  @override
  String get name => 'update-ip';

  @override
  FutureOr<int>? run() {
    if (argResults!.options.isEmpty) {
      usageException('Update IP command requires a device id');
    }

    final deviceId = argResults![FlutterGlobalOptions.kDeviceIdOption];
    if (deviceId == Null || deviceId is! String) {
      usageException('Update IP command requires a device id');
    }

    final ip = argResults!['ip'];
    if (ip == Null || ip is! String) {
      usageException('Update IP command requires an IP address');
    }

    final isIpValid = InternetAddress.tryParse(ip) != null;

    if (!isIpValid) {
      usageException('Ip address passed to this command is not valid');
    }

    if (!_customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${_customDevicesConfig.configPath}"');
    }

    _changeIp(deviceId, ip);

    return 0;
  }

  void _changeIp(String deviceId, String newIp) {
    final currentDeviceConfig = _customDevicesConfig.devices
        .firstWhere((element) => element.id == deviceId);

    final oldIp = _findOldIpInPingCommand(currentDeviceConfig.pingCommand);

    if (oldIp == null) {
      throwToolExit(
        '''
Couldn't find device old IP in pingCommand for the device with id "$deviceId" in config at "${_customDevicesConfig.configPath}"
This could be because of a malformed ping command
Or Maybe you entered a host name instead of IpAddress in add command
        ''',
      );
    }

    final newDeviceConfig = _replaceNewIp(currentDeviceConfig, oldIp, newIp);

    final newDeviceRemoved =
        _customDevicesConfig.remove(currentDeviceConfig.id);

    if (!newDeviceRemoved) {
      throwToolExit(
        'Something went wrong in removing old device process. Device id: "$deviceId" in config at "${_customDevicesConfig.configPath}"',
      );
    }

    _customDevicesConfig.add(newDeviceConfig);

    _logger.printStatus(
      'IP address of device with id "$deviceId" successfully changed from "$oldIp" to "$newIp" in config at "${_customDevicesConfig.configPath}"',
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
