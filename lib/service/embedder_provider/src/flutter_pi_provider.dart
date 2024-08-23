import 'dart:io';

import 'package:snapp_cli/service/embedder_provider/embedder_provider.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class FlutterPiEmbedderProvider extends EmbedderProvider {
  const FlutterPiEmbedderProvider({
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

    logger.info('Searching for flutter-pi on the remote machine...');
    logger.spaces();

    final possibleFlutterPath = await remoteControllerService.findToolPath(
        username: username,
        ip: targetIp,
        toolName: 'flutter-pi',
        preferredPaths: [
          '/usr/local/bin',
        ]);

    if (possibleFlutterPath?.isNotEmpty == true) {
      logger.detail('flutter-pi found path: $possibleFlutterPath');

      logger.success('flutter-pi found on the remote machine.');
      logger.spaces();

      return possibleFlutterPath!;
    }

    logger.info('''
Could not find flutter-pi in the remote machine automatically.
We need the exact path of your flutter-pi command line tools on the remote device.
Now you have two options:
1. You can enter the path to flutter manually.
2 We can install flutter-pi on the remote machine for you.
''');

    logger.spaces();

    final provideFlutterPiPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Install flutter-pi on the remote machine',
        'Enter flutter-pi path manually',
      ],
    );

    logger.spaces();

    if (provideFlutterPiPathOption == 0) {
      return _installFlutterPiOnRemote(username, targetIp);
    }

    return interaction.readToolManualPath(
      toolName: 'flutter-pi',
      examplePath: '/usr/local/bin/flutter-pi',
    );
  }

  Future<String> _installFlutterPiOnRemote(
    String username,
    InternetAddress ip,
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
Now we can install flutter-pi on the device with the help of snapp_installer.
''',
      );
    }

    logger.spaces();

    final flutterPiInstalled =
        await remoteControllerService.installFlutterPiOnRemote(
      username,
      ip,
    );

    if (!flutterPiInstalled) {
      throw Exception('Could not install flutter-pi on the device!');
    }

    logger.success('flutter-pi is installed on the device!');

    logger.spaces();

    logger.warn('flutter-pi needs cli-auto login to run.');
    logger.warn('Please REBOOT your remote device to apply the changes.');
    logger.warn('After rebooting, you can run your app with flutter-pi.');

    logger.spaces();
    return (await remoteControllerService.findToolPathInteractive(
      username: username,
      ip: ip,
      toolName: 'flutter-pi',
      preferredPaths: [
        '/usr/local/bin',
      ],
    ))!;
  }
}
