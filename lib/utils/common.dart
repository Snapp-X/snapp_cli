// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:io';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:interact/interact.dart';

import 'package:collection/collection.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/process.dart';

import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';
import 'package:process/process.dart';

final RegExp hostnameRegex = RegExp(
    r'^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

final RegExp pathRegex = RegExp(r'^(.+)\/([^\/]+)$');

extension StringExt on String {
  bool get isValidIpAddress => InternetAddress.tryParse(this) != null;

  bool get isValidHostname => hostnameRegex.hasMatch(this);

  bool get isValidPath => pathRegex.hasMatch(this);
}

extension LoggerExt on Logger {
  String get searchIcon => '🔎';
  String get successIcon => Theme.colorfulTheme.successPrefix;
  String get errorIcon => Theme.colorfulTheme.errorPrefix;

  void printSpaces([int count = 1]) {
    for (var i = 0; i < count; i++) {
      print('');
    }
  }

  void printSuccess(String message) {
    printStatus(
      successIcon + Theme.colorfulTheme.messageStyle(message),
    );
  }

  void printFail(String message) {
    printStatus(
      errorIcon + Theme.colorfulTheme.messageStyle(message),
    );
  }
}

extension IpExt on InternetAddress {
  String get ipAddress => address;

  bool get isIpv4 => type == InternetAddressType.IPv4;
  bool get isIpv6 => type == InternetAddressType.IPv6;

  String sshTarget([String username = '']) =>
      (username.isNotEmpty ? '$username@' : '') +
      (type == InternetAddressType.IPv6 ? '[$address]' : address);
}

extension CustomDevicesConfigExt on CustomDeviceConfig {
  /// Try to find the device ip address in the ping command
  String? get tryFindDeviceIp => pingCommand.firstWhereOrNull(
        (element) => InternetAddress.tryParse(element) != null,
      );

  /// Get the device ip address from the ping command
  /// If the ping command doesn't contain an ip address, then throw an error
  String get deviceIp => pingCommand.firstWhere(
        (element) => InternetAddress.tryParse(element) != null,
      );

  /// Get the device username
  /// Check if the username is defined before the ip address in the ping command
  /// sample: username@192.168.1.1
  /// If the ping command doesn't contain a username, then throw an error
  String get deviceUsername {
    // TODO(payam): Complete this method
    throw UnimplementedError();
  }
}

extension ProcessUtilsExt on ProcessUtils {
  Future<RunResult> runWithOutput(
    List<String> cmd, {
    required ProcessManager processManager,
    required Logger logger,
    Duration? timeout,
  }) async {
    while (true) {
      final Process process = await start(cmd);

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();
      final Future<void> stdoutFuture =
          process.stdout.transform<String>(const Utf8Decoder()).listen(
        (event) {
          stdoutBuffer.write(event);
          logger.printStatus(event);
        },
      ).asFuture<void>();
      final Future<void> stderrFuture = process.stderr
          .transform<String>(const Utf8Decoder())
          .listen(stderrBuffer.write)
          .asFuture<void>();

      int? exitCode;
      exitCode = timeout == null
          ? await process.exitCode.then<int?>((int x) => x)
          : await process.exitCode.then<int?>((int x) => x).timeout(timeout,
              onTimeout: () {
              // The process timed out. Kill it.
              processManager.killPid(process.pid);
              return null;
            });

      String stdoutString;
      String stderrString;
      try {
        Future<void> stdioFuture =
            Future.wait<void>(<Future<void>>[stdoutFuture, stderrFuture]);
        if (exitCode == null) {
          // If we had to kill the process for a timeout, only wait a short time
          // for the stdio streams to drain in case killing the process didn't
          // work.
          stdioFuture = stdioFuture.timeout(const Duration(seconds: 1));
        }
        await stdioFuture;
      } on Exception {
        // Ignore errors on the process' stdout and stderr streams. Just capture
        // whatever we got, and use the exit code
      }
      stdoutString = stdoutBuffer.toString();
      stderrString = stderrBuffer.toString();

      final ProcessResult result = ProcessResult(
          process.pid, exitCode ?? -1, stdoutString, stderrString);
      final RunResult runResult = RunResult(result, cmd);

      // If the process did not timeout. We are done.
      if (exitCode != null) {
        logger.printTrace(runResult.toString());

        return runResult;
      }
    }
  }
}
