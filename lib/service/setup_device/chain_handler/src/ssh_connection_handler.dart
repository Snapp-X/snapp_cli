import 'package:snapp_cli/service/setup_device/chain_handler/device_setup_handler.dart';
import 'package:snapp_cli/service/ssh_service.dart';

class SshConnectionHandler extends DeviceSetupHandler {
  final SshService sshService;

  SshConnectionHandler(this.sshService);

  @override
  Future<DeviceSetupContext> execute(DeviceSetupContext context) async {
    if (context.targetIp == null || context.username == null) {
      throw Exception('Missing target IP or username for SSH connection.');
    }

    logger.spaces();

    final username = context.username!;
    final targetIp = context.targetIp!;

    bool remoteHasSshConnection =
        await sshService.testPasswordLessSshConnection(username, targetIp);

    if (!remoteHasSshConnection) {
      logger.fail(
        'could not establish a password-less ssh connection to the remote device. \n',
      );

      logger.info(
          'We can create a ssh connection with the remote device, do you want to try it?');

      final continueWithoutPing = interaction.confirm(
        'Create a ssh connection?',
        defaultValue: true,
      );

      if (!continueWithoutPing) {
        logger.spaces();
        throwToolExit(
          'Check your ssh connection with the remote device and try again.',
          exitCode: 1,
        );
      }

      logger.spaces();

      final sshConnectionCreated =
          await sshService.createPasswordLessSshConnection(username, targetIp);

      if (sshConnectionCreated) {
        logger.success('SSH connection to the remote device is created!');
        remoteHasSshConnection = true;
      } else {
        logger.fail('Could not create SSH connection to the remote device!');
        throwToolExit(' SSH connection failed.', exitCode: 1);
      }
    }

    return context.copyWith(remoteHasSshConnection: remoteHasSshConnection);
  }
}
