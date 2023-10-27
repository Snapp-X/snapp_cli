// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:snapp_debugger/commands/base_command.dart';
import 'package:snapp_debugger/utils/flutter_sdk.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class DeleteCommand extends BaseCommand {
  DeleteCommand({
    required FlutterSdkManager flutterSdkManager,
    required CustomDevicesConfig customDevicesConfig,
    required Logger logger,
    required Platform platform,
  })  : _customDevicesConfig = customDevicesConfig,
        _logger = logger {
    argParser.addOption(
      FlutterGlobalOptions.kDeviceIdOption,
      abbr: 'd',
      help: 'Target device id or name (prefixes allowed).',
    );
  }

  final CustomDevicesConfig _customDevicesConfig;
  final Logger _logger;

  @override
  final String description = 'Delete a custom device from the Flutter SDK';

  @override
  final String name = 'delete';

  @override
  FutureOr<int>? run() {
    if (argResults!.options.isEmpty) {
      usageException('Delete command requires a device id');
    }

    final deviceId = argResults![FlutterGlobalOptions.kDeviceIdOption];
    if (deviceId == Null || deviceId is! String) {
      usageException('Delete command requires a device id');
    }

    if (!_customDevicesConfig.contains(deviceId)) {
      throwToolExit(
          'Couldn\'t find device with id "$deviceId" in config at "${_customDevicesConfig.configPath}"');
    }

    _customDevicesConfig.remove(deviceId);
    _logger.printStatus(
        'Successfully removed device with id "$deviceId" from config at "${_customDevicesConfig.configPath}"');

    return 0;
  }
}
