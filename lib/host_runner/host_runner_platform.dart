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

  String get homePath;

  List<String> commandRunner(List<String> commands);

  List<String> scpCommand({
    required bool ipv6,
    required String source,
    required String dest,
    bool addHostToKnownHosts = false,
    bool lastCommand = false,
    String endCharacter = ';',
  }) =>
      [
        'scp',
        '-r',
        '-o',
        'BatchMode=yes',
        if (addHostToKnownHosts) ...[
          '-o',
          'StrictHostKeyChecking=accept-new',
        ],
        if (ipv6) '-6',
        source,
        '$dest ${lastCommand ? '' : endCharacter}',
      ];

  List<String> sshCommand({
    required bool ipv6,
    required String sshTarget,
    required String command,
    bool addHostToKnownHosts = false,
    bool lastCommand = false,
    String endCharacter = ';',
  }) =>
      [
        'ssh',
        '-o',
        'BatchMode=yes',
        if (addHostToKnownHosts) ...[
          '-o',
          'StrictHostKeyChecking=accept-new',
        ],
        if (ipv6) '-6',
        sshTarget,
        '$command ${lastCommand ? '' : endCharacter}',
      ];

  List<String> sshMultiCommand({
    required bool ipv6,
    required String sshTarget,
    required List<String> commands,
    bool addHostToKnownHosts = false,
    String endCharacter = ';',
  }) =>
      [
        'ssh',
        '-o',
        'BatchMode=yes',
        if (addHostToKnownHosts) ...[
          '-o',
          'StrictHostKeyChecking=accept-new',
        ],
        if (ipv6) '-6',
        sshTarget,
        ...commands.map(
            (e) => e.trim().endsWith(' $endCharacter') ? e : '$e$endCharacter'),
      ];

  List<String> pingCommand({
    required bool ipv6,
    required String pingTarget,
  });

  RegExp? get pingSuccessRegex => null;

  List<String> generateSshKeyCommand({required String filePath}) => [
        'ssh-keygen',
        '-t',
        'rsa',
        '-b',
        '2048',
        '-f',
        filePath,
        '-q',
        '-N',
        '',
      ];

  List<String> addSshKeyToAgent({required String filePath}) => commandRunner([
        'ssh-add',
        filePath,
      ]);

  List<String> copySshKeyCommand({
    required String filePath,
    required bool ipv6,
    required String targetDevice,
  });

  /// This command is used to compress a folder
  ///
  /// since we can use tar command in powershell in windows 10 and above
  /// we can use the same command for windows, linux and macos
  List<String> compressCommand({
    String compressedFileName = 'archive.tar.gz',
    String source = '.',
    bool lastCommand = false,
    List<String> exclude = const [],
  }) =>
      [
        'tar',
        '-czvf',
        compressedFileName,
        if (exclude.isNotEmpty) ...exclude.map((e) => '--exclude=\'$e\''),
        source,
        lastCommand ? '' : ';',
      ];

  /// This command is used to compress the current project
  List<String> compressCurrentProjectCommand({
    required String compressedFileName,
  }) =>
      compressCommand(
        compressedFileName: compressedFileName,
        exclude: [
          '.dart_tool',
          '.idea',
          'android',
          'build',
          'ios',
          'macos',
          'test',
          'web',
          'windows',
        ],
      );

  List<String> deleteFile({
    required String target,
    bool lastCommand = false,
  });
}

class WindowsHostRunnerPlatform extends HostRunnerPlatform {
  const WindowsHostRunnerPlatform(super.platform);

  @override
  List<String> get terminalCommandRunner => ['powershell', '-c'];

  @override
  String get currentSourcePath => '.\\';

  @override
  String get homePath => platform.environment['UserProfile']!;

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

  @override
  List<String> copySshKeyCommand({
    required String filePath,
    required bool ipv6,
    required String targetDevice,
  }) {
    return commandRunner([
      'type $filePath |',
      'ssh $targetDevice "cat >> .ssh/authorized_keys"'
    ]);
  }

  @override
  List<String> deleteFile({
    required String target,
    bool lastCommand = false,
  }) =>
      [
        'del',
        target,
        lastCommand ? '' : ';',
      ];
}

class UnixHostRunnerPlatform extends HostRunnerPlatform {
  const UnixHostRunnerPlatform(super.platform);

  @override
  List<String> get terminalCommandRunner => ['bash', '-c'];

  @override
  String get currentSourcePath => './';

  @override
  String get homePath => platform.environment['HOME']!;

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
        '-W',
        '400',
        pingTarget,
      ];

  @override
  List<String> copySshKeyCommand({
    required String filePath,
    required bool ipv6,
    required String targetDevice,
  }) {
    return [
      'ssh-copy-id',
      if (ipv6) '-6',
      '-f',
      '-i',
      filePath,
      targetDevice,
    ];
  }

  @override
  List<String> deleteFile({required String target, bool lastCommand = false}) =>
      [
        'rm',
        target,
        lastCommand ? '' : ';',
      ];
}

extension StringListExtension on List<String> {
  String get asString => join(' ');
}
