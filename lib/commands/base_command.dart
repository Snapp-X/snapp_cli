// ignore_for_file: implementation_imports

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';
import 'package:snapp_cli/utils/interact.dart';

export 'package:flutter_tools/src/base/common.dart';

abstract class BaseSnappCommand extends Command<int> {
  BaseSnappCommand({
    required this.flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        interaction = Interaction(logger: flutterSdkManager.logger);

  final FlutterSdkManager flutterSdkManager;
  final Interaction interaction;

  /// create a HostPlatform instance based on the current platform
  /// with the help of this class we can make the commands platform specific
  /// for example, the ping command is different on windows and linux
  ///
  /// only supports windows, linux and macos
  final HostRunnerPlatform hostPlatform;

  CustomDevicesConfig get customDevicesConfig =>
      flutterSdkManager.customDeviceConfig;

  Logger get logger => flutterSdkManager.logger;
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
