// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';

import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/ssh_service.dart';
import 'package:snapp_cli/utils/common.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class InstallFlutterCommand extends BaseSnappCommand {
  InstallFlutterCommand({
    required super.flutterSdkManager,
  })  : sshService = SshService(flutterSdkManager: flutterSdkManager),
        remoteControllerService =
            RemoteControllerService(flutterSdkManager: flutterSdkManager);

  @override
  final String description =
      'Install flutter on the remote device automatically';

  @override
  final String name = 'install-flutter';

  final SshService sshService;
  final RemoteControllerService remoteControllerService;

  @override
  Future<int> run() async {
    // Steps:
    // 1. Check user want to install flutter on a new device or an existing device
    // 2. If new device, get information about the device (IP address, username, password)
    final (ip, username) = await _getDeviceInfoFromUser();

    // 3. Check if the device is reachable
    await _establishDeviceSshConnection(username, ip);

    // 4. Check if the device has flutter installed
    final flutterPath =
        await remoteControllerService.findFlutterPath(username, ip);

    if (flutterPath != null) {
      logger.printSuccess(
          'Flutter is already installed on the device at "$flutterPath"');

      return 0;
    }

    // 5. If not, install snapp_installer on the device
    final snappInstallerPath =
        await remoteControllerService.findSnappInstallerPath(username, ip);

    if (snappInstallerPath == null) {
      logger.printStatus(
        'snapp_installer is not installed on the device, we will install it for you.',
      );

      final snappInstallerInstalled = await remoteControllerService
          .installSnappInstallerOnRemote(username, ip);

      if (!snappInstallerInstalled) {
        throwToolExit('Could not install snapp_installer on the device!');
      }

      logger.printSuccess('snapp_installer is installed on the device!');
    }

    // 6. Install flutter on the device with snapp_installer
    final flutterInstalled =
        await remoteControllerService.installFlutterOnRemote(username, ip);

    if (!flutterInstalled) {
      throwToolExit('Could not install flutter on the device!');
    }

    logger.printSuccess('Flutter is installed on the device!');

    return 0;
  }

  Future<(InternetAddress ip, String username)> _getDeviceInfoFromUser() async {
    final deviceOptions = [
      'Existing device',
      'New device',
    ];

    logger.printStatus(
        'Please select the type of device you want to install Flutter on.');

    final deviceTypeIndex = Select(
      prompt: 'Device Type:',
      options: deviceOptions,
    ).interact();

    final isNewDevice = deviceTypeIndex == 1;

    if (isNewDevice) {
      return getRemoteIpAndUsername(message: 'Please enter the device info:');
    }

    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

Before you can install flutter on a device, you need to add one first.
''',
      );
    }

    final devices = {
      for (var e in customDevicesConfig.devices) '${e.id} : ${e.label}': e
    };

    final selectedDevice = Select(
      prompt: 'Select a target device',
      options: devices.keys.toList(),
    ).interact();

    final deviceKey = devices.keys.elementAt(selectedDevice);

    final targetDevice = devices[deviceKey];

    if (targetDevice == null) {
      throwToolExit(
          'Couldn\'t find device with id "${targetDevice!.id}" in config at "${customDevicesConfig.configPath}"');
    }

    final deviceIp = targetDevice.tryFindDeviceIp;

    if (deviceIp == null) {
      throwToolExit(
        'Couldn\'t find device ip address in ping command for device with id "${targetDevice.id}" in config at "${customDevicesConfig.configPath}"',
      );
    }

    final username = targetDevice.deviceUsername;

    return (InternetAddress.tryParse(deviceIp)!, username);
  }

  Future<void> _establishDeviceSshConnection(
    String username,
    InternetAddress ip,
  ) async {
    var remoteHasSshConnection =
        await sshService.testPasswordLessSshConnection(username, ip);

    if (!remoteHasSshConnection) {
      logger.printFail(
        'could not establish a password-less ssh connection to the remote device. \n',
      );

      logger.printStatus(
          'We can create a ssh connection with the remote device, do you want to try it?');

      final continueWithoutPing = Confirm(
        prompt: 'Create a ssh connection?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      if (!continueWithoutPing) {
        logger.printSpaces();
        throwToolExit(
            'Check your ssh connection with the remote device and try again.');
      }

      logger.printSpaces();

      final sshConnectionCreated =
          await sshService.createPasswordLessSshConnection(username, ip);

      if (!sshConnectionCreated) {
        throwToolExit('Could not create SSH connection to the remote device!');
      }

      logger.printSuccess('SSH connection to the remote device is created!');
    }
  }
}
