// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/base_command.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/utils/common.dart';

class SshCommand extends BaseSnappCommand {
  SshCommand({
    required super.flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  @override
  String get description => 'Create an SSH connection to the remote device';

  @override
  String get name => 'ssh';

  /// create a HostPlatform instance based on the current platform
  /// with the help of this class we can make the commands platform specific
  /// for example, the ping command is different on windows and linux
  ///
  /// only supports windows, linux and macos
  final HostRunnerPlatform hostPlatform;

  final ProcessUtils processRunner;

  @override
  FutureOr<int>? run() async {
    printSpaces();

    logger.printStatus(
      'to create an SSH connection to the remote device, we need an IP address and a username',
    );

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

    printSpaces();

    final String username = Input(
      prompt: 'Username:',
    ).interact();

    printSpaces();

    final isDeviceReachable = await _tryPingDevice(
      deviceIp,
      ip.type == InternetAddressType.IPv6,
    );

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

    print('ip formatted: ${ip.address}');

    printSpaces();

    final sshConnectionCreated =
        await _createPasswordlessSshConnection(username, ip);

    return sshConnectionCreated ? 0 : 1;
  }

  Future<bool> _tryPingDevice(String pingTarget, bool ipv6) async {
    final spinner = Spinner(
      icon: '✔️',
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'pinging device completed.'
          : 'pinging device to check if it is reachable.',
    ).interact();

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

  Future<bool> _createPasswordlessSshConnection(
    String username,
    InternetAddress ip,
  ) async {
    // SSH expects IPv6 addresses to use the bracket syntax like URIs do too,
    // but the IPv6 the user enters is a raw IPv6 address, so we need to wrap it.
    final String sshTarget = (username.isNotEmpty ? '$username@' : '') +
        (ip.type == InternetAddressType.IPv6 ? '[${ip.address}]' : ip.address);

    final spinner = Spinner(
      icon: '✔️',
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'creating SSH connection completed.'
          : 'creating SSH connection.',
    ).interact();

    // create a directory in the user's home directory
    final snappCliDirectory = await _createSnapppCliDirectory();

    final sshKeyFile =
        await _generateSshKeyFile(processRunner, snappCliDirectory);

    spinner.done();

    final sshKeyCopied = await _copySshKeyToRemote(
      sshKeyFile,
      ip.type == InternetAddressType.IPv6,
      sshTarget,
    );

    printSpaces();

    return sshKeyCopied;
  }

  /// Creates a directory in the user's home directory
  /// to store the snapp_cli related files like ssh keys
  Future<Directory> _createSnapppCliDirectory() async {
    final String homePath = hostPlatform.homePath;
    final String snapppCliDirectoryPath = '$homePath/.snapp_cli';

    final snappCliDirectory = Directory(snapppCliDirectoryPath);

    if (!(await snappCliDirectory.exists())) {
      await snappCliDirectory.create();
    }

    return snappCliDirectory;
  }

  Future<File> _generateSshKeyFile(
    ProcessUtils processRunner,
    Directory snappCliDir,
  ) async {
    // generate random 6 digit file name
    final fileName = Random().nextInt(900000) + 100000;

    final keyFile = File('${snappCliDir.path}/$fileName');
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.generateSshKeyCommand(
          filePath: keyFile.path,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      throwToolExit(
          'Something went wrong while generating the ssh key. \nException: $s \nStack: $s');
    }

    logger.printTrace('SSH Command ExitCode: ${result.exitCode}');
    logger.printTrace('SSH Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('SSH Command Stderr: ${result.stderr}');

    if (result.exitCode != 0) {
      throwToolExit('Something went wrong while generating the ssh key.');
    }

    return keyFile;
  }

  Future<bool> _copySshKeyToRemote(
    File sshKeyFile,
    bool ipv6,
    String targetDevice,
  ) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.copySshKeyCommand(
          filePath: sshKeyFile.path,
          ipv6: ipv6,
          targetDevice: targetDevice,
        ),
      );
    } catch (e, s) {
      throwToolExit(
          'Something went wrong while generating the ssh key. \n $s \n $s');
    }

    logger.printTrace('SSH key copy Command ExitCode: ${result.exitCode}');
    logger.printTrace('SSH key copy Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('SSH key copy Command Stderr: ${result.stderr}');

    return result.exitCode == 0;
  }
}
