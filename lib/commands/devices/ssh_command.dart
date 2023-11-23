// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dartssh2/dartssh2.dart';
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
    final spinner = Spinner(
      icon: '✔️',
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'creating SSH connection completed.'
          : 'creating SSH connection.',
    ).interact();

    // create a directory in the user's home directory
    final snappCliDirectory = await _createSnappCliDirectory();

    final sshKeys = await _generateSshKeyFile(processRunner, snappCliDirectory);

    await _addSshKeyToAgent(sshKeys.privateKey);

    spinner.done();

    final sshKeyCopied = await _copySshKeyToRemote(
      sshKeys.publicKey,
      username,
      ip,
    );

    printSpaces();

    return sshKeyCopied;
  }

  /// Creates a directory in the user's home directory
  /// to store the snapp_cli related files like ssh keys
  Future<Directory> _createSnappCliDirectory() async {
    final String homePath = hostPlatform.homePath;
    final String snapppCliDirectoryPath = '$homePath/.snapp_cli';

    final snappCliDirectory = Directory(snapppCliDirectoryPath);

    if (!(await snappCliDirectory.exists())) {
      await snappCliDirectory.create();
    }

    return snappCliDirectory;
  }

  /// Generates a ssh key file in the snapp_cli directory
  Future<({File privateKey, File publicKey})> _generateSshKeyFile(
    ProcessUtils processRunner,
    Directory snappCliDir,
  ) async {
    // generate random 6 digit file name
    final randomNumber = Random().nextInt(900000) + 100000;

    final keyFile = File('${snappCliDir.path}/id_rsa_$randomNumber');

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

    return (privateKey: keyFile, publicKey: File('${keyFile.path}.pub'));
  }

  /// Adds the ssh key to the ssh-agent
  Future<void> _addSshKeyToAgent(File sshKey) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.commandRunner(
          [
            'ssh-add',
            sshKey.path,
          ],
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      throwToolExit(
          'Something went wrong while adding the key to ssh-agent. \nException: $s \nStack: $s');
    }

    logger.printTrace('ssh-add Command ExitCode: ${result.exitCode}');
    logger.printTrace('ssh-add Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('ssh-add Command Stderr: ${result.stderr}');

    if (result.exitCode != 0) {
      throwToolExit('Something went wrong while adding the key to ssh-agent.');
    }
  }

  Future<bool> _copySshKeyToRemote(
    File sshKeyFile,
    String username,
    InternetAddress ip,
  ) async {
    final client = SSHClient(
      await SSHSocket.connect(
        ip.address,
        22,
        timeout: Duration(seconds: 10),
      ),
      username: username,
      onPasswordRequest: () {
        stdout.write('Password: ');
        stdin.echoMode = false;
        return stdin.readLineSync() ?? exit(1);
      },
    );

    final session = await client.execute('cat >> .ssh/authorized_keys');
    await session.stdin.addStream(sshKeyFile.openRead().cast());

    // Close the sink to send EOF to the remote process.
    await session.stdin.close();

    // Wait for session to exit to ensure all data is flushed to the remote process.
    await session.done;

    // You can get the exit code after the session is done
    print(session.exitCode);

    client.close();
    return true;
  }
}
