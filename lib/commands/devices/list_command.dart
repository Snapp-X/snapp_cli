// ignore_for_file: implementation_imports

import 'package:snapp_cli/commands/base_command.dart';
import 'package:flutter_tools/src/base/process.dart';

/// List all custom devices added to the Flutter SDK with custom-devices command
/// it will utilize the `flutter custom-devices list` command to show the list
class ListCommand extends BaseSnappCommand {
  ListCommand({
    required super.flutterSdkManager,
  });

  @override
  final name = 'list';

  @override
  final description = 'List all custom devices added to the Flutter SDK';

  @override
  Future<int> run() async {
    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: logger,
    );

    await Future.delayed(Duration(seconds: 2));

    final result = await processRunner.run(
      ['flutter', 'custom-devices', 'list'],
      timeout: Duration(seconds: 10),
    );

    printSpaces();

    logger.printStatus(result.stdout);

    return result.exitCode;
  }
}
