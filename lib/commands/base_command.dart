// ignore_for_file: implementation_imports

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';


abstract class BaseDebuggerCommand extends Command<int> {
  BaseDebuggerCommand({
    required this.customDevicesConfig,
    required this.logger,
  });

  final CustomDevicesConfig customDevicesConfig;
  final Logger logger;

  /// check if the command-line option named [name] was provided.
  bool wasProvided<T>(String name) =>
      argResults![name] == Null || argResults![name] is! T;

  /// Checks if the command-line option named [name] was parsed.
  bool wasParsed(String name) => argResults!.wasParsed(name);

  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => argResults![name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) {
    final arg = argResults![name] as String?;
    if (arg == 'null' || (arg == null || arg.isEmpty)) {
      return null;
    }
    return arg;
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String?> stringsArg(String name) => argResults![name] as List<String>;
}
