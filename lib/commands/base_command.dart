// ignore_for_file: implementation_imports

import 'package:args/args.dart';
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
}

extension ArgResultsExtension on ArgResults {
  /// Gets the parsed command-line option named [name] as `bool`.
  bool boolArg(String name) => this[name] == true;

  /// Gets the parsed command-line option named [name] as `String`.
  String? stringArg(String name) {
    final arg = this[name];
    if (arg == 'null' || arg == Null || (arg == null || arg.isEmpty)) {
      return null;
    }
    return arg;
  }

  /// Gets the parsed command-line option named [name] as `List<String>`.
  List<String?> stringsArg(String name) => this[name] as List<String>;
}
