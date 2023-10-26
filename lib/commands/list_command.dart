// ignore_for_file: implementation_imports

import 'package:raspberry_device/commands/base_command.dart';
import 'package:raspberry_device/utils/flutter_sdk.dart';
import 'package:process_run/process_run.dart' as process_run;

/// List all custom devices added to the Flutter SDK with custom-devices command
/// it will utilize the `flutter custom-devices list` command to show the list
class ListCommand extends BaseCommand {
  ListCommand({required this.flutterSdkManager});

  final FlutterSdkManager flutterSdkManager;

  @override
  final name = 'list';

  @override
  final description = 'List all raspberries';

  @override
  Future<int> run() async {
    final isConfigAvailable =
        await flutterSdkManager.isCustomDevicesConfigAvailable();

    if (isConfigAvailable) {
      final result = await process_run.run('flutter custom-devices list');

      return result.first.exitCode;
    }

    return 0;
  }
}
