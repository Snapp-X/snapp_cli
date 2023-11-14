// ignore_for_file: implementation_imports

import 'package:snapp_cli/commands/base_command.dart';
import 'package:process_run/process_run.dart' as process_run;

/// List all custom devices added to the Flutter SDK with custom-devices command
/// it will utilize the `flutter custom-devices list` command to show the list
class ListCommand extends BaseSnappCommand {
  ListCommand({
    required super.customDevicesConfig,
    required super.logger,
  });

  @override
  final name = 'list';

  @override
  final description = 'List all custom devices added to the Flutter SDK';

  @override
  Future<int> run() async {
    final result = await process_run.run('flutter custom-devices list');

    return result.first.exitCode;
  }
}
