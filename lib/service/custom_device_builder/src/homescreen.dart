import 'package:snapp_cli/host_runner/host_runner_platform.dart';
import 'package:snapp_cli/service/custom_device_builder/custom_device_builder.dart';
import 'package:snapp_cli/service/setup_device/device_setup.dart';
// ignore: implementation_imports
import 'package:flutter_tools/src/custom_devices/custom_device_config.dart';

// TODO(payam): Support for json config file for ivi-homescreen
class HomescreenCustomDeviceBuilder extends CustomDeviceBuilder {
  const HomescreenCustomDeviceBuilder({
    required super.flutterSdkManager,
    required super.hostPlatform,
  });

  @override
  Future<CustomDeviceConfig> buildDevice(
    final DeviceConfigContext context,
  ) async {
    if (!isContextValid(context)) {
      logger.err('Device context: $context');
      throw Exception("Device setup did not produce a valid configuration.");
    }

    final ipv6 = context.ipv6!;

    final sshTarget = context.sshTarget!;

    final formattedLoopbackIp = context.formattedLoopbackIp!;

    final remoteAppExecuter = context.appExecuterPath!;

    final executeAppCommand = '$remoteAppExecuter --b=/tmp/\${appName}';

    return CustomDeviceConfig(
      id: context.id!,
      label: context.formattedLabel,
      sdkNameAndVersion: context.sdkName!,
      enabled: true,

      // host-platform specific, filled out later
      pingCommand: hostPlatform.pingCommand(
        ipv6: ipv6,
        pingTarget: context.targetIp!.address,
      ),
      pingSuccessRegex: hostPlatform.pingSuccessRegex,
      postBuildCommand: const <String>[],
      installCommand: hostPlatform.commandRunner(
        <String>[
          // Create the necessary directories in the remote machine
          hostPlatform
              .sshCommand(
                ipv6: ipv6,
                sshTarget: sshTarget,
                command: 'mkdir -p /tmp/\${appName}/lib /tmp/\${appName}/data',
              )
              .asString,

          // Copy bundle folder to remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: r'${localPath}',
                dest: '$sshTarget:/tmp/\${appName}/data',
              )
              .asString,

          // Build using flutterpi_tool to be able to use libflutter_engine.so and icudtl.dat
          'flutterpi_tool build --arch=arm64  --debug ;',

          // Copy icudtl.dat to remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: r'${localPath}/icudtl.dat',
                dest: '$sshTarget:/tmp/\${appName}/data',
              )
              .asString,

          // Copy libflutter_engine.so to remote
          hostPlatform
              .scpCommand(
                ipv6: ipv6,
                source: r'${localPath}/libflutter_engine.so',
                dest: '$sshTarget:/tmp/\${appName}/lib',
                lastCommand: true,
              )
              .asString,
        ],
      ),
      // just uninstall app by removing the /tmp/${appName} directory on the remote
      uninstallCommand: hostPlatform.sshCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        // TODO(payam): take care of removing folder after killing the process
        command:
            'PID=\$(ps aux | grep \'$executeAppCommand\' | grep -v grep | awk \'{print \$2}\'); [ -n "\$PID" ] && kill \$PID && echo "Process $remoteAppExecuter /tmp/\${appName} (PID: \$PID) has been killed." || echo "Process not found.";',
        lastCommand: true,
      ),
      // run the app on the remote
      runDebugCommand: hostPlatform.sshCommand(
        ipv6: ipv6,
        sshTarget: sshTarget,
        lastCommand: true,
        command: "WAYLAND_DISPLAY=\"wayland-1\" $executeAppCommand &",
      ),
      forwardPortCommand: <String>[
        'ssh',
        '-o',
        'BatchMode=yes',
        '-o',
        'ExitOnForwardFailure=yes',
        if (ipv6) '-6',
        '-L',
        '$formattedLoopbackIp:\${hostPort}:$formattedLoopbackIp:\${devicePort}',
        sshTarget,
        "echo 'Port forwarding success'; read",
      ],
      forwardPortSuccessRegex: RegExp('Port forwarding success'),
      screenshotCommand: null,
    );
  }
}
