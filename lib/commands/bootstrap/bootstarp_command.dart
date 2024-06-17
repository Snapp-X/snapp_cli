// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/service/custom_device_builder/custom_device_builder.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';
import 'package:snapp_cli/service/setup_device/src/custom_embedder_provider.dart';
import 'package:snapp_cli/service/setup_device/src/install_dependency_provider.dart';
import 'package:snapp_cli/service/ssh_service.dart';

/// Perform a comprehensive setup for a device.(add custom device,ssh connection, install flutter,...)
class BootstrapCommand extends BaseSnappCommand {
  BootstrapCommand({
    required super.flutterSdkManager,
  })  : sshService = SshService(flutterSdkManager: flutterSdkManager),
        remoteControllerService = RemoteControllerService(
          flutterSdkManager: flutterSdkManager,
        );

  final SshService sshService;
  final RemoteControllerService remoteControllerService;

  @override
  final name = 'bootstrap';

  @override
  final description =
      'perform a comprehensive setup for a device.(add custom device,ssh connection, install flutter,...)';

  @override
  Future<int> run() async {
    logger.info('new version');

    logger.spaces();

    logger.info('''
Bootstrap command is a way to setup a device from scratch.
It will add a new device to custom devices, create a ssh connection to the device,
install flutter on the device and finally help you to run your app on the device.

some changes

let's start! \n
    ''');

    logger.spaces();

    DeviceSetup deviceSetup = DeviceSetup(
      steps: [
        /// Receives information about the target device like id, name and type.
        /// Example: Raspberry Pi 4b
        DeviceTypeProvider(customDevicesConfig: customDevicesConfig),

        /// Receives connection information about the target device like ip, port, username.
        DeviceHostProvider(),

        /// Checks if we can have a passwordless ssh connection to the target device.
        /// If not, it will help you to create one.
        /// It will also check if the device is reachable.
        SshConnectionProvider(sshService),

        /// Checks what kind of embedder user wants to use.
        /// Example: Flutter, Flutter-pi ...
        CustomEmbedderProvider(),

        /// Installs dependencies required to run the app on the remote device.
        /// Regarding to the embedder type
        /// for example for Flutter-pi, it will install flutterpi_tool global package
        InstallDependencyProvider(
          remoteControllerService: remoteControllerService,
          flutterSdkManager: flutterSdkManager,
        ),

        /// installs custom embedder chosen by the user.
        AppExecuterProvider(remoteControllerService: remoteControllerService),
      ],
    );

    final deviceContext = await deviceSetup.setup();

    final deviceBuilder = CustomDeviceBuilder.create(
      embedder: deviceContext.embedder!,
      flutterSdkManager: flutterSdkManager,
      hostPlatform: hostPlatform,
    );

    final newDeviceConfig = await deviceBuilder.buildDevice(deviceContext);

    customDevicesConfig.add(newDeviceConfig);

    logger.spaces();

    logger.success(
      'Successfully added custom device to config file at "${customDevicesConfig.configPath}".',
    );

    logger.spaces();

    return 0;
  }
}
