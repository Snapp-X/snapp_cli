import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/utils/const.dart';
import 'package:yaml/yaml.dart';
import 'package:pub_semver/pub_semver.dart';

class UpdateService {
  final PubUpdater pubUpdater = PubUpdater();

  Future<String> currentVersion() async {
    final pkgConfig = (await findPackageConfigUri(Platform.script))!;

    final path = pkgConfig.resolve(Uri.parse('package:$kPackageName/'));

    final pubspecPath = path!.resolve('../pubspec.yaml').toFilePath();

    final pubspecFile = File(pubspecPath);

    final pubspecContent = pubspecFile.readAsStringSync();

    final pubspec = loadYaml(pubspecContent);

    final versionString = pubspec['version'] as String?;

    return versionString!;
  }

  Future<bool> isUpdateAvailable() async {
    final currentPackageVersion = await currentVersion();
    final latestVersion = await pubUpdater.getLatestVersion(kPackageName);

    logger.detail('Snapp_cli Current version: $currentPackageVersion');
    logger.detail('Snapp_cli Latest version: $latestVersion');

    final currentVersionDesc = Version.parse(currentPackageVersion);
    final latestVersionDesc = Version.parse(latestVersion);

    logger.detail(
        'Snapp_cli needs update: ${currentVersionDesc < latestVersionDesc}');

    return currentVersionDesc < latestVersionDesc;
  }

  Future<ProcessResult> update() =>
      pubUpdater.update(packageName: kPackageName);
}
