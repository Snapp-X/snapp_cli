// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:interact/interact.dart';
import 'package:snapp_debugger/commands/base_command.dart';
import 'package:snapp_debugger/host_runner/host_runner_platform.dart';
import 'package:snapp_debugger/utils/common.dart';
import 'package:snapp_debugger/utils/flutter_sdk.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
///
///
// TODO: add get platform for example: x64 or arm64
class AddCommand extends BaseDebuggerCommand {
  AddCommand({
    required this.flutterSdkManager,
    required super.customDevicesConfig,
    required super.logger,
    required Platform platform,
  }) : _platform = platform;

  final FlutterSdkManager flutterSdkManager;

  final Platform _platform;

  @override
  final name = 'add';

  @override
  final description = 'add a new device to custom devices';

  @override
  Future<int> run() async {
    /// create a HostPlatform instance based on the current platform
    /// with the help of this class we can make the commands platform specific
    /// for example, the ping command is different on windows and linux
    ///
    /// only supports windows, linux and macos
    ///
    final hostPlatform = HostRunnerPlatform.build(_platform);

    /// path to the icu data file on the host machine
    final hostIcuDataPath = flutterSdkManager.icuDataPath;

    /// path to the build artifacts on the remote machine
    const hostBuildClonePath = 'snapp_embedded';

    /// path to the icu data file on the remote machine
    const hostIcuDataClone = '$hostBuildClonePath/engine';

    printSpaces();

    final String id = Input(
      prompt:
          'Please enter the id you want to device to have. Must contain only alphanumeric or underscore characters. (example: pi)',
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

    final String label = Input(
      prompt:
          'Please enter the label of the device, which is a slightly more verbose name for the device. (example: Raspberry Pi Model 4B)',
      validator: (s) {
        if (s.trim().isNotEmpty) {
          return true;
        }
        throw ValidationError('Input is empty. Please try again.');
      },
    ).interact();

    printSpaces();

    final String targetStr = Input(
      prompt:
          'Please enter the IP-address of the device. (example: 192.168.1.101)',
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

    final String username = Input(
      prompt:
          'Please enter the username used for ssh-ing into the remote device. (example: pi)',
      defaultValue: 'no username',
    ).interact();

    printSpaces();

    final String remoteRunnerCommand = Input(
      prompt:
          'We need the exact path of your flutter command line tools on the remote device. '
          'We will use this path to run flutter commands on the remote device like "flutter build linux --debug".'
          'You can use which command to find it in your remote machine: "which flutter"'
          '*NOTE: if you added flutter to one of directories in \$PATH variables, you can just enter "flutter" here.'
          'example: /home/pi/sdk/flutter/bin/flutter',
      validator: (s) {
        if (_isValidPath(s)) {
          return true;
        }
        throw ValidationError('Invalid Path to flutter. Please try again.');
      },
    ).interact();

    // SSH expects IPv6 addresses to use the bracket syntax like URIs do too,
    // but the IPv6 the user enters is a raw IPv6 address, so we need to wrap it.
    final String sshTarget = (username.isNotEmpty ? '$username@' : '') +
        (ipv6 ? '[${targetIp.address}]' : targetStr);

    final String formattedLoopbackIp =
        ipv6 ? '[${loopbackIp.address}]' : loopbackIp.address;

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

    logger.printStatus(
      'Successfully added custom device to config file at "${customDevicesConfig.configPath}".',
    );
    return 0;
  }

  // ignore: unused_element
  bool _isValidHostname(String s) => hostnameRegex.hasMatch(s);

  bool _isValidPath(String s) => pathRegex.hasMatch(s);

  bool _isValidIpAddr(String s) => InternetAddress.tryParse(s) != null;

  void printSpaces([int n = 2]) {
    for (int i = 0; i < n; i++) {
      logger.printStatus(' ');
    }
  }

  bool _isDuplicatedDeviceId(String s) {
    return customDevicesConfig.devices.any((element) => element.id == s);
  }
}
