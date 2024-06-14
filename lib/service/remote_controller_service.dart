// ignore_for_file: implementation_imports

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_tools/src/base/process.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/snapp_cli.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/service/interaction_service.dart';
import 'package:snapp_cli/utils/process.dart';

class RemoteControllerService {
  RemoteControllerService({
    required FlutterSdkManager flutterSdkManager,
  })  : hostPlatform = HostRunnerPlatform.build(flutterSdkManager.platform),
        processManager = flutterSdkManager.processManager,
        processRunner = ProcessUtils(
          processManager: flutterSdkManager.processManager,
          logger: flutterSdkManager.logger,
        );

  final HostRunnerPlatform hostPlatform;

  final ProcessManager processManager;
  final ProcessUtils processRunner;

  /// Searches for the specified tool on a remote machine using SSH and returns the path if found.
  ///
  /// This function connects to a remote machine via SSH and attempts to find the specified tool.
  /// If the tool is found, the function will return its path. If multiple paths are found,
  /// the user will be prompted to select one. It also optionally checks for preferred paths.
  ///
  /// Parameters:
  /// - `username`: The SSH username for the remote machine.
  /// - `ip`: The IP address of the remote machine. Supports both IPv4 and IPv6.
  /// - `toolName`: The name of the tool to search for on the remote machine.
  /// - `toolPath`: (Optional) A specific path pattern to search within for the tool.
  /// - `preferredPaths`: (Optional) A list of preferred paths to prioritize if found in the search results.
  /// - `addHostToKnownHosts`: (Optional) Whether to add the remote host to the known hosts list. Default is `true`.
  ///
  /// Example:
  /// ```dart
  /// final flutterPath = await findToolPath(
  ///   username: 'user',
  ///   ip: InternetAddress('192.168.1.100'),
  ///   toolName: 'flutter',
  ///   toolPath: '*/flutter/bin/*', // Optional specific path pattern
  ///   preferredPaths: ['/usr/local/flutter/bin/flutter'], // Optional preferred paths
  /// );
  /// ```
  ///
  /// Notes:
  /// - If `toolPath` is provided, the function will search within this specific path pattern.
  /// - If multiple paths are found, the user will be prompted to select one from the list.
  /// - If `preferredPaths` are provided, they will be prioritized in the selection process if found.
  /// - This function uses a spinner to indicate progress and logs detailed messages during the execution.
  Future<String?> findToolPath({
    required String username,
    required InternetAddress ip,
    required String toolName,
    String? toolPath,
    List<String>? preferredPaths,
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'search for $toolName path on remote device.',
      doneMessage: 'search for $toolName path completed',
      failedMessage: 'search for $toolName path failed',
    );

    final searchCommand = toolPath != null
        ? 'find / -type f -name "$toolName" -path "$toolPath" 2>/dev/null'
        : 'find / -type f -name "$toolName" 2>/dev/null';

    final output = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.isIpv6,
        sshTarget: ip.sshTarget(username),
        command: searchCommand,
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      timeout: const Duration(seconds: 30),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          logger.spaces();

          return null;
        }

