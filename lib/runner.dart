import 'package:args/command_runner.dart';
import 'package:raspberry_device/commands/list_command.dart';

class Runner extends CommandRunner<int> {
  Runner()
      : super(
          'raspberry_device',
          'A command-line tool to add your rasp',
        ) {
  }
}
