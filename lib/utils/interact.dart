// ignore_for_file: implementation_imports

import 'dart:io';

import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:snapp_cli/utils/custom_device.dart';

class Interaction {
  const Interaction({required this.logger});

  final Logger logger;

  (InternetAddress ip, String username) getDeviceInfoInteractively(
    CustomDevicesConfig customDevicesConfig,
    String message, {
    bool printSelectedDeviceInfo = false,
  }) {
    final deviceOptions = [
      'Existing device',
      'New device',
    ];

    logger.printStatus(message);

    logger.printSpaces();

    final deviceTypeIndex = Select(
      prompt: 'Device Type:',
      options: deviceOptions,
    ).interact();

    logger.printSpaces();

    final isNewDevice = deviceTypeIndex == 1;

    final (InternetAddress ip, String username) deviceInfo;

    if (isNewDevice) {
      logger.printSpaces();

      logger.printStatus("Please enter the device info:");
      deviceInfo = (readDeviceIp(), readDeviceUsername());
    } else {
      deviceInfo = selectDeviceIpAndUsername(customDevicesConfig);
    }

    if (printSelectedDeviceInfo) {
      logger.printStatus('''
Target Device info: 

Ip Address: ${deviceInfo.$1}
Username: ${deviceInfo.$2}

''');
    }

    return deviceInfo;
  }

  (InternetAddress ip, String username) selectDeviceIpAndUsername(
    CustomDevicesConfig customDevicesConfig,
  ) {
    if (customDevicesConfig.devices.isEmpty) {
      throwToolExit(
        '''
No devices found in config at "${customDevicesConfig.configPath}"

Before you can install flutter on a device, you need to add one first.
''',
      );
    }

    final devices = {
      for (var e in customDevicesConfig.devices) '${e.id} : ${e.label}': e
    };

    final selectedDevice = Select(
      prompt: 'Select a target device',
      options: devices.keys.toList(),
    ).interact();

    final deviceKey = devices.keys.elementAt(selectedDevice);

    final targetDevice = devices[deviceKey];

    if (targetDevice == null) {
      throwToolExit(
          'Couldn\'t find device with id "${targetDevice!.id}" in config at "${customDevicesConfig.configPath}"');
    }

    final deviceIp = targetDevice.tryFindDeviceIp;

    if (deviceIp == null) {
      throwToolExit(
        'Couldn\'t find device ip address in ping command for device with id "${targetDevice.id}" in config at "${customDevicesConfig.configPath}"',
      );
    }

    final username = targetDevice.deviceUsername;

    logger.printSpaces();

    return (InternetAddress.tryParse(deviceIp)!, username);
  }

  InternetAddress readDeviceIp({String? description, String? title}) {
    if (description != null) {
      logger.printStatus(description);
      logger.printSpaces();
    }

    final String deviceIp = Input(
      prompt: title ?? 'Device IP-address:',
      validator: (s) {
        if (s.isValidIpAddress) {
          return true;
        }
        throw ValidationError('Invalid IP-address. Please try again.');
      },
    ).interact();

    final ip = InternetAddress(deviceIp);

    logger.printSpaces();

    return ip;
  }

  String readDeviceUsername({String? description}) {
    if (description != null) {
      logger.printStatus(description);
      logger.printSpaces();
    }

    final String username = Input(
      prompt: 'Username:',
    ).interact();

    logger.printSpaces();

    return username;
  }

  String readDeviceId(
    CustomDevicesConfig customDevicesConfig, {
    String? description,
  }) {
    logger.printStatus(
      description ??
          'Please enter the id you want to device to have. Must contain only alphanumeric or underscore characters. (example: pi)',
    );

    final id = Input(
      prompt: 'Device Id:',
      validator: (s) {
        if (!RegExp(r'^\w+$').hasMatch(s.trim())) {
          throw ValidationError('Invalid input. Please try again.');
        } else if (customDevicesConfig.isDuplicatedDeviceId(s.trim())) {
          throw ValidationError('Device with this id already exists.');
        }
        return true;
      },
    ).interact().trim();

    logger.printSpaces();

    return id;
  }

  String readDeviceLabel({String? description}) {
    logger.printStatus(
      description ??
          'Please enter the label of the device, which is a slightly more verbose name for the device. (example: Raspberry Pi Model 4B)',
    );
    final label = Input(
      prompt: 'Device label:',
      validator: (s) {
        if (s.trim().isNotEmpty) {
          return true;
        }
        throw ValidationError('Input is empty. Please try again.');
      },
    ).interact();

    logger.printSpaces();

    return label;
  }

  Future<String> readFlutterManualPath({String? description}) async {
    logger.printStatus(
      description ??
          '''You can use which command to find it in your remote machine: "which flutter" 
*NOTE: if you added flutter to one of directories in \$PATH variables, you can just enter "flutter" here. 
(example: /home/pi/sdk/flutter/bin/flutter)''',
    );

    final manualFlutterPath = Input(
      prompt: 'Flutter path on device:',
      validator: (s) {
        if (s.isValidPath) {
          return true;
        }
        throw ValidationError('Invalid Path to flutter. Please try again.');
      },
    ).interact();

    /// check if [manualFlutterPath] is a valid file path
    if (!manualFlutterPath.isValidPath) {
      throwToolExit(
          'Invalid Path to flutter. Please make sure about flutter path on the remote machine and try again.');
    }

    return manualFlutterPath;
  }
}
