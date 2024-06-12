import 'package:snapp_cli/service/setup_device/chain_handler/device_setup_handler.dart';

/// EmbedderProvider is an abstract class that provides the embedder which is responsible to execute the flutter app
///
/// The embedder can be the official Flutter Linux embedder
/// or a custom embedders like Flutter-pi or ivi-homescreen
abstract class EmbedderProvider {
  const EmbedderProvider({required this.context});

  final DeviceSetupContext context;

  Future<String> provideEmbedderPath();
}
