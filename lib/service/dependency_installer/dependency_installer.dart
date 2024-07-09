import 'package:snapp_cli/configs/embedder.dart';
import 'package:snapp_cli/flutter_sdk.dart';
import 'package:snapp_cli/service/dependency_installer/src/flutter_pi_dependency_installer.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';

abstract class DependencyInstaller {
  const DependencyInstaller({
    required this.flutterSdkManager,
    required this.remoteControllerService,
  });

  final FlutterSdkManager flutterSdkManager;
  final RemoteControllerService remoteControllerService;

  factory DependencyInstaller.create(
    FlutterEmbedder embedder, {
    required FlutterSdkManager flutterSdkManager,
    required RemoteControllerService remoteControllerService,
  }) {
    switch (embedder) {
      case FlutterEmbedder.flutter:
        return NoOpDependencyInstaller(
          flutterSdkManager: flutterSdkManager,
          remoteControllerService: remoteControllerService,
        );
      case FlutterEmbedder.flutterPi:
        return FlutterPiDependencyInstaller(
          flutterSdkManager: flutterSdkManager,
          remoteControllerService: remoteControllerService,
        );
      case FlutterEmbedder.iviHomescreen:
        return FlutterPiDependencyInstaller(
          flutterSdkManager: flutterSdkManager,
          remoteControllerService: remoteControllerService,
        );
    }
  }

  Future<bool> install() async {
    final isHostDependenciesInstalled = await installDependenciesOnHost();
    if (!isHostDependenciesInstalled) {
      return false;
    }

    final isRemoteDependenciesInstalled = await installDependenciesOnRemote();
    if (!isRemoteDependenciesInstalled) {
      return false;
    }

    return true;
  }

  /// Install host dependencies that is required to run the app on the remote device.
  Future<bool> installDependenciesOnHost();

  /// Install dependencies on the remote device.
  Future<bool> installDependenciesOnRemote();
}

class NoOpDependencyInstaller extends DependencyInstaller {
  const NoOpDependencyInstaller({
    required super.flutterSdkManager,
    required super.remoteControllerService,
  });

  @override
  Future<bool> installDependenciesOnHost() async {
    return true;
  }

  @override
  Future<bool> installDependenciesOnRemote() async {
    return true;
  }
}
