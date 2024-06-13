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

    logger.info(
        'Flutter-pi embedder is mocked. The real implementation is not available yet.');

    return 'flutter-pi';
  }
}
