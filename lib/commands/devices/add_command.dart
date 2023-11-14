// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:math';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/configs/predefined_devices.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:flutter_tools/src/base/common.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
///
///
// TODO: add get platform for example: x64 or arm64
class AddCommand extends BaseSnappCommand {
  AddCommand({
    required super.flutterSdkManager,
    required Platform platform,
  }) : hostPlatform = HostRunnerPlatform.build(platform);

  /// create a HostPlatform instance based on the current platform
  /// with the help of this class we can make the commands platform specific
  /// for example, the ping command is different on windows and linux
  ///
  /// only supports windows, linux and macos
  final HostRunnerPlatform hostPlatform;

  @override
  final name = 'add';

  @override
  final description = 'add a new device to custom devices';

  @override
  Future<int> run() async {
    printSpaces();

    final addCommandOptions = [
      'Express (recommended)',
      'Custom',
    ];

    final commandIndex = Select(
      prompt: 'Please select the type of device you want to add.',
      options: addCommandOptions,
    ).interact();

    if (commandIndex == 0) {
      return _addPredefinedDevice();
    }

    return _addCustomDevice();
  }

  Future<int> _addPredefinedDevice() async {
    printSpaces();

    final selectedPredefinedDevice = Select(
      prompt: 'Select your device',
      options: predefinedDevices.keys.toList(),
    ).interact();

    final deviceKey =
        predefinedDevices.keys.elementAt(selectedPredefinedDevice);

    var predefinedDeviceConfig = predefinedDevices[deviceKey];

    if (predefinedDeviceConfig == null) {
      throwToolExit(
          'Something went wrong while trying to add predefined $deviceKey device.');
    }

    /// check if the device id already exists in the config file
    /// update the id if it
    if (_isDuplicatedDeviceId(predefinedDeviceConfig.id)) {
      predefinedDeviceConfig = predefinedDeviceConfig.copyWith(
        id: _suggestIdForDuplicatedDeviceId(predefinedDeviceConfig.id),
      );
    }

    return _addCustomDevice(predefinedConfig: predefinedDeviceConfig);
  }

