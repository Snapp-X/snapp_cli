// ignore_for_file: implementation_imports

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';

abstract class BaseSnappCommand extends Command<int> {
  BaseSnappCommand({
    required this.flutterSdkManager,
  });

  final FlutterSdkManager flutterSdkManager;

  CustomDevicesConfig get customDevicesConfig =>
      flutterSdkManager.customDeviceConfig;
  Logger get logger => flutterSdkManager.logger;

  void printSpaces([int n = 2]) {
    for (int i = 0; i < n; i++) {
      logger.printStatus(' ');
    }
  }
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
