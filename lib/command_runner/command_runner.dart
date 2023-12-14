// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/logger.dart';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:snapp_cli/commands/devices/devices_command.dart';
import 'package:snapp_cli/commands/ssh/ssh_command.dart';
import 'package:snapp_cli/utils/common.dart';
import 'package:snapp_cli/utils/flutter_sdk.dart';
import 'package:snapp_cli/utils/update.dart';

const deviceIdOption = FlutterGlobalOptions.kDeviceIdOption;

class SnappCliCommandRunner extends CommandRunner<int> {
  SnappCliCommandRunner({required this.flutterSdkManager})
      : super(
          'snapp_cli',
          'A command-line tool to manage custom devices for flutter',
        ) {
    // Add the device id option to all commands
    argParser.addOption(
      deviceIdOption,
      abbr: 'd',
      help: 'Target device id or name (prefixes allowed).',
    );

    // Add the devices command to the command runner
    addCommand(DevicesCommand(flutterSdkManager: flutterSdkManager));

    // Create and manage SSH connections
    addCommand(SshCommand(flutterSdkManager: flutterSdkManager));
  }

  final FlutterSdkManager flutterSdkManager;

  final UpdateController updateController = UpdateController();

  Logger get logger => flutterSdkManager.logger;

  @override
  Future<int?> run(Iterable<String> args) async {
    final areCustomDevicesEnabled = flutterSdkManager.areCustomDevicesEnabled;

    final isLinuxEnabled = flutterSdkManager.isLinuxEnabled;

    if (!areCustomDevicesEnabled || !isLinuxEnabled) {
      logger.printSpaces();

      logger.printStatus(
        '''
To use snapp_cli you need to enable custom devices and linux configs.
This is a one time setup and will not be required again.
''',
      );

      logger.printSpaces();

      final enableConfigs = Confirm(
        prompt: 'Do you want to enable them now?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      logger.printSpaces();

      if (!enableConfigs) {
        throwToolExit('''
Custom devices and linux configs are required.
if don't want to enable them now, you can enable them manually by running the following command:

flutter config --enable-custom-devices --enable-linux-desktop
        ''');
      }

      await _enableConfigs();
    }

    await _checkForUpdates();

    logger.printSpaces();

    return super.run(args);
  }

  Future<void> _enableConfigs() async {
    final spinner = Spinner(
      icon: logger.successIcon,
      leftPrompt: (done) => '', // prompts are optional
      rightPrompt: (done) => done
          ? 'Configs enabled successfully!'
          : 'Enabling custom devices and linux configs...',
    ).interact();

    final processRunner = ProcessUtils(
      processManager: flutterSdkManager.processManager,
      logger: logger,
    );

    await Future.delayed(Duration(seconds: 1));

    final RunResult result;
    try {
      result = await processRunner.run(
        <String>[
          'flutter',
          'config',
          '--enable-custom-devices',
          '--enable-linux-desktop',
        ],
        timeout: Duration(seconds: 10),
      );
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong. \n $e \n $s',
      );

      return;
    } finally {
      spinner.done();

      logger.printSpaces();
    }

    if (result.exitCode != 0) {
      throwToolExit('''
Something went wrong.
Could not enable custom devices and linux configs.
Please enable them manually by running the following command:

flutter config --enable-custom-devices --enable-linux-desktop
''');
    }
  }

  Future<void> _checkForUpdates() async {
    final bool isUpdateAvailable;
    try {
      isUpdateAvailable = await updateController.isUpdateAvailable();
    } catch (e, s) {
      logger.printTrace(
        'Something went wrong. During checking for updates. \n $e \n $s',
      );

      return;
    }

    logger.printSpaces();

    if (isUpdateAvailable) {
      logger.printStatus('A new version of snapp_cli is available!');

      final updateConfirmed = Confirm(
        prompt: 'Do you want to update now?',
        defaultValue: true, // this is optional
        waitForNewLine: true, // optional and will be false by default
      ).interact();

      logger.printSpaces();

      if (!updateConfirmed) return;

      final spinner = Spinner(
        icon: logger.successIcon,
        leftPrompt: (done) => '', // prompts are optional
        rightPrompt: (done) =>
            done ? 'Updated process completed!' : 'Updating snapp_cli...',
      ).interact();

      final result = await updateController.update();

      logger.printSpaces();

      spinner.done();

      if (result.exitCode != 0) {
        throwToolExit('Something went wrong. \n ${result.stderr}');
      }

      logger.printStatus(result.stdout);

      logger.printSpaces();

      logger.printSuccess('Snapp_cli updated successfully! 🎉');

      exit(0);
    }
  }
}
