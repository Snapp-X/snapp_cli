import 'package:recase/recase.dart';
import 'package:snapp_cli/configs/embedder.dart';
import 'package:snapp_cli/service/embedder_provider/embedder_provider.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/chain_handler/device_setup_handler.dart';

class AppExecuterHandler extends DeviceSetupHandler {
  final RemoteControllerService remoteControllerService;

  AppExecuterHandler({required this.remoteControllerService});

  @override
  Future<DeviceSetupContext> execute(DeviceSetupContext context) async {
    logger.spaces();

    logger.info(
      '''
To execute the app on the remote device, we need to know the app executer. 
The app executer is a tool that will be used to run the app on the remote device. 
The app executer can be the official Flutter Linux embedder or a custom embedder like Flutter-pi or ivi-homescreen.
Supported app executers:
''',
    );

    FlutterEmbedder.values.forEach((embedder) {
      logger.info(' - ${embedder.name.paramCase}');
    });

    logger.spaces();

    final selectedEmbedderIndex = interaction.selectIndex(
      'Select the app executer',
      options: FlutterEmbedder.values.map((e) => e.name.paramCase).toList(),
    );

    final selectedEmbedder = FlutterEmbedder.values[selectedEmbedderIndex];

    final embedderProvider = EmbedderProvider.create(
      selectedEmbedder,
      context,
      remoteControllerService,
    );

    final executablePath = await embedderProvider.provideEmbedderPath();

    return context.copyWith(
      appExecuterPath: executablePath,
    );
  }
}
