import 'package:recase/recase.dart';
import 'package:snapp_cli/configs/embedder.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class CustomEmbedderProvider extends DeviceSetupStep {

  CustomEmbedderProvider();

  @override
  Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
    logger.spaces();

    logger.info(
      '''
To execute the app on the remote device, we need to know the app executer. 
The app executer is a tool that will be used to run the app on the remote device. 
The app executer can be the official Flutter Linux embedder or a custom embedder like Flutter-pi or ivi-homescreen.
''',
    );

    logger.spaces();

    final selectedEmbedderIndex = interaction.selectIndex(
      'Select the app executer',
      options: FlutterEmbedder.values.map((e) => e.name.paramCase).toList(),
    );

    final selectedEmbedder = FlutterEmbedder.values[selectedEmbedderIndex];

    return context.copyWith(
      embedder: selectedEmbedder,
    );
  }
}
