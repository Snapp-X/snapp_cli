// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:mason_logger/mason_logger.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/service/interaction/actor.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:snapp_cli/utils/custom_device.dart';

final interaction = InteractionService._();

class InteractionService {
  InteractionService._();

  final Actor actor = Actor.cli(logger: logger);

  bool confirm(
    String? message, {
    bool? defaultValue,
  }) =>
      actor.confirm(
        prompt: message ?? 'Are you sure?',
        defaultValue: defaultValue,
      );

  Progress progress(String message) => logger.loggerInstance.progress(message);

  Spinner spinner({
    required String inProgressMessage,
    String doneMessage = 'Done!',
    String failedMessage = 'Failed!',
  }) =>
      Spinner(
        inProgressMessage: inProgressMessage,
        doneMessage: doneMessage,
        failedMessage: failedMessage,
      );

  String input(String? message, {Object? defaultValue}) => actor.input(
        prompt: message ?? 'Input:',
        defaultValue: defaultValue,
      );

  String inputWithValidation(
    String? message, {
    required String? Function(String) validator,
    Object? defaultValue,
  }) =>
      actor.inputWithValidation(
        prompt: message ?? 'Input:',
        validator: validator,
        defaultValue: defaultValue,
      );

  String select(
    String? message, {
    required List<String> options,
  }) =>
      actor.select(
        message ?? 'Select an option:',
        options: options,
      );

  int selectIndex(
    String? message, {
    required List<String> options,
  }) =>
      actor.selectIndex(
        message ?? 'Select an option:',
        options: options,
      );

  (InternetAddress ip, String username) getDeviceInfoInteractively(
    CustomDevicesConfig customDevicesConfig,
    String message, {
    bool printSelectedDeviceInfo = false,
  }) {
    final deviceOptions = [
      'Existing device',
      'New device',
    ];

    logger.info(message);

    logger.spaces();

    final deviceTypeIndex = selectIndex(
      'Device Type:',
      options: deviceOptions,
    );

    logger.spaces();

    final isNewDevice = deviceTypeIndex == 1;

    final (InternetAddress ip, String username) deviceInfo;

    if (isNewDevice) {
      logger.spaces();

      logger.info("Please enter the device info:");
      deviceInfo = (readDeviceIp(), readDeviceUsername());
    } else {
      final selectedDevice = selectDevice(customDevicesConfig);

      deviceInfo = (
        InternetAddress.tryParse(selectedDevice.deviceIp)!,
        selectedDevice.deviceUsername
      );
    }

    if (printSelectedDeviceInfo) {
      logger.info('''
Target Device info: 

Ip Address: ${deviceInfo.$1}
Username: ${deviceInfo.$2}

''');
    }

    return deviceInfo;
  }

  CustomDeviceConfig selectDevice(
    CustomDevicesConfig customDevicesConfig, {
    String? title,
    String? description,
    String? errorDescription,
  }) {
    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

${errorDescription ?? 'Before you can select a device, you need to add one first.'}
''',
      );
    }

    if (description != null) {
      logger.info(description);
      logger.spaces();
    }

    final devices = {
      for (var e in customDevicesConfig.devices) '${e.id} : ${e.label}': e
    };

    final selectedTarget = selectIndex(
      title ?? 'Select a target device',
      options: devices.keys.toList(),
    );

    final deviceKey = devices.keys.elementAt(selectedTarget);

    final selectedDevice = devices[deviceKey];

    if (selectedDevice == null) {
      throwToolExit(
          'Couldn\'t find device with id "${selectedDevice!.id}" in config at "${customDevicesConfig.configPath}"');
    }

    return selectedDevice;
  }

  InternetAddress readDeviceIp({String? description, String? title}) {
    if (description != null) {
      logger.info(description);
      logger.spaces();
    }

    final String deviceIp = inputWithValidation(
      title ?? 'Device IP-address:',
      validator: (s) {
        if (s.isValidIpAddress) {
          return null;
        }
        return 'Invalid IP-address. Please try again.';
      },
    );

    final ip = InternetAddress(deviceIp);

    logger.spaces();

    return ip;
  }

  String readDeviceUsername({String? description}) {
    if (description != null) {
      logger.info(description);
      logger.spaces();
    }

    final String username = input('Username:');

    logger.spaces();

    return username;
  }

  String readDeviceId(
    CustomDevicesConfig customDevicesConfig, {
    String? description,
  }) {
    logger.info(
      description ??
          'Please enter the id you want to device to have. Must contain only alphanumeric or underscore characters. (example: pi)',
    );

    final id = inputWithValidation(
      'Device Id:',
      validator: (s) {
        if (!RegExp(r'^\w+$').hasMatch(s.trim())) {
          return 'Invalid input. Please try again.';
        } else if (customDevicesConfig.isDuplicatedDeviceId(s.trim())) {
          return 'Device with this id already exists.';
        }
        return null;
      },
    ).trim();

    logger.spaces();

    return id;
  }

  String readDeviceLabel({String? description}) {
    logger.info(
      description ??
          'Please enter the label of the device, which is a slightly more verbose name for the device. (example: Raspberry Pi Model 4B)',
    );
    final label = inputWithValidation(
      'Device label:',
      validator: (s) {
        if (s.trim().isNotEmpty) {
          return null;
        }
        return 'Input is empty. Please try again.';
      },
    );

    logger.spaces();

    return label;
  }

  Future<String> readToolManualPath({
    required String toolName,
    String? examplePath,
    String? description,
  }) async {
    logger.info(
      description ??
          '''You can use which command to find it in your remote machine: "which $toolName" 
*NOTE: if you added $toolName to one of directories in \$PATH variables, you can just enter "$toolName" here. 
${examplePath == null ? '' : '(example: $examplePath)'}''',
    );

    final manualEnteredPath = inputWithValidation(
      '$toolName path on device:',
      validator: (s) {
        if (s.isValidPath) {
          return null;
        }
        return 'Invalid Path to $toolName. Please try again.';
      },
    );

    /// check if [manualEnteredPath] is a valid file path
    if (!manualEnteredPath.isValidPath) {
      throwToolExit(
          'Invalid Path to $toolName. Please make sure about $toolName path on the remote machine and try again.');
    }

    return manualEnteredPath;
  }

  Future<String> readFlutterManualPath() => readToolManualPath(
        toolName: 'flutter',
        examplePath: '/usr/local/bin/flutter',
      );
}

class Spinner {
  Spinner({
    required this.inProgressMessage,
    this.doneMessage = 'Done!',
    this.failedMessage = 'Failed!',
  });

  final String inProgressMessage;
  final String doneMessage;
  final String failedMessage;

  Progress? progress;

  void start() {
    if (progress != null) {
      throwToolExit('Spinner already started');
    }

    progress = interaction.progress(inProgressMessage);
  }

  void done() {
    progress?.complete(doneMessage);
  }

  void failed() {
    progress?.fail(failedMessage);
  }
}
