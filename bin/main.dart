import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:snapp_cli/snapp_cli.dart';

Future<void> main(List<String> arguments) async {
  late int exitCode;

  final FlutterSdkManager sdkManager = FlutterSdkManager();

  try {
    /// Initialize connection to the flutter sdk
    await sdkManager.initialize();

    exitCode = await runInContext(() async {
      // Check if custom devices feature is enabled
      // If not, throw an error
      if (!sdkManager.areCustomDevicesEnabled) {
        throwToolExit('Custom devices feature must be enabled. '
            'Enable using `flutter config --enable-custom-devices`.');
      }

      return await SnappCliCommandRunner(
            flutterSdkManager: sdkManager,
          ).run(arguments) ??
          0;
    });
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
  } on ToolExit catch (e) {
    print('Tool Error: ${e.message}');

    exitCode = e.exitCode ?? 1;
  } catch (e, _) {
    print('$e\n');
    exitCode = 1;
  }

  io.exit(exitCode);
}
