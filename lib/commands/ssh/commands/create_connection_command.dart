// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/commands/base_command.dart';
import 'package:snapp_cli/service/ssh_service.dart';
import 'package:snapp_cli/utils/common.dart';

/// This command will create a PasswordLess SSH connection to the remote device.
///
/// The user will be prompted for the IP-address and the username of the remote device.
///
class CreateConnectionCommand extends BaseSnappCommand {
  CreateConnectionCommand({
    required super.flutterSdkManager,
  }) : sshService = SshService(flutterSdkManager: flutterSdkManager);

  @override
  String get description =>
      'Create a PasswordLess SSH connection to the remote device';

  @override
  String get name => 'create-connection';

  final SshService sshService;

  @override
  FutureOr<int>? run() async {
    logger.printSpaces();

    logger.printStatus(
      'to create an SSH connection to the remote device, we need an IP address and a username',
    );

    final ip = interaction.readDeviceIp();

    final username = interaction.readDeviceUsername();

    final sshConnectionCreated =
        await sshService.createPasswordLessSshConnection(
      username,
      ip,
    );

    if (sshConnectionCreated) {
      logger.printSuccess('SSH connection to the remote device is created!');
      return 0;
    } else {
      logger.printFail('Could not create SSH connection to the remote device!');
      return 1;
    }
  }
}
