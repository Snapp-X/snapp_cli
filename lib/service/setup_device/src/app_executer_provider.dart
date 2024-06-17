import 'package:snapp_cli/service/embedder_provider/embedder_provider.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class AppExecuterProvider extends DeviceSetupStep {
  final RemoteControllerService remoteControllerService;

  AppExecuterProvider({required this.remoteControllerService});

  @override
  Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
    logger.spaces();

    final selectedEmbedder = context.embedder!;

    final embedderProvider = EmbedderProvider.create(
      selectedEmbedder,
      context,
      remoteControllerService,
    );

    final executablePath = await embedderProvider.provideEmbedderPath();

    return context.copyWith(
      appExecuterPath: executablePath,
      embedder: selectedEmbedder,
    );
  }
}
