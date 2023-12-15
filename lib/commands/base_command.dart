// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';

export 'package:flutter_tools/src/base/common.dart';

abstract class BaseSnappCommand extends Command<int> {
  BaseSnappCommand({
    required this.flutterSdkManager,
  }) : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform);

  final FlutterSdkManager flutterSdkManager;

  /// create a HostPlatform instance based on the current platform
  /// with the help of this class we can make the commands platform specific
  /// for example, the ping command is different on windows and linux
  ///
  /// only supports windows, linux and macos
  final HostRunnerPlatform hostPlatform;

  CustomDevicesConfig get customDevicesConfig =>
      flutterSdkManager.customDeviceConfig;

  Logger get logger => flutterSdkManager.logger;

  (InternetAddress ip, String username) getRemoteIpAndUsername({
    required String message,
    String? getIpDescription,
    String? getUsernameDescription,
  }) {
    logger.printSpaces();

    logger.printStatus(message);

    if (getIpDescription != null) {
      logger.printStatus(getIpDescription);
      logger.printSpaces();
    }

    final String deviceIp = Input(
      prompt: 'Device IP-address:',
      validator: (s) {
        if (s.isValidIpAddress) {
          return true;
        }
        throw ValidationError('Invalid IP-address. Please try again.');
      },
    ).interact();

    final ip = InternetAddress(deviceIp);

    logger.printSpaces();

    if (getUsernameDescription != null) {
      logger.printStatus(getUsernameDescription);
      logger.printSpaces();
    }

    final String username = Input(
      prompt: 'Username:',
    ).interact();

    logger.printSpaces();

    return (ip, username);
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
