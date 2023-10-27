// ignore_for_file: implementation_imports

import 'dart:async';
import 'package:async/async.dart';

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:snapp_debugger/commands/base_command.dart';
import 'package:snapp_debugger/host_runner/host_runner_platform.dart';
import 'package:snapp_debugger/utils/common.dart';
import 'package:snapp_debugger/utils/flutter_sdk.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class AddCommand extends BaseCommand {
  AddCommand({
    required this.flutterSdkManager,
    required CustomDevicesConfig customDevicesConfig,
    required Terminal terminal,
    required Platform platform,
    required this.logger,
  })  : _customDevicesConfig = customDevicesConfig,
        _terminal = terminal,
        _platform = platform;

  final FlutterSdkManager flutterSdkManager;

  final CustomDevicesConfig _customDevicesConfig;
  final Terminal _terminal;
  final Platform _platform;
  final Logger logger;

  late StreamQueue<String> inputs;

  @override
  final name = 'add';

  @override
  final description = 'add a new device to custom devices';

  @override
  Future<int> run() async {
    final isConfigAvailable =
        await flutterSdkManager.isCustomDevicesConfigAvailable();

    if (isConfigAvailable) {
      /// create a HostPlatform instance based on the current platform
      /// with the help of this class we can make the commands platform specific
      /// for example, the ping command is different on windows and linux
      ///
      /// only supports windows, linux and macos
      ///
      final hostPlatform = HostRunnerPlatform.build(_platform);

      // Listen to the keystrokes stream as late as possible, since it's a
      // single-subscription stream apparently.
      // Also, _terminal.keystrokes can be closed unexpectedly, which will result
      // in StreamQueue.next throwing a StateError when make the StreamQueue listen
      // to that directly.
      // This caused errors when using Ctrl+C to terminate while the
      // custom-devices add command is waiting for user input.
      // So instead, we add the keystrokes stream events to a new single-subscription
      // stream and listen to that instead.
      final StreamController<String> nonClosingKeystrokes =
          StreamController<String>();

      final StreamSubscription<String> keystrokesSubscription = _terminal
          .keystrokes
          .listen((String s) => nonClosingKeystrokes.add(s.trim()),
              cancelOnError: true);

      inputs = StreamQueue<String>(nonClosingKeystrokes.stream);

      /// path to the icu data file on the host machine
      final hostIcuDataPath = flutterSdkManager.icuDataPath;

      /// path to the build artifacts on the remote machine
      const hostBuildClonePath = 'snapp_embedded';

      /// path to the icu data file on the remote machine
      const hostIcuDataClone = '$hostBuildClonePath/engine';

      final String id = (await askForString(
        'id',
        description:
            'Please enter the id you want to device to have. Must contain only '
            'alphanumeric or underscore characters.',
        example: 'pi',
        validator: (String s) async => RegExp(r'^\w+$').hasMatch(s),
      ))!;

      final String label = (await askForString(
        'label',
        description:
            'Please enter the label of the device, which is a slightly more verbose '
            'name for the device.',
        example: 'Raspberry Pi',
      ))!;

      final String sdkNameAndVersion = (await askForString(
        'SDK name and version',
        example: 'Raspberry Pi 4 Model B+',
      ))!;

      final bool enabled = await askForBool(
        'enabled',
        description: 'Should the device be enabled?',
      );

      // TODO: add get platform for example x64 or arm64

      final String targetStr = (await askForString('target',
          description:
              'Please enter the hostname or IPv4/v6 address of the device.',
          example: 'raspberrypi',
          validator: (String s) async =>
              _isValidHostname(s) || _isValidIpAddr(s)))!;

      final InternetAddress? targetIp = InternetAddress.tryParse(targetStr);
      final bool useIp = targetIp != null;
      final bool ipv6 = useIp && targetIp.type == InternetAddressType.IPv6;
      final InternetAddress loopbackIp =
          ipv6 ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;

      final String username = (await askForString(
        'username',
        description:
            'Please enter the username used for ssh-ing into the remote device.',
        example: 'pi',
        defaultsTo: 'no username',
      ))!;

      final String remoteRunnerCommand = (await askForString(
        'flutter executable path',
        description:
            'We need the exact path of your flutter command line tools on the remote device. \n'
            'We will use this path to run flutter commands on the remote device like "flutter build linux --debug".\n'
            'Example: /home/pi/sdk/flutter/bin/flutter\n'
            '*NOTE: if you added flutter to one of directories in \$PATH variables, you can just enter "flutter" here.\n',
        example: r'/home/pi/sdk/flutter/bin/flutter',
        validator: (String s) async => _isValidPath(s),
      ))!;

      final bool usePortForwarding = await askForBool(
        'use port forwarding',
        description: 'Should the device use port forwarding? '
            'Using port forwarding is the default because it works in all cases, however if your '
            'remote device has a static IP address and you have a way of '
            'specifying the "--vm-service-host=<ip>" engine option, you might prefer '
            'not using port forwarding.',
      );

      final String screenshotCommand = (await askForString(
        'screenshot command',
        description:
            'Enter the command executed on the remote device for taking a screenshot.',
        example:
            r"fbgrab /tmp/screenshot.png && cat /tmp/screenshot.png | base64 | tr -d ' \n\t'",
        defaultsTo: 'no screenshotting support',
      ))!;

      // SSH expects IPv6 addresses to use the bracket syntax like URIs do too,
      // but the IPv6 the user enters is a raw IPv6 address, so we need to wrap it.
      final String sshTarget = (username.isNotEmpty ? '$username@' : '') +
          (ipv6 ? '[${targetIp.address}]' : targetStr);

      final String formattedLoopbackIp =
          ipv6 ? '[${loopbackIp.address}]' : loopbackIp.address;

      CustomDeviceConfig config = CustomDeviceConfig(
        id: id,
        label: label,
        sdkNameAndVersion: sdkNameAndVersion,
        enabled: enabled,

        // host-platform specific, filled out later
        pingCommand:
            hostPlatform.pingCommand(ipv6: ipv6, pingTarget: targetStr),
        pingSuccessRegex: hostPlatform.pingSuccessRegex,
        postBuildCommand: const <String>[],

        // just install to /tmp/${appName} by default
        installCommand: <String>[
          // returns the command runner for the current platform
          // for example:
          // on windows it returns "powershell -c"
          // on linux and macOS it returns "bash -c"
          ...hostPlatform.terminalCommandRunner,

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
            '$remoteRunnerCommand linux --debug ;',
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

        forwardPortCommand: usePortForwarding
            ? <String>[
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
              ]
            : null,
        forwardPortSuccessRegex:
            usePortForwarding ? RegExp('Port forwarding success') : null,
        screenshotCommand: screenshotCommand.isNotEmpty
            ? <String>[
                'ssh',
                '-o',
                'BatchMode=yes',
                if (ipv6) '-6',
                sshTarget,
                screenshotCommand,
              ]
            : null,
      );

      unawaited(keystrokesSubscription.cancel());
      unawaited(nonClosingKeystrokes.close());

      _customDevicesConfig.add(config);

      logger.printStatus(
        'Successfully added custom device to config file at "${_customDevicesConfig.configPath}".',
      );
      return 0;
    }

    return 1;
  }

  bool _isValidHostname(String s) => hostnameRegex.hasMatch(s);

  bool _isValidPath(String s) => pathRegex.hasMatch(s);

  bool _isValidIpAddr(String s) => InternetAddress.tryParse(s) != null;

  /// Ask the user to input a string.
  Future<String?> askForString(
    String name, {
    String? description,
    String? example,
    String? defaultsTo,
    Future<bool> Function(String)? validator,
  }) async {
    String msg = description ?? name;

    final String exampleOrDefault = <String>[
      if (example != null) 'example: $example',
      if (defaultsTo != null) 'empty for $defaultsTo',
    ].join(', ');

    if (exampleOrDefault.isNotEmpty) {
      msg += ' ($exampleOrDefault)';
    }

    logger.printStatus('\n$msg');
    while (true) {
      if (!await inputs.hasNext) {
        return null;
      }

      final String input = await inputs.next;

      if (validator != null && !await validator(input)) {
        logger.printStatus('Invalid input. Please enter $name:');
      } else {
        return input;
      }
    }
  }

  /// Ask the user for a y(es) / n(o) or empty input.
  Future<bool> askForBool(
    String name, {
    String? description,
    bool defaultsTo = true,
  }) async {
    final String defaultsToStr = defaultsTo ? '[Y/n]' : '[y/N]';
    logger.printStatus('\n $description $defaultsToStr (empty for default)');
    while (true) {
      final String input = await inputs.next;

      if (input.isEmpty) {
        return defaultsTo;
      } else if (input.toLowerCase() == 'y') {
        return true;
      } else if (input.toLowerCase() == 'n') {
        return false;
      } else {
        logger.printStatus(
            'Invalid input. Expected is either y, n or empty for default. $name? $defaultsToStr');
      }
    }
  }

  /// Ask the user if he wants to apply the config.
  /// Shows a different prompt if errors or warnings exist in the config.
  Future<bool> askApplyConfig({bool hasErrorsOrWarnings = false}) {
    return askForBool('apply',
        description: hasErrorsOrWarnings
            ? 'Warnings or errors exist in custom device. '
                'Would you like to add the custom device to the config anyway?'
            : 'Would you like to add the custom device to the config now?',
        defaultsTo: !hasErrorsOrWarnings);
  }
}