        return output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find $toolName. \n $e \n $s',
        );

        logger.spaces();

        return null;
      },
      spinner: spinner,
      label: 'Find $toolName',
      logger: logger,
    );

    logger.detail('Find $toolName output: $output');

    logger.spaces();

    if (output == null) return null;

    final outputLinesLength = output.split('\n').length;
    final isOutputMultipleLines = outputLinesLength > 1;

    if (!isOutputMultipleLines) {
      logger.info('We found $toolName in "$output" in the remote machine. ');

      final toolPathConfirmation = interaction.confirm(
        'Do you want to use this path?',
        defaultValue: true, // this is optional
      );

      return toolPathConfirmation ? output : null;
    } else {
      logger.info('We found multiple $toolName paths in the remote machine. ');

      final outputLines = output
          .split('\n')
          .map((e) => e.trim())
          .toList()
          .sublist(0, min(2, outputLinesLength));

      if (preferredPaths != null) {
        final preferredPathsSet = preferredPaths.toSet();

        final preferredPathsInOutput = preferredPathsSet
            .where(
              (element) => outputLines.any(
                (line) => line.contains(element),
              ),
            )
            .toList();

        if (preferredPathsInOutput.isNotEmpty) {
          if (preferredPathsInOutput.length == 1) {
            return preferredPathsInOutput.first;
          }

          return interaction.select(
            'Please select the path of $toolName you want to use.',
            options: preferredPathsInOutput,
          );
        }
      }

      return interaction.select(
        'Please select the path of $toolName you want to use.',
        options: outputLines,
      );
    }
  }

  Future<String?> findToolPathInteractive({
    required String username,
    required InternetAddress ip,
    required String toolName,
    String? toolPath,
    List<String>? preferredPaths,
    bool addHostToKnownHosts = true,
  }) async {
    return processRunner.runCommand<String>(
      hostPlatform.sshCommand(
        ipv6: ip.isIpv6,
        sshTarget: ip.sshTarget(username),
        command: toolPath != null
            ? 'find / -type f -name "$toolName" -path "$toolPath" 2>/dev/null'
            : 'find / -type f -name "$toolName" 2>/dev/null',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          return null;
        }

        final outputLines = output.split('\n').map((e) => e.trim()).toList();

        logger.detail(
            'findToolPathInteractive $toolName outputLines: $outputLines');

        final outputLinesLength = outputLines.length;
        final isOutputMultipleLines = outputLinesLength > 1;

        final preferredPathsSet = preferredPaths?.toSet();

        if (preferredPathsSet != null) {
          final preferredPathsInOutput = preferredPathsSet
              .where(
                (element) => outputLines.any(
                  (line) => line.contains(element),
                ),
              )
              .toList();

          if (preferredPathsInOutput.isNotEmpty) {
            logger.detail('Find $toolName in Preferred Paths');
            logger.detail('Preferred Paths in Output: $preferredPathsInOutput');
            return preferredPathsInOutput.first;
          }
        }

        logger.detail('Find $toolName in Output');
        logger.detail('Output: $outputLines');

        return isOutputMultipleLines ? outputLines.first : output;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find $toolName. \n $e \n $s',
        );

        return null;
      },
      label: 'Find $toolName',
      logger: logger,
    );
  }

  /// finds flutter in the remote machine using ssh connection
  /// returns the path of flutter if found it
  /// otherwise returns null
  Future<String?> findFlutterPath(
    String username,
    InternetAddress ip,
  ) =>
      findToolPath(
        username: username,
        ip: ip,
        toolName: 'flutter',
        toolPath: '*/flutter/bin/*',
      );

  ///  'find / -type f -name "flutter" -path "*/flutter/bin/*" 2>/dev/null',
  Future<String?> findFlutterPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) =>
      findToolPathInteractive(
        username: username,
        ip: ip,
        toolName: 'flutter',
        toolPath: '*/flutter/bin/*',
        addHostToKnownHosts: addHostToKnownHosts,
      );

  Future<String?> findSnappInstallerPath(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) =>
      findToolPath(
        username: username,
        ip: ip,
        toolName: 'snapp_installer',
        toolPath: '*/snapp_installer/bin/*',
      );

  /// finds snapp_installer in the remote machine using ssh connection interactively
  ///
  /// this method is not communicating with the user directly
  Future<String?> findSnappInstallerPathInteractive(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) =>
      findToolPathInteractive(
        username: username,
        ip: ip,
        toolName: 'snapp_installer',
        toolPath: '*/snapp_installer/bin/*',
        addHostToKnownHosts: addHostToKnownHosts,
      );

  Future<String?> findFlutterVersion(
    String username,
    InternetAddress ip,
    String flutterRunnerPath, {
    bool addHostToKnownHosts = true,
  }) async {
    final spinner = interaction.spinner(
      inProgressMessage: 'Search for flutter version on remote device.',
      doneMessage: 'Search for flutter version completed',
      failedMessage: 'Search for flutter version failed',
    );

    final output = await processRunner.runCommand(
      hostPlatform.sshCommand(
        ipv6: ip.isIpv6,
        sshTarget: ip.sshTarget(username),
        command: '$flutterRunnerPath --version --machine',
        addHostToKnownHosts: addHostToKnownHosts,
      ),
      throwOnError: false,
      parseResult: (runResult) {
        final output = runResult.stdout.trim();

        if (runResult.exitCode != 0 && output.isEmpty) {
          logger.spaces();

          return null;
        }

        final jsonOutput = jsonDecode(output);

        logger.detail('Find Flutter Version jsonOutput: $jsonOutput');

        logger.detail(
            'Find Flutter Version jsonOutput[flutterVersion]: ${jsonOutput['flutterVersion']}');

        return jsonOutput['flutterVersion'] as String;
      },
      parseFail: (e, s) {
        logger.detail(
          'Something went wrong while trying to find flutter version. \n $e \n $s',
        );

        logger.spaces();

        return null;
      },
      spinner: spinner,
      label: 'Find Flutter Version',
      logger: logger,
    );

    logger.detail('Find Flutter Version output: $output');

    logger.spaces();

    return output;
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
      logger.detail(
        'Something went wrong while trying to find snapp_installer. \n $e \n $s',
      );

      return false;
    } finally {
      logger.spaces();
    }

    if (result.exitCode != 0) {
      logger.info('Snapp Installer ExitCode: ${result.exitCode}');
      logger.info('Snapp Installer Stdout: ${result.stdout.trim()}');
      logger.info('Snapp Installer Stderr: ${result.stderr}');
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
    String? version,
    bool addHostToKnownHosts = true,
  }) async {
    final snappInstallerPath = await findSnappInstallerPathInteractive(
      username,
      ip,
    );

    final RunResult result;

    final versionArgs = version != null ? '-v $version -f' : '';

    final installFlutterCommand = '$snappInstallerPath install -q $versionArgs';

    logger.detail('Install Flutter Command: \n $installFlutterCommand');

    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command: installFlutterCommand,
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.detail(
        'Something went wrong while trying to install flutter on the remote. \n $e \n $s',
      );

      return false;
    } finally {
      logger.spaces();
    }

    if (result.exitCode != 0) {
      logger.info('Flutter Installer ExitCode: ${result.exitCode}');
      logger.info('Flutter Installer Stdout: ${result.stdout.trim()}');
      logger.info('Flutter Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }

  Future<bool> installFlutterPiOnRemote(
    String username,
    InternetAddress ip, {
    bool addHostToKnownHosts = true,
  }) async {
    final snappInstallerPath = await findSnappInstallerPathInteractive(
      username,
      ip,
    );

    final RunResult result;

    final installFlutterPiCommand = '$snappInstallerPath install_flutter_pi';

    logger.detail('Install Flutter Pi Command: \n $installFlutterPiCommand');

    try {
      result = await processRunner.runWithOutput(
        hostPlatform.sshCommand(
          ipv6: ip.isIpv6,
          sshTarget: ip.sshTarget(username),
          lastCommand: true,
          command: installFlutterPiCommand,
          addHostToKnownHosts: addHostToKnownHosts,
        ),
        processManager: processManager,
        logger: logger,
      );
    } catch (e, s) {
      logger.detail(
        'Something went wrong while trying to install flutter-pi on the remote. \n $e \n $s',
      );

      return false;
    } finally {
      logger.spaces();
    }

    if (result.exitCode != 0) {
      logger.info('Flutter Pi Installer ExitCode: ${result.exitCode}');
      logger.info('Flutter Pi Installer Stdout: ${result.stdout.trim()}');
      logger.info('Flutter Pi Installer Stderr: ${result.stderr}');
    }

    return result.exitCode == 0;
  }
}
