import 'dart:io';
import 'package:flutter_tools/src/base/logger.dart';

final RegExp hostnameRegex = RegExp(
    r'^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$');

final RegExp pathRegex = RegExp(r'^(.+)\/([^\/]+)$');

extension StringExt on String {
  bool get isValidIpAddress => InternetAddress.tryParse(this) != null;

  bool get isValidHostname => hostnameRegex.hasMatch(this);

  bool get isValidPath => pathRegex.hasMatch(this);
}

extension LoggerExt on Logger {
  void printSpaces([int count = 1]) {
    for (var i = 0; i < count; i++) {
      print('');
    }
  }
}
