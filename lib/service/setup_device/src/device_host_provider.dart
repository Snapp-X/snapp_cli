import 'package:snapp_cli/service/setup_device/device_setup.dart';

class DeviceHostProvider extends DeviceSetupStep {
  @override
  Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
    // get remote device ip and username from the user
    logger.spaces();

    logger.info('to setup a new device, we need an IP address and a username.');

    final targetIp = interaction.readDeviceIp(
        description:
            'Please enter the IP-address of the device. (example: 192.168.1.101)');

    final username = interaction.readDeviceUsername(
      description:
          'Please enter the username used for ssh-ing into the remote device. (example: pi)',
    );

    return context.copyWith(
      targetIp: targetIp,
      username: username,
    );
  }
}
