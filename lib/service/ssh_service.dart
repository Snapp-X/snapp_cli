// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/service/interaction_service.dart';
import 'package:snapp_cli/utils/process.dart';

class SshService {
  SshService({
    required FlutterSdkManager flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final HostRunnerPlatform hostPlatform;

  final ProcessUtils processRunner;

  Future<bool> tryPingDevice(String pingTarget, bool ipv6) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'Pinging device to check if it is reachable',
      doneMessage: 'Pinging device completed',
      failedMessage: 'Pinging device failed',
    );

    await Future.delayed(Duration(seconds: 2));

    final RunResult? result = await processRunner.runCommand(
      hostPlatform.pingCommand(ipv6: ipv6, pingTarget: pingTarget),
      parseResult: (result) => result,
      parseFail: (e, s) {
        logger.info(
          'Something went wrong while pinging the device.',
        );
        logger.detail(
          'Exception: $e \nStack: $s',
        );

        return null;
      },
      spinner: spinner,
      label: 'pingCommand',
      logger: logger,
    );

    if (result == null || result.exitCode != 0) {
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
    logger.detail('try to create SnappCli directory');

    final String homePath = hostPlatform.homePath;
    final String snappCliDirectoryPath = '$homePath/.snapp_cli';

    final snappCliDirectory = Directory(snappCliDirectoryPath);

    if (!(await snappCliDirectory.exists())) {
      logger.detail('SnappCli directory does not exist, creating it now');
      return await snappCliDirectory.create();
    }

    logger.detail('SnappCli directory already exists');

    return snappCliDirectory;
  }

  /// Generates a ssh key file in the snapp_cli directory
  Future<({File privateKey, File publicKey})> generateSshKeyFile(
    ProcessUtils processRunner,
    Directory snappCliDir,
  ) async {
    logger.detail('try to generate ssh key file');

    // generate random 6 digit file name
    final randomNumber = Random().nextInt(900000) + 100000;

    final keyFile = File('${snappCliDir.path}/id_rsa_$randomNumber');

    final RunResult? result = await processRunner.runCommand(
      hostPlatform.generateSshKeyCommand(filePath: keyFile.path),
      parseResult: (result) => result,
      parseFail: (e, s) {
        throwToolExit(
            'Something went wrong while generating the ssh key. \nException: $e \nStack: $s');
      },
      label: 'generateSshKeyCommand',
      logger: logger,
    );

    if (result?.exitCode != 0) {
      logger.detail('generateSshKeyCommand exitCode: ${result?.exitCode}');
      logger.detail('generateSshKeyCommand stdout: ${result?.stdout}');
      logger.detail('generateSshKeyCommand stderr: ${result?.stderr}');

      throwToolExit('Something went wrong while generating the ssh key.');
    }

    return (privateKey: keyFile, publicKey: File('${keyFile.path}.pub'));
  }

  /// Adds the ssh key to the ssh-agent
  Future<void> addSshKeyToAgent(File sshKey) async {
    logger.detail('try to add ssh key to ssh-agent');

    final RunResult? result = await processRunner.runCommand(
      hostPlatform.addSshKeyToAgent(filePath: sshKey.path),
      parseResult: (result) => result,
      parseFail: (e, s) {
        throwToolExit(
            'Something went wrong while adding the key to ssh-agent. \nException: $e \nStack: $s');
      },
    );

    if (result?.exitCode != 0) {
      logger.detail('addSshKeyToAgent exitCode: ${result?.exitCode}');
      logger.detail('addSshKeyToAgent stdout: ${result?.stdout}');
      logger.detail('addSshKeyToAgent stderr: ${result?.stderr}');

      throwToolExit('Something went wrong while generating the ssh key.');
    }
  }

  Future<void> copySshKeyToRemote(
    File sshKeyFile,
    String username,
    InternetAddress ip,
  ) async {
    logger.detail('try to copy ssh key to remote');

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

    logger.detail('creating ~/.ssh/authorized_keys');

    final createAuthFile = await client.run(
      '[ ! -d ~/.ssh ] && mkdir -p ~/.ssh; [ ! -f ~/.ssh/authorized_keys ] && touch ~/.ssh/authorized_keys',
    );

    logger.detail(
        'creating ~/.ssh/authorized_keys: result is empty: ${createAuthFile.isEmpty}');
    logger.detail(
        'creating ~/.ssh/authorized_keys: ${utf8.decode(createAuthFile)}');

    final session = await client.execute('cat >> .ssh/authorized_keys');

    session.stdout.listen((data) {
      final String dataAsString = utf8.decode(data);
      logger.detail('SSH Session stdout: $dataAsString');
    });

    session.stderr.listen((data) {
      final String dataAsString = utf8.decode(data);
      logger.detail('SSH Session stderr: $dataAsString');
    });

    await session.stdin.addStream(sshKeyFile.openRead().cast());

    // Close the sink to send EOF to the remote process.
    await session.stdin.close();

    // Wait for session to exit to ensure all data is flushed to the remote process.
    await session.done;

    client.close();

    // You can get the exit code after the session is done

    if (session.exitCode != 0) {
      logger.detail('SSH Session ExitCode: ${session.exitCode}');

      throwToolExit(
          'Something went wrong while copying the ssh key to the remote device.');
    }
  }

  Future<bool> createPasswordLessSshConnection(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final isDeviceReachable = await tryPingDevice(
      ip.address,
      ip.type == InternetAddressType.IPv6,
    );

    if (!isDeviceReachable) {
      logger.info(
        'Could not reach the device with the given IP-address.',
      );

      final continueWithoutPing = interaction.confirm(
        'Do you want to continue anyway?',
        defaultValue: true, // this is optional
      );

      if (!continueWithoutPing) {
        logger.spaces();
        logger.info('Check your device IP-address and try again.');

        return false;
      }
    }

    logger.spaces();

    final progress = interaction.progress(
      'Preparing SSH connection',
    );

    // create a directory in the user's home directory
    final snappCliDirectory = await createSnappCliDirectory();

    final sshKeys = await generateSshKeyFile(processRunner, snappCliDirectory);

    await addSshKeyToAgent(sshKeys.privateKey);

    progress.complete('Preparing SSH connection completed');

    await copySshKeyToRemote(
      sshKeys.publicKey,
      username,
      ip,
    );

    logger.spaces();

    return true;
  }

  /// Checks if the device is reachable via ssh
  Future<bool> testPasswordLessSshConnection(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final String sshTarget = ip.sshTarget(username);

    final spinner = interaction.spinner(
      inProgressMessage: 'Testing SSH connection',
      doneMessage: 'Testing SSH connection completed',
      failedMessage: 'Testing SSH connection failed',
    );

    final result = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.type == InternetAddressType.IPv6,
        sshTarget: sshTarget,
        command: 'echo "Test SSH Connection"',
        addHostToKnownHosts: addHostToKnownHosts,
        lastCommand: true,
      ),
      parseResult: (result) {
        return true;
      },
      parseFail: (e, s) {
        logger.info(
            'Something went wrong while trying to connect to the device via ssh.');
        logger.detail(
          'Exception: $e \nStack: $s',
        );
        return false;
      },
      spinner: spinner,
      label: 'testPasswordLessSshConnection',
      logger: logger,
    );

    return result ?? false;
  }
}
