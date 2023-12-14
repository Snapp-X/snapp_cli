import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:snapp_cli/utils/const.dart';
import 'package:yaml/yaml.dart';

class UpdateController {
  final PubUpdater pubUpdater = PubUpdater();

  Future<String> currentVersion() async {
    final pkgConfig = (await findPackageConfigUri(Platform.script))!;

    final path = pkgConfig.resolve(Uri.parse('package:$kPackageName/'));

    print('script: ${Platform.script}');
    print('path: $path');

    final pubspecPath = path!.resolve('../pubspec.yaml').toFilePath();

    final pubspecFile = File(pubspecPath);

    final pubspecContent = pubspecFile.readAsStringSync();

    final pubspec = loadYaml(pubspecContent);

    final versionString = pubspec['version'] as String?;

    print('versionString: $versionString');

    return versionString!;
  }

  Future<bool> isUpdateAvailable() async {
    final currentPackageVersion = await currentVersion();

    final isPackageUpToDate = await pubUpdater.isUpToDate(
        packageName: kPackageName, currentVersion: currentPackageVersion);

    return !isPackageUpToDate;
  }

  Future<ProcessResult> update() =>
      pubUpdater.update(packageName: kPackageName);
}
