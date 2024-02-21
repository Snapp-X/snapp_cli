import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:package_config/package_config.dart';
import 'package:process/process.dart';
import 'package:snapp_cli/service/logger_service.dart';
import 'package:snapp_cli/utils/const.dart';
import 'package:yaml/yaml.dart';
import 'package:pub_semver/pub_semver.dart';

const _pubPackagesPath = 'https://pub.dev/api/packages/';

class UpdateService {
  /// {@macro pub_update}
  const UpdateService([http.Client? client, String baseUrl = _pubPackagesPath])
      : _client = client,
        _baseUrl = baseUrl;

  final http.Client? _client;
  final String _baseUrl;

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
    final latestVersion = await _getPackageLatestVersion(kPackageName);

    logger.detail('Snapp_cli Current version: $currentPackageVersion');
    logger.detail('Snapp_cli Latest version: $latestVersion');

    final currentVersionDesc = Version.parse(currentPackageVersion);
    final latestVersionDesc = Version.parse(latestVersion);

    logger.detail(
        'Snapp_cli needs update: ${currentVersionDesc < latestVersionDesc}');

    return currentVersionDesc < latestVersionDesc;
  }

  /// Updates the package associated with [packageName]
  Future<ProcessResult> update() {
    final ProcessManager processManager = const LocalProcessManager();

    return processManager.run(
      [
        'dart',
        'pub',
        'global',
        'activate',
        kPackageName,
      ],
    );
  }

  Future<http.Response> _get(Uri uri) => _client?.get(uri) ?? http.get(uri);

  Future<String> _getPackageLatestVersion(String packageName) async {
    final uri = Uri.parse('$_baseUrl$packageName');

    final response = await _get(uri);

    if (response.statusCode != HttpStatus.ok) {
      throw FormatException("PackageInfoRequestFailure");
    }

    final packageJson = jsonDecode(response.body) as Map<String, dynamic>;

    return packageJson['latest']['version'];
  }
}
