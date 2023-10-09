import 'package:args/command_runner.dart';
import 'package:raspberry_device/runner.dart';
import 'dart:io' as io;

Future<void> main(List<String> arguments) async {
  late int exitCode;
  try {
    exitCode = await Runner().run(arguments) ?? 0;
  } on UsageException catch (e) {
    print(e);
    exitCode = 1;
  }

  io.exitCode = exitCode;
}
