// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/service/ssh_service.dart';

/// This command will create a PasswordLess SSH connection to the remote device.
///
/// The user will be prompted for the IP-address and the username of the remote device.
///
class CreateConnectionCommand extends BaseSnappCommand {
  CreateConnectionCommand({
    required super.flutterSdkManager,
  }) : _sshService = SshService(flutterSdkManager: flutterSdkManager);

  @override
  String get description =>
      'Create an PasswordLess SSH connection to the remote device';

  @override
  String get name => 'create-connection';

  final SshService _sshService;

  @override
  FutureOr<int>? run() async {
    final (ip, username) = getRemoteIpAndUsername(
      message:
          'to create an SSH connection to the remote device, we need an IP address and a username',
    );

    final sshConnectionCreated =
        await _sshService.createPasswordLessSshConnection(
      username,
      ip,
    );

    return sshConnectionCreated ? 0 : 1;
  }
}
