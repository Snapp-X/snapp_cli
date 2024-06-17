import 'package:recase/recase.dart';
import 'package:snapp_cli/flutter_sdk.dart';
import 'package:snapp_cli/service/dependency_installer/dependency_installer.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';

class InstallDependencyProvider extends DeviceSetupStep {
  InstallDependencyProvider({
    required this.remoteControllerService,
    required this.flutterSdkManager,
  });

  final RemoteControllerService remoteControllerService;
  final FlutterSdkManager flutterSdkManager;

  @override
  Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
    logger.spaces();

    logger.info(
      '''
Installing required dependencies to run the app on the remote device.
Selected custom embedder: ${context.embedder?.name.paramCase}


''',
    );

    logger.spaces();

    final dependencyInstaller = DependencyInstaller.create(
      context.embedder!,
      flutterSdkManager: flutterSdkManager,
      remoteControllerService: remoteControllerService,
    );

    final isDependenciesInstalled = await dependencyInstaller.install();

    if (!isDependenciesInstalled) {
      logger.err(
          'Failed to install dependencies! for ${context.embedder?.name.paramCase} embedder.');
      throwToolExit(
          'Failed to install dependencies! for ${context.embedder?.name.paramCase} embedder.');
    }

    return context;
  }
}
