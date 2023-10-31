// ignore: implementation_imports
import 'package:flutter_tools/src/base/platform.dart';

/// This class is used to make the commands platform specific
/// for example, the ping command is different on windows and linux
///
/// only supports windows, linux and macos
///
abstract class HostRunnerPlatform {
  const HostRunnerPlatform(this.platform);

  factory HostRunnerPlatform.build(Platform host) {
    if (host.isWindows) {
      return WindowsHostRunnerPlatform(host);
    } else if (host.isLinux || host.isMacOS) {
      return UnixHostRunnerPlatform(host);
    }

    throw UnsupportedError('Unsupported operating system');
  }

  final Platform platform;

  List<String> get terminalCommandRunner;

  String get currentSourcePath;

  List<String> commandRunner(List<String> commands);

  List<String> scpCommand({
    required bool ipv6,
    required String source,
    required String dest,
    bool lastCommand = false,
  }) =>
      [
        'scp',
        '-r',
        '-o',
        'BatchMode=yes',
        if (ipv6) '-6',
        source,
        '$dest ${lastCommand ? '' : ';'}',
      ];

  List<String> sshCommand({
    required bool ipv6,
    required String sshTarget,
    required String command,
    bool lastCommand = false,
  }) =>
      [
        'ssh',
        '-o',
        'BatchMode=yes',
        if (ipv6) '-6',
        sshTarget,
        '$command ${lastCommand ? '' : ';'}',
      ];

  List<String> sshMultiCommand({
    required bool ipv6,
    required String sshTarget,
    required List<String> commands,
  }) =>
      [
        'ssh',
        '-o',
        'BatchMode=yes',
        if (ipv6) '-6',
        sshTarget,
        ...commands.map((e) => e.trim().endsWith(' ;') ? e : '$e;'),
      ];

  List<String> pingCommand({
    required bool ipv6,
    required String pingTarget,
  });

  RegExp? get pingSuccessRegex => null;
}

class WindowsHostRunnerPlatform extends HostRunnerPlatform {
  const WindowsHostRunnerPlatform(super.platform);

  @override
  List<String> get terminalCommandRunner => ['powershell', '-c'];

  @override
  String get currentSourcePath => '.\\';

  @override
  List<String> commandRunner(List<String> commands) {
    return <String>[
      ...terminalCommandRunner,
      ...commands,
    ];
  }

  @override
  List<String> pingCommand({required bool ipv6, required String pingTarget}) =>
      <String>[
        'ping',
        if (ipv6) '-6',
        '-n',
        '1',
        '-w',
        '500',
        pingTarget,
      ];

  @override
  RegExp? get pingSuccessRegex => RegExp(r'[<=]\d+ms');
}

class UnixHostRunnerPlatform extends HostRunnerPlatform {
  const UnixHostRunnerPlatform(super.platform);

  @override
  List<String> get terminalCommandRunner => ['bash', '-c'];

  @override
  String get currentSourcePath => './';

  @override
  List<String> commandRunner(List<String> commands) {
    return <String>[
      ...terminalCommandRunner,
      commands.join(' '),
    ];
  }

  @override
  List<String> pingCommand({required bool ipv6, required String pingTarget}) =>
      <String>[
        'ping',
        if (ipv6) '-6',
        '-c',
        '1',
        '-w',
        '1',
        pingTarget,
      ];
}

extension StringListExtension on List<String> {
  String get asString => join(' ');
}
