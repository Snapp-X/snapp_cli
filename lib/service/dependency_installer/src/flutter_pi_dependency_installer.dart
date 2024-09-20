import 'package:snapp_cli/service/dependency_installer/dependency_installer.dart';

// ignore: implementation_imports
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/service/interaction/interaction_service.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/utils/package.dart';
import 'package:snapp_cli/utils/process.dart';

export 'package:flutter_tools/src/base/common.dart';
export 'package:snapp_cli/service/logger_service.dart';
export 'package:snapp_cli/service/interaction/interaction_service.dart';

class FlutterPiDependencyInstaller extends DependencyInstaller {
  const FlutterPiDependencyInstaller({
    required super.flutterSdkManager,
    required super.remoteControllerService,
  });

  @override
  Future<bool> installDependenciesOnHost() {
    return _installFlutterPiTool();
  }

  @override
  Future<bool> installDependenciesOnRemote() async => true;

  Future<bool> _installFlutterPiTool() async {
    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: flutterSdkManager.logger,
    );

    final PackageUtils packageUtils = PackageUtils(processRunner);

    final isFlutterPiToolsAlreadyInstalled =
        await packageUtils.isPackageInstalledGlobally('flutterpi_tool');

    final result = await processRunner.runCommand(
      ['dart', 'pub', 'global', 'activate', 'flutterpi_tool'],
      parseResult: (result) => result,
      timeout: isFlutterPiToolsAlreadyInstalled
          ? const Duration(seconds: 10)
          : const Duration(seconds: 15),
      logger: logger,
      spinner: interaction.spinner(
        inProgressMessage: 'Installing flutterpi_tool...',
        doneMessage: 'flutterpi_tool installed successfully!',
        failedMessage: 'Failed to install flutterpi_tool!',
      ),
    );

    logger.spaces();

    if (result == null) return isFlutterPiToolsAlreadyInstalled;

    logger.info(result.stdout);
    logger.detail(result.stderr);

    return result.exitCode == 0;
  }
}
