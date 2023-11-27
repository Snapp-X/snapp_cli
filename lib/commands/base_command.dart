// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';

abstract class BaseSnappCommand extends Command<int> {
  BaseSnappCommand({
    required this.flutterSdkManager,
  });

  final FlutterSdkManager flutterSdkManager;

  CustomDevicesConfig get customDevicesConfig =>
      flutterSdkManager.customDeviceConfig;
  Logger get logger => flutterSdkManager.logger;

  (InternetAddress ip, String username) getRemoteIpAndUsername(
      {required String message}) {
    logger.printSpaces();

    logger.printStatus(message);

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
