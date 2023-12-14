// ignore_for_file: implementation_imports

import 'package:flutter_tools/src/base/logger.dart';
import 'package:interact/interact.dart';

final RegExp hostnameRegex = RegExp(
    r'^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

final RegExp pathRegex = RegExp(r'^(.+)\/([^\/]+)$');

extension LoggerExt on Logger {
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
