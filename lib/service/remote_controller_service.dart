// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:interact/interact.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';

class RemoteControllerService {
  RemoteControllerService({
    required FlutterSdkManager flutterSdkManager,
  })  : logger = flutterSdkManager.logger,
        hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processManager = flutterSdkManager.processManager,
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final Logger logger;

  final HostRunnerPlatform hostPlatform;

  final ProcessManager processManager;
  final ProcessUtils processRunner;

  /// finds flutter in the remote machine using ssh connection
  /// returns the path of flutter if found it
  /// otherwise returns null
  Future<String?> findFlutterPath(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = Spinner(
      icon: logger.successIcon,
      failedIcon: logger.errorIcon,
      rightPrompt: (state) => switch (state) {
        SpinnerStateType.inProgress =>
          'search for flutter path on remote device.',
        SpinnerStateType.done => 'search for flutter path completed',
        SpinnerStateType.failed => 'search for flutter path failed',
      },
    ).interact();

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      spinner.failed();
      logger.printTrace(
        'Something went wrong while trying to find flutter. \n $e \n $s',
      );

      return null;
    } finally {
      logger.printSpaces();
    }

    logger.printTrace('Find Flutter ExitCode: ${result.exitCode}');
    logger.printTrace('Find Flutter Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find Flutter Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      spinner.failed();
      return null;
    }

    spinner.done();

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

  Future<String?> findFlutterPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find flutter. \n $e \n $s',
      );

      return null;
    } finally {
      logger.printSpaces();
    }

    logger.printTrace('Find Flutter ExitCode: ${result.exitCode}');
    logger.printTrace('Find Flutter Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find Flutter Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }
    final outputLines = output.split('\n').map((e) => e.trim()).toList();
    final outputLinesLength = outputLines.length;
    final isOutputMultipleLines = outputLinesLength > 1;

    return isOutputMultipleLines ? outputLines.first : output;
  }

  /// finds snapp_installer in the remote machine using ssh connection
  /// returns the path of snapp_installer if found it
  /// otherwise returns null
  Future<String?> findSnappInstallerPath(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = Spinner(
      icon: logger.successIcon,
      rightPrompt: (done) => switch (done) {
        SpinnerStateType.inProgress =>
          'search for snapp_installer path on remote device.',
        SpinnerStateType.done => 'search for snapp_installer path completed',
        SpinnerStateType.failed => 'search for snapp_installer path failed',
      },
    ).interact();

    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      spinner.failed();

      logger.printTrace(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return null;
    } finally {
      logger.printSpaces();
    }

    logger.printTrace('Find snapp_installer ExitCode: ${result.exitCode}');
    logger.printTrace('Find snapp_installer Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find snapp_installer Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      spinner.failed();

      return null;
    }

    spinner.done();

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger.printStatus(
          'We found snapp_installer in "$output" in the remote machine. ');

      final snappInstallerPathConfirmation = Confirm(
        prompt: 'Do you want to use this path?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      return snappInstallerPathConfirmation ? output : null;
    }

    return null;
  }

  /// finds snapp_installer in the remote machine using ssh connection interactively
  ///
  /// this method is not communicating with the user directly
  Future<String?> findSnappInstallerPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final RunResult result;
    try {
      result = await processRunner.run(
        hostPlatform.sshCommand(
          ipv6: ip.type == InternetAddressType.IPv6,
          sshTarget: ip.sshTarget(username),
          command:
              'find / -type f -name "snapp_installer" -path "*/snapp_installer/bin/*" 2>/dev/null',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return null;
    } finally {
      logger.printSpaces();
    }

    logger.printTrace('Find snapp_installer ExitCode: ${result.exitCode}');
    logger.printTrace('Find snapp_installer Stdout: ${result.stdout.trim()}');
    logger.printTrace('Find snapp_installer Stderr: ${result.stderr}');

    final output = result.stdout.trim();

    if (result.exitCode != 0 && output.isEmpty) {
      return null;
    }

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    return isOutputMultipleLines ? null : output;
  }

  /// install snapp_installer in the remote machine using ssh connection
  ///
  /// we will use snapp_installer[https://github.com/Snapp-Embedded/snapp_installer] to install flutter in the remote machine
  /// with this method you can first install snapp_installer
  ///
  /// returns true if snapp_installer installed successfully
  /// otherwise returns false
  Future<bool> installSnappInstallerOnRemote(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final RunResult result;
    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command:
              'bash <(curl -fSL https://raw.githubusercontent.com/Snapp-Embedded/snapp_installer/main/installer.sh)',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return false;
    } finally {
      logger.printSpaces();
    }

    if (result.exitCode != 0) {
      logger.printStatus('Snapp Installer ExitCode: ${result.exitCode}');
      logger.printStatus('Snapp Installer Stdout: ${result.stdout.trim()}');
      logger.printStatus('Snapp Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }

  /// in
  /// install flutter in the remote machine using ssh connection
  ///
  /// we will use snapp_installer[https://github.com/Snapp-Embedded/snapp_installer] to install flutter in the remote machine
  ///
  /// returns true if snapp_installer installed successfully
  /// otherwise returns false
  Future<bool> installFlutterOnRemote(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final snappInstallerPath = await findSnappInstallerPathInteractive(
      username,
      ip,
    );

    final RunResult result;
    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command: '$snappInstallerPath install',
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong while trying to install flutter on the remote. \n $e \n $s',
      );

      return false;
    } finally {
      logger.printSpaces();
    }

    if (result.exitCode != 0) {
      logger.printStatus('Flutter Installer ExitCode: ${result.exitCode}');
      logger.printStatus('Flutter Installer Stdout: ${result.stdout.trim()}');
      logger.printStatus('Flutter Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }
}
