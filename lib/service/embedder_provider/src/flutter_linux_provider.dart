import 'dart:io';

import 'package:snapp_cli/flutter_sdk.dart';
import 'package:snapp_cli/service/embedder_provider/embedder_provider.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class FlutterLinuxEmbedderProvider extends EmbedderProvider {
  const FlutterLinuxEmbedderProvider({
    required super.context,
    required super.remoteControllerService,
  });

  @override
  Future<String> provideEmbedderPath() async {
    if (context.targetIp == null || context.username == null) {
      throwToolExit(
          'Target IP and username are required to provide the embedder path.');
    }

    final username = context.username!;
    final targetIp = context.targetIp!;

    final hostFlutterVersion =
        FlutterSdkManager().flutterVersion.frameworkVersion;

    final possibleFlutterPath =
        await remoteControllerService.findFlutterPath(username, targetIp);

    // if we found the flutter path on the remote machine
    // then we need to check if the version of the remote flutter is the same as the host flutter
    if (possibleFlutterPath != null) {
      final remoteFlutterVersion =
          await remoteControllerService.findFlutterVersion(
        username,
        targetIp,
        possibleFlutterPath,
      );

      logger.detail('remote flutter version: $remoteFlutterVersion');
      logger.detail('host flutter version: $hostFlutterVersion');

      if (remoteFlutterVersion == hostFlutterVersion) {
        logger.success(
            'You have flutter installed on the remote machine with the same version as your host machine.');
        logger.spaces();

        return possibleFlutterPath;
      } else {
        return _fixConflictVersions(
          username,
          targetIp,
          hostFlutterVersion,
          remoteFlutterVersion!,
        );
      }
    }

    logger.info(
        'Could not find flutter in the remote machine automatically. \n\n'
        'We need the exact path of your flutter command line tools on the remote device. \n'
        'Now you have two options: \n'
        '1. You can enter the path to flutter manually. \n'
        '2. We can install flutter on the remote machine for you. \n');

    logger.spaces();

    final provideFlutterPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Install Flutter on the remote machine',
        'Enter Flutter path manually',
      ],
    );

    logger.spaces();

    if (provideFlutterPathOption == 0) {
      return _installFlutterOnRemote(username, targetIp, hostFlutterVersion);
    }

    return interaction.readFlutterManualPath();
  }

  Future<String> _fixConflictVersions(
    String username,
    InternetAddress targetIp,
    String hostFlutterVersion,
    String remoteFlutterVersion,
  ) async {
    logger.info(
      'To run your app on the remote device, you need the same version of Flutter on both machines. \n\n'
      'Currently, you have a different version of Flutter on the remote machine. \n'
      'Remote Flutter version: $remoteFlutterVersion \n'
      'Host Flutter version: $hostFlutterVersion \n\n'
      'You have two options: \n'
      '1. Manually update your host machine to the same version as the remote machine. \n'
      '2. Install the same version of Flutter on the remote machine for you. \n',
    );

    logger.spaces();

    final provideFlutterPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Manually update your host',
        'Install the same version on the remote',
      ],
    );

    logger.spaces();

    if (provideFlutterPathOption == 0) {
      logger.info(
        'Please update your host machine to the same version as the remote machine and try again.',
      );

      throw Exception('Host Flutter version is different from the remote.');
    }

    return await _installFlutterOnRemote(
        username, targetIp, hostFlutterVersion);
  }

  Future<String> _installFlutterOnRemote(
    String username,
    InternetAddress ip,
    String version,
  ) async {
    final snappInstallerPath = await remoteControllerService
        .findSnappInstallerPathInteractive(username, ip);

    if (snappInstallerPath == null) {
      logger.info(
        '''
snapp_installer is not installed on the device
but don't worry, we will install it for you.
''',
      );

      logger.spaces();

      final snappInstallerInstalled = await remoteControllerService
          .installSnappInstallerOnRemote(username, ip);

      if (!snappInstallerInstalled) {
        throw Exception('Could not install snapp_installer on the device!');
      }

      logger.success(
        '''
snapp_installer is installed on the device!
Now we can install Flutter on the device with the help of snapp_installer.
''',
      );
    }

    logger.spaces();

    final flutterInstalled = await remoteControllerService
        .installFlutterOnRemote(username, ip, version: version);

    if (!flutterInstalled) {
      throw Exception('Could not install Flutter on the device!');
    }

    logger.success('Flutter is installed on the device!');

    return (await remoteControllerService.findFlutterPathInteractive(
      username,
      ip,
    ))!;
  }
}
