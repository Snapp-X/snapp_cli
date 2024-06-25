// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:snapp_cli/service/custom_device_builder/custom_device_builder.dart';
import 'package:snapp_cli/service/remote_controller_service.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';
import 'package:snapp_cli/service/setup_device/src/custom_embedder_provider.dart';
import 'package:snapp_cli/service/setup_device/src/install_dependency_provider.dart';
import 'package:snapp_cli/service/ssh_service.dart';

/// Add a new raspberry device to the Flutter SDK custom devices
class AddCommand extends BaseSnappCommand {
  AddCommand({
    required super.flutterSdkManager,
  })  : sshService = SshService(flutterSdkManager: flutterSdkManager),
        remoteControllerService = RemoteControllerService(
          flutterSdkManager: flutterSdkManager,
        );

  final SshService sshService;
  final RemoteControllerService remoteControllerService;

  @override
  final name = 'add';

  @override
  final description = 'add a new device to custom devices manually.';

  @override
  Future<int> run() async {
    logger.spaces();

    logger.warn('''
Add command is a way to add a new device to custom devices manually.

We recommend you to use the bootstrap command to setup a device from scratch.

You need to provide specific PATH to the custom embedder you want to use.
    ''');

    logger.spaces();

    DeviceSetup deviceSetup = DeviceSetup(
      steps: [
        /// Receives information about the target device like id, name and type.
        /// Example: Raspberry Pi 4b
        DeviceTypeProvider(customDevicesConfig: customDevicesConfig),

        /// Receives connection information about the target device like ip, port, username.
        DeviceHostProvider(),

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
        ManualAppExecuterProvider(),
      ],
    );

    final deviceContext = (await deviceSetup.setup()).copyWith(
      // We need to set this to true because we are not setting up passwordless ssh connection in this command.
      remoteHasSshConnection: true,
    );

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
