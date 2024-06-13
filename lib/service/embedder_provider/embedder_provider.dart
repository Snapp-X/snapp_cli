import 'package:snapp_cli/configs/embedder.dart';
import 'package:snapp_cli/service/embedder_provider/src/flutter_linux_provider.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/chain_handler/device_setup_handler.dart';

/// EmbedderProvider is an abstract class that provides the embedder which is responsible to execute the flutter app
///
/// The embedder can be the official Flutter Linux embedder
/// or a custom embedders like Flutter-pi or ivi-homescreen
abstract class EmbedderProvider {
  const EmbedderProvider(
      {required this.context, required this.remoteControllerService});

  final DeviceSetupContext context;
  final RemoteControllerService remoteControllerService;

  factory EmbedderProvider.create(
    FlutterEmbedder embedder,
    DeviceSetupContext context,
    RemoteControllerService remoteControllerService,
  ) {
    switch (embedder) {
      case FlutterEmbedder.flutter:
        return FlutterLinuxEmbedderProvider(
          context: context,
          remoteControllerService: remoteControllerService,
        );
      case FlutterEmbedder.flutterPi:
        throw UnimplementedError('Flutter-pi embedder is not implemented yet');
    }
  }

  Future<String> provideEmbedderPath();
}
