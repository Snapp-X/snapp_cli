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
    final (ip, username) = interaction.getDeviceInfoInteractively(
      customDevicesConfig,
      'Please select the type of device you want to install Flutter on.',
    );

    // 3. Check if the device is reachable
    await _establishDeviceSshConnection(username, ip);

    // 4. Check if the device has flutter installed
    final flutterPath =
        await remoteControllerService.findFlutterPath(username, ip);

    logger.printSpaces();

    if (flutterPath != null) {
      logger.printSuccess(
          'Flutter is already installed on the device at "$flutterPath"');

      return 0;
    }

    logger.printStatus(
      '''
Flutter is not installed on the device
We will install it for you.
''',
    );
    logger.printSpaces();

    // 5. If not, install snapp_installer on the device
    final snappInstallerPath =
        await remoteControllerService.findSnappInstallerPath(username, ip);

    if (snappInstallerPath == null) {
      logger.printStatus(
        '''
snapp_installer is not installed on the device
but don't worry, we will install it for you.
''',
      );

      logger.printSpaces();

      final snappInstallerInstalled = await remoteControllerService
          .installSnappInstallerOnRemote(username, ip);

      if (!snappInstallerInstalled) {
        throwToolExit('Could not install snapp_installer on the device!');
      }

      logger.printSuccess(
        '''
snapp_installer is installed on the device!
Now we can install flutter on the device with the help of snapp_installer.
''',
      );
    }

    logger.printSpaces();

    // 6. Install flutter on the device with snapp_installer
    final flutterInstalled =
        await remoteControllerService.installFlutterOnRemote(username, ip);

    if (!flutterInstalled) {
      throwToolExit('Could not install flutter on the device!');
    }

    logger.printSuccess('Flutter is installed on the device!');

    return 0;
  }

  Future<void> _establishDeviceSshConnection(
    String username,
    InternetAddress ip,
  ) async {
    final remoteHasSshConnection =
        await sshService.testPasswordLessSshConnection(username, ip);

    if (!remoteHasSshConnection) {
      logger.printFail(
        'could not establish a password-less ssh connection to the remote device. \n',
      );

      logger.printStatus(
          'We can create a ssh connection with the remote device, do you want to try it?');

      final createSshConfirmation = Confirm(
        prompt: 'Create a ssh connection?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      if (!createSshConfirmation) {
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
