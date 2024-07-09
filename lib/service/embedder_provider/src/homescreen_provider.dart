import 'package:snapp_cli/service/embedder_provider/embedder_provider.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class HomescreenEmbedderProvider extends EmbedderProvider {
  const HomescreenEmbedderProvider({
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

    logger.info('Searching for ivi-homescreen on the remote machine...');
    logger.spaces();

    final possibleFlutterPath = await remoteControllerService.findToolPath(
      username: username,
      ip: targetIp,
      toolName: 'homescreen',
      preferredPaths: [
        '/out/usr/local',
      ],
    );

    if (possibleFlutterPath?.isNotEmpty == true) {
      logger.detail('ivi-homescreen found path: $possibleFlutterPath');

      logger.success('ivi-homescreen found on the remote machine.');
      logger.spaces();

      return possibleFlutterPath!;
    }

    logger.info('''
Could not find ivi-homescreen in the remote machine automatically.
We need the exact path of your ivi-homescreen command line tools on the remote device.
Now you have two options:
1. You can enter the path to flutter manually.
2. We can install ivi-homescreen on the remote machine for you.
''');

    logger.spaces();

    final provideHomescreenPathOption = interaction.selectIndex(
      'Please select one of the options:',
      options: [
        'Enter ivi-homescreen path manually',
        // 'Install ivi-homescreen on the remote machine',
      ],
    );

    logger.spaces();

    if (provideHomescreenPathOption == 0) {
      return interaction.readToolManualPath(
        toolName: 'homescreen',
        examplePath: '/usr/local/bin/homescreen',
      );
    }

    throwToolExit('ivi-homescreen installation is not supported yet.');
  }
}
