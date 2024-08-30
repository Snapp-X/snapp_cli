import 'package:snapp_cli/service/dependency_installer/dependency_installer.dart';

// ignore: implementation_imports
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/service/interaction/interaction_service.dart';
import 'package:snapp_cli/service/logger_service.dart';
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

  // TODO(payam): add try-catch block to catch exceptions
  Future<bool> _installFlutterPiTool() async {
    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: flutterSdkManager.logger,
    );

    final result = await processRunner.runCommand(
      ['flutter', 'pub', 'global', 'activate', 'flutterpi_tool'],
      parseResult: (result) => result,
      spinner: interaction.spinner(
        inProgressMessage: 'Installing flutterpi_tool...',
        doneMessage: 'flutterpi_tool installed successfully!',
        failedMessage: 'Failed to install flutterpi_tool!',
      ),
    );

    logger.spaces();

    if (result == null) {
      return false;
    }

    logger.info(result.stdout);
    logger.detail(result.stderr);

    return result.exitCode == 0;
  }
}