  Future<int> _addCustomDevice({
    CustomDeviceConfig? predefinedConfig,
  }) async {
    /// path to the icu data file on the host machine
    final hostIcuDataPath = flutterSdkManager.icuDataPath;

    /// path to the build artifacts on the remote machine
    const hostBuildClonePath = 'snapp_embedded';

    /// path to the icu data file on the remote machine
    const hostIcuDataClone = '$hostBuildClonePath/engine';

    printSpaces();

    String id = predefinedConfig?.id ?? '';

    if (id.isEmpty) {
      logger.printStatus(
        'Please enter the id you want to device to have. Must contain only alphanumeric or underscore characters. (example: pi)',
      );

      id = Input(
        prompt: 'Device Id:',
        validator: (s) {
          if (!RegExp(r'^\w+$').hasMatch(s.trim())) {
            throw ValidationError('Invalid input. Please try again.');
          } else if (_isDuplicatedDeviceId(s.trim())) {
            throw ValidationError('Device with this id already exists.');
          }
          return true;
        },
      ).interact().trim();

      printSpaces();
    }

    String label = predefinedConfig?.label ?? '';

    if (label.isEmpty) {
      logger.printStatus(
        'Please enter the label of the device, which is a slightly more verbose name for the device. (example: Raspberry Pi Model 4B)',
      );
      label = Input(
        prompt: 'Device label:',
        validator: (s) {
          if (s.trim().isNotEmpty) {
            return true;
          }
          throw ValidationError('Input is empty. Please try again.');
        },
      ).interact();

      printSpaces();
    }

    logger.printStatus(
      'Please enter the IP-address of the device. (example: 192.168.1.101)',
    );

    final String targetStr = Input(
      prompt: 'Device IP-address:',
      validator: (s) {
        if (_isValidIpAddr(s)) {
          return true;
        }
        throw ValidationError('Invalid IP-address. Please try again.');
      },
    ).interact();

    final InternetAddress? targetIp = InternetAddress.tryParse(targetStr);
    final bool useIp = targetIp != null;
    final bool ipv6 = useIp && targetIp.type == InternetAddressType.IPv6;
    final InternetAddress loopbackIp =
        ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;

    printSpaces();

    logger.printStatus(
      'Please enter the username used for ssh-ing into the remote device. (example: pi)',
    );

    final String username = Input(
      prompt: 'Device Username:',
      defaultValue: 'no username',
    ).interact();

    // SSH expects IPv6 addresses to use the bracket syntax like URIs do too,
    // but the IPv6 the user enters is a raw IPv6 address, so we need to wrap it.
    final String sshTarget = (username.isNotEmpty ? '$username@' : '') +
        (ipv6 ? '[${targetIp.address}]' : targetStr);

    final String formattedLoopbackIp =
        ipv6 ? '[${loopbackIp.address}]' : loopbackIp.address;

    printSpaces();

    final isDeviceReachable = await _tryPingDevice(targetStr, ipv6);

    if (!isDeviceReachable) {
      logger.printStatus(
        'Could not reach the device with the given IP-address.',
      );

      final continueWithoutPing = Confirm(
        prompt: 'Do you want to continue anyway?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      if (!continueWithoutPing) {
        printSpaces();
        logger.printStatus('Check your device IP-address and try again.');
        return 1;
      }
    }

    printSpaces();

    logger.printStatus(
      'We need the exact path of your flutter command line tools on the remote device. '
      'We will use this path to run flutter commands on the remote device like "flutter build linux --debug". \n',
    );

    String remoteRunnerCommand = '';

    if (isDeviceReachable) {
      final possibleFlutterPath = await _findFlutterPath(sshTarget, ipv6);

      remoteRunnerCommand = possibleFlutterPath ?? '';
    }

    if (remoteRunnerCommand.isEmpty) {
      logger.printStatus(
        'Could not find flutter in the remote machine automatically. \n\n'
        'You need to provide it manually.'
        'You can use which command to find it in your remote machine: "which flutter" \n'
        '*NOTE: if you added flutter to one of directories in \$PATH variables, you can just enter "flutter" here. \n'
        '(example: /home/pi/sdk/flutter/bin/flutter)',
      );

      remoteRunnerCommand = Input(
        prompt: 'Flutter path on device:',
        validator: (s) {
          if (_isValidPath(s)) {
            return true;
          }
          throw ValidationError('Invalid Path to flutter. Please try again.');
        },
      ).interact();
    }

    CustomDeviceConfig config = CustomDeviceConfig(
      id: id,
      label: label,
      sdkNameAndVersion: label,
      enabled: true,

      // host-platform specific, filled out later
      pingCommand: hostPlatform.pingCommand(ipv6: ipv6, pingTarget: targetStr),
      pingSuccessRegex: hostPlatform.pingSuccessRegex,
      postBuildCommand: const <String>[],

      // just install to /tmp/${appName} by default
      // returns the command runner for the current platform
      // for example:
      // on windows it returns "powershell -c"
      // on linux and macOS it returns "bash -c"
      installCommand: hostPlatform.commandRunner(
        <String>[
          // create the necessary directories in the remote machine
          hostPlatform
              .sshCommand(
                ipv6: ipv6,
                sshTarget: sshTarget,
                command: 'mkdir -p /tmp/\${appName}/$hostIcuDataClone',
              )
              .asString,

          // copy the current project files from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: '${hostPlatform.currentSourcePath}*',
                dest: '$sshTarget:/tmp/\${appName}',
              )
              .asString,

          // copy the build artifacts from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: r'${localPath}',
                dest: '$sshTarget:/tmp/\${appName}/$hostBuildClonePath',
              )
              .asString,

          // copy the icu data file from host to the remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: hostIcuDataPath,
                dest: '$sshTarget:/tmp/\${appName}/$hostIcuDataClone',
                lastCommand: true,
              )
              .asString,
        ],
      ),
      // just uninstall app by removing the /tmp/${appName} directory on the remote
      uninstallCommand: hostPlatform.sshCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        command: r'rm -rf "/tmp/${appName}"',
        lastCommand: true,
      ),

      // run the app on the remote
      runDebugCommand: hostPlatform.sshMultiCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        commands: <String>[
          'cd /tmp/\${appName} ;',
          '$remoteRunnerCommand build linux --debug ;',
          // remove remote build artifacts
          'rm -rf "/tmp/\${appName}/build/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets/*" ;',
          'rm -rf "/tmp/\${appName}/build/linux/arm64/debug/bundle/data/icudtl.dat" ;',
          // and replace them by host build artifacts
          'cp /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/flutter_assets ;',
          'cp /tmp/\${appName}/$hostBuildClonePath/flutter_assets/*  /tmp/\${appName}/build/linux/arm64/debug/bundle/data/flutter_assets ;',
          'cp /tmp/\${appName}/$hostIcuDataClone/icudtl.dat  /tmp/\${appName}/build/linux/arm64/debug/bundle/data ;',
          // finally run the app
          r'DISPLAY=:0 /tmp/\${appName}/build/linux/arm64/debug/bundle/\${appName} ;'
        ],
      ),
      forwardPortCommand: <String>[
        'ssh',
        '-o',
        'BatchMode=yes',
        '-o',
        'ExitOnForwardFailure=yes',
        if (ipv6) '-6',
        '-L',
        '$formattedLoopbackIp:\${hostPort}:$formattedLoopbackIp:\${devicePort}',
        sshTarget,
        "echo 'Port forwarding success'; read",
      ],
      forwardPortSuccessRegex: RegExp('Port forwarding success'),
      screenshotCommand: null,
    );

    customDevicesConfig.add(config);

    printSpaces();

    logger.printStatus(
      '✔️ Successfully added custom device to config file at "${customDevicesConfig.configPath}". ✔️',
    );

    printSpaces();

    return 0;
  }

  // ignore: unused_element
  bool _isValidHostname(String s) => hostnameRegex.hasMatch(s);

  bool _isValidPath(String s) => pathRegex.hasMatch(s);

  bool _isValidIpAddr(String s) => InternetAddress.tryParse(s) != null;

  bool _isDuplicatedDeviceId(String s) {
    return customDevicesConfig.devices.any((element) => element.id == s);
  }

  /// returns new device id by adding a number to the end of it
  ///
  /// for example: if the id is "pi-4" and this id already exists
  /// then we update the id to "pi-4-1" and check again
  /// if the new id already exists, then we update it to "pi-4-2" and so on
  String _suggestIdForDuplicatedDeviceId(String s) {
    int i = 1;

    while (_isDuplicatedDeviceId('$s-$i')) {
      i++;
    }

    return '$s-$i';
  }

  Future<bool> _tryPingDevice(String pingTarget, bool ipv6) async {
    final spinner = Spinner(
      icon: '✔️',
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'pinging device completed.'
          : 'pinging device to check if it is reachable.',
    ).interact();

    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: logger,
    );

    await Future.delayed(Duration(seconds: 2));
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.pingCommand(ipv6: ipv6, pingTarget: pingTarget),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find flutter. \n $e \n $s',
      );

      return false;
    } finally {
      spinner.done();

      printSpaces();
    }

    logger.printTrace('Ping Command ExitCode: ${result.exitCode}');
    logger.printTrace('Ping Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('Ping Command Stderr: ${result.stderr}');

    printSpaces();

    if (result.exitCode != 0) {
      return false;
    }

    // If the user doesn't configure a ping success regex, any ping with exitCode zero
    // is good enough. Otherwise we check if either stdout or stderr have a match of
    // the pingSuccessRegex.
    final RegExp? pingSuccessRegex = hostPlatform.pingSuccessRegex;

    return pingSuccessRegex == null ||
        pingSuccessRegex.hasMatch(result.stdout) ||
        pingSuccessRegex.hasMatch(result.stderr);
  }

  /// finds flutter in the host using ssh connection
  /// returns the path of flutter if found it
  /// otherwise returns null
  Future<String?> _findFlutterPath(String sshTarget, bool ipv6) async {
    final spinner = Spinner(
      icon: '✔️',
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'finding flutter path completed'
          : 'finding flutter path on remote device.',
    ).interact();

    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: logger,
    );

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ipv6,
          sshTarget: sshTarget,
          command:
              'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find flutter. \n $e \n $s',
      );

      return null;
    } finally {
      spinner.done();

      printSpaces();
    }

    logger.printTrace('Find Flutter ExitCode: ${result.exitCode}');
    logger.printTrace('Find Flutter Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find Flutter Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger
          .printStatus('We found flutter in "$output" in the remote machine. ');
      final flutterSdkPathConfirmation = Confirm(
        prompt: 'Do you want to use this path?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      return flutterSdkPathConfirmation ? output : null;
    } else {
      final outputLines = output
          .split('\n')
          .map((e) => e.trim())
          .toList()
          .sublist(0, min(2, outputLinesLength));

      logger.printStatus(
          'We found multiple flutter paths in the remote machine. ');
      final flutterSdkPathSelection = Select(
        prompt: 'Please select the path of flutter you want to use.',
        options: outputLines,
      ).interact();

      return outputLines[flutterSdkPathSelection];
    }
  }
}
