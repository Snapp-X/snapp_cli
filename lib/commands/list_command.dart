// ignore_for_file: implementation_imports

import 'package:raspberry_device/commands/base_command.dart';
import 'package:raspberry_device/utils/flutter_sdk.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:process_run/process_run.dart' as process_run;

/// List all custom devices added to the Flutter SDK with custom-devices command
/// it will utilize the `flutter custom-devices list` command to show the list
class ListCommand extends BaseCommand {
  final sdkManager = FlutterSdkManager();

  @override
  final name = 'list';

  @override
  final description = 'List all raspberries';

  @override
  Future<int> run() async {
    await sdkManager.initialize();

    await runInContext(() async {
      final isConfigAvailable =
          await sdkManager.isCustomDevicesConfigAvailable();

      if (isConfigAvailable) {
        final result = await process_run.run('flutter custom-devices list');

        return result.first.exitCode;
      }
    });

    return 0;
  }
}
