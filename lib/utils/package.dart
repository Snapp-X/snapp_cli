// ignore_for_file: implementation_imports

import 'package:flutter_tools/src/base/process.dart';

class PackageUtils {
  const PackageUtils(this.processRunner);

  final ProcessUtils processRunner;

  Future<bool> isPackageInstalledGlobally(
    String packageName, {
    Duration processTimeout = const Duration(seconds: 10),
  }) async {
    final result = await processRunner.run(
      [
        'dart',
        'pub',
        'global',
        'list',
      ],
      timeout: processTimeout,
      timeoutRetries: 2,
    );

    if (result.exitCode != 0) {
      return false;
    }

    return result.stdout.contains(packageName);
  }
}
