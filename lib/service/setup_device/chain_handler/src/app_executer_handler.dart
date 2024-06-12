import 'package:snapp_cli/service/setup_device/chain_handler/device_setup_handler.dart';

class AppExecuterHandler extends DeviceSetupHandler {
  @override
  Future<DeviceSetupContext> execute(DeviceSetupContext context) async {
    logger.spaces();

    logger.info(
      'We need the exact path of your flutter command line tools on the remote device. '
      'We will use this path to run flutter commands on the remote device like "flutter build linux --debug". \n',
    );

    return context.copyWith();
  }
}
