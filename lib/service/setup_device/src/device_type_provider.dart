import 'package:snapp_cli/configs/predefined_devices.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';
// ignore: implementation_imports
import 'package:flutter_tools/src/custom_devices/custom_devices_config.dart';

class DeviceTypeProvider extends DeviceSetupStep {
  DeviceTypeProvider({required this.customDevicesConfig});

  final CustomDevicesConfig customDevicesConfig;

  @override
  Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
    final addCommandOptions = [
      'Express (recommended)',
      'Custom',
    ];

    final commandIndex = interaction.selectIndex(
      'Please select the type of device you want to setup.',
      options: addCommandOptions,
    );

    if (commandIndex == 0) {
      return _setupPredefinedDevice(context);
    }

    return _setupCustomDevice(context);
  }

  Future<DeviceConfigContext> _setupPredefinedDevice(
      DeviceConfigContext context) async {
    logger.spaces();

    final deviceKey = interaction.select(
      'Select your device',
      options: predefinedDevices.keys.toList(),
    );

    var predefinedDeviceConfig = predefinedDevices[deviceKey];

    if (predefinedDeviceConfig == null) {
      throwToolExit(
          'Something went wrong while trying to setup predefined $deviceKey device.');
    }

    /// check if the device id already exists in the config file
    /// update the id if it
    if (_isDuplicatedDeviceId(predefinedDeviceConfig.id)) {
      predefinedDeviceConfig = predefinedDeviceConfig.copyWith(
        id: _suggestIdForDuplicatedDeviceId(predefinedDeviceConfig.id),
      );
    }

    return context.copyWith(
      id: predefinedDeviceConfig.id,
      label: predefinedDeviceConfig.label,
    );
  }

  Future<DeviceConfigContext> _setupCustomDevice(
      DeviceConfigContext context) async {
    final id = interaction.readDeviceId(customDevicesConfig);
    final label = interaction.readDeviceLabel();

    return context.copyWith(id: id, label: label);
  }

  bool _isDuplicatedDeviceId(String s) {
    return customDevicesConfig.devices.any((element) => element.id == s);
  }

  String _suggestIdForDuplicatedDeviceId(String s) {
    int i = 1;

    while (_isDuplicatedDeviceId('$s-$i')) {
      i++;
    }

    return '$s-$i';
  }
}
