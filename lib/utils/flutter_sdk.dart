// ignore_for_file: implementation_imports

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context_runner.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

/// singleton class to manage flutter sdk
/// responsible for find the flutter path and initialize the flutter sdk
class FlutterSdkManager {
  static const FlutterSdkManager _instance = FlutterSdkManager._();

  const FlutterSdkManager._();

  factory FlutterSdkManager() => _instance;

  bool get isInitialized => Cache.flutterRoot != null;

  /// get the flutter sdk file system
  FileSystem get flutterSdkFileSystem {
    if (!isInitialized) {
      throw Exception(
        'Flutter SDK is not initialized: use initialize() method first',
      );
    }

    return globals.localFileSystem;
  }

  /// initialize the flutter sdk
  Future<void> initialize() async {
    if (isInitialized) {
      print('flutter is located at: ${Cache.flutterRoot}');
      return;
    }

    final flutterRoot = await _getFlutterRootDirectory();

    final flutterDirectory = LocalFileSystem()..currentDirectory = flutterRoot;

    Cache.flutterRoot = Cache.defaultFlutterRoot(
      platform: const LocalPlatform(),
      fileSystem: flutterDirectory,
      userMessages: UserMessages(),
    );

    print('flutter is located at: ${Cache.flutterRoot}');
  }

  Future<bool> isCustomDevicesConfigAvailable() async {
    return runInContext<bool>(() {
      try {
        final customDevicesConfig = globals.customDevicesConfig;

        final io.File configFile =
            flutterSdkFileSystem.file(customDevicesConfig.configPath);

        if (configFile.existsSync()) {
          return true;
        }

        return false;

      } catch (e) {

        return false;
      }
    });
  }

  /// get the flutter sdk path
  Future<String> _getFlutterRootDirectory() async {
    final pkgConfig = await findPackageConfigUri(io.Platform.script);
    pkgConfig!;

    final flutterToolsPath =
        pkgConfig.resolve(Uri.parse('package:flutter_tools/'))!.toFilePath();

    const dirname = path.dirname;

    return dirname(dirname(dirname(flutterToolsPath)));
  }
}
