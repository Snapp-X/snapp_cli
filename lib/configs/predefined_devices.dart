// ignore_for_file: implementation_imports

import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

final Map<String, CustomDeviceConfig> predefinedDevices = Map.unmodifiable(
  {
    raspberryPi5.label: raspberryPi5,
    raspberryPi4B.label: raspberryPi4B,
    raspberryPi4.label: raspberryPi4,
    raspberryPi3.label: raspberryPi3,
    raspberryZero.label: raspberryZero,
    raspberryZero2W.label: raspberryZero2W,
  },
);

const _defaultConfig = CustomDeviceConfig(
  id: '',
  label: '',
  sdkNameAndVersion: '',
  enabled: true,
  pingCommand: <String>[],
  postBuildCommand: <String>[],
  installCommand: <String>[],
  uninstallCommand: <String>[],
  runDebugCommand: <String>[],
  screenshotCommand: null,
);

CustomDeviceConfig raspberryPi5 = _defaultConfig.copyWith(
  id: 'pi-5',
  label: 'Raspberry Pi 5',
  sdkNameAndVersion: 'Raspberry Pi 5',
);

CustomDeviceConfig raspberryPi4B = _defaultConfig.copyWith(
  id: 'pi-4b',
  label: 'Raspberry Pi 4 Model B',
  sdkNameAndVersion: 'Raspberry Pi 4 Model B',
);

CustomDeviceConfig raspberryPi4 = _defaultConfig.copyWith(
  id: 'pi-4',
  label: 'Raspberry Pi 4',
  sdkNameAndVersion: 'Raspberry Pi 4',
);

CustomDeviceConfig raspberryPi3 = _defaultConfig.copyWith(
  id: 'pi-3',
  label: 'Raspberry Pi 3',
  sdkNameAndVersion: 'Raspberry Pi 3',
);

CustomDeviceConfig raspberryZero = _defaultConfig.copyWith(
  id: 'pi-zero',
  label: 'Raspberry Pi Zero',
  sdkNameAndVersion: 'Raspberry Pi Zero',
);

CustomDeviceConfig raspberryZero2W = _defaultConfig.copyWith(
  id: 'pi-zero2w',
  label: 'Raspberry Pi Zero 2 W',
  sdkNameAndVersion: 'Raspberry Pi Zero 2 W',
);
