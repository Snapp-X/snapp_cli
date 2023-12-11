// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dartssh2/dartssh2.dart';
import 'package:interact/interact.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';

class SshService {
  SshService({
    required FlutterSdkManager flutterSdkManager,
  })  : logger = flutterSdkManager.logger,
        hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final Logger logger;

  final HostRunnerPlatform hostPlatform;

  final ProcessUtils processRunner;

  Future<bool> tryPingDevice(String pingTarget, bool ipv6) async {
    final spinner = Spinner(
      icon: logger.successIcon,
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
        'Something went wrong while pinging the device. \nException: $e \nStack: $s',
      );

      return false;
    } finally {
      spinner.done();

      logger.printSpaces();
    }

    logger.printTrace('Ping Command ExitCode: ${result.exitCode}');
    logger.printTrace('Ping Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('Ping Command Stderr: ${result.stderr}');

    logger.printSpaces();

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

  /// Creates a directory in the user's home directory
  /// to store the snapp_cli related files like ssh keys
  Future<Directory> createSnappCliDirectory() async {
    final String homePath = hostPlatform.homePath;
    final String snappCliDirectoryPath = '$homePath/.snapp_cli';

    final snappCliDirectory = Directory(snappCliDirectoryPath);

    if (!(await snappCliDirectory.exists())) {
      await snappCliDirectory.create();
    }

    return snappCliDirectory;
  }

  /// Generates a ssh key file in the snapp_cli directory
  Future<({File privateKey, File publicKey})> generateSshKeyFile(
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
          'Something went wrong while generating the ssh key. \nException: $e \nStack: $s');
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
  Future<void> addSshKeyToAgent(File sshKey) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        // TODO: add this to the hostPlatform
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
          'Something went wrong while adding the key to ssh-agent. \nException: $e \nStack: $s');
    }

    logger.printTrace('ssh-add Command ExitCode: ${result.exitCode}');
    logger.printTrace('ssh-add Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('ssh-add Command Stderr: ${result.stderr}');

    if (result.exitCode != 0) {
      throwToolExit('Something went wrong while adding the key to ssh-agent.');
    }
  }

  Future<void> copySshKeyToRemote(
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

    client.close();

    // You can get the exit code after the session is done
    logger.printTrace('SSH Session ExitCode: ${session.exitCode}');
    logger.printTrace('SSH Session stdout: ${session.stdout}');
    logger.printTrace('SSH Session stderr: ${session.stderr}');
  }

  Future<bool> createPasswordLessSshConnection(
    String username,
    InternetAddress ip,
  ) async {
    final isDeviceReachable = await tryPingDevice(
      ip.address,
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
        logger.printSpaces();
        logger.printStatus('Check your device IP-address and try again.');

        return false;
      }
    }

    logger.printSpaces();

    final spinner = Spinner(
      icon: logger.searchIcon,
      rightPrompt: (done) =>
          done ? 'Search completed.' : 'Searching for the device',
    ).interact();

    // create a directory in the user's home directory
    final snappCliDirectory = await createSnappCliDirectory();

    final sshKeys = await generateSshKeyFile(processRunner, snappCliDirectory);

    await addSshKeyToAgent(sshKeys.privateKey);

    spinner.done();

    await copySshKeyToRemote(
      sshKeys.publicKey,
      username,
      ip,
    );

    logger.printSpaces();

    return true;
  }

  /// Checks if the device is reachable via ssh
  Future<bool> testPasswordLessSshConnection(
    String username,
    InternetAddress ip,
  ) async {
    final String sshTarget = ip.sshTarget(username);

    final spinner = Spinner(
      icon: logger.searchIcon,
      rightPrompt: (done) =>
          done ? 'Search completed.' : 'Searching for the device',
    ).interact();

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: sshTarget,
          command: 'echo "Test SSH Connection"',
          lastCommand: true,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printStatus(
        'Something went wrong while trying to connect to the device via ssh. \nException: $e',
      );
      logger.printTrace('Stack: $s');

      return false;
    } finally {
      spinner.done();

      logger.printSpaces();
    }

    logger.printTrace('SSH Test Command ExitCode: ${result.exitCode}');
    logger.printTrace('SSH Test Command Stdout: ${result.stdout.trim()}');
    logger.printTrace('SSH Test Command Stderr: ${result.stderr}');

    logger.printSpaces();

    if (result.exitCode != 0) {
      return false;
    }

    return true;
  }
}
