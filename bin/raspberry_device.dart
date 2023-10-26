import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:raspberry_device/runner.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:raspberry_device/utils/flutter_sdk.dart';

Future<void> main(List<String> arguments) async {
  late int exitCode;

  final FlutterSdkManager sdkManager = FlutterSdkManager();

  try {
    /// Initialize the Flutter SDK
    await sdkManager.initialize();

    // TODO: check custom devices is enabled or not ? checkFeatureEnabled

    exitCode = await runInContext(() async {
      return await Runner(flutterSdkManager: sdkManager).run(arguments) ?? 0;
    });
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
  } catch (e, st) {
    print('Error: $e\n$st');
    exitCode = 1;
  } 

  io.exit(exitCode);
}
