## snapp\_cli

`snapp_cli` is a Dart command-line tool designed to simplify the process of adding custom devices to the Flutter SDK. With this tool, you can configure and run your Flutter apps on non-standard or remote devices, such as a Raspberry Pi, while maintaining essential Flutter features like hot reload and hot restart.

## Preconditions

Before using `snapp_cli`, please ensure that you meet the following preconditions:

-   **Secure SSH Connection:** You should have a secure SSH connection between your host machine and the remote device, established using SSH keys. Password-based SSH connections are not supported.
    - Check out this [guide](https://pimylifeup.com/raspberry-pi-ssh-keys/) for more information on setting up SSH keys.
-   **Flutter Linux Configuration:** Make sure that Flutter's Linux configuration is enabled on your host machine. You can enable it using the following command:

``` bash
flutter config --enable-linux-desktop
```

- **Flutter Custom Devices Configuration:** Ensure that Flutter's custom-devices configuration is also enabled on your host machine. You can enable it with the following command:

``` bash
flutter config --enable-custom-devices
```
- **Flutter Installation on Remote Device:** Flutter should be installed and configured on your remote device. If you are using a Raspberry Pi, you can use the `snapp_installer` to install Flutter on your device.

- **Know the Path to Flutter on Remote Device:** You should know the exact path to the Flutter installation on your remote device. You can find the path using the following command on the remote device:

``` bash
which flutter
```
Ensure that you've met these preconditions to use snapp_cli effectively with custom devices and remote debugging.

## Commands

`snapp_cli` provides the following commands:

- **add:** Add a custom device configuration.
   - Use the `add` command to add and configure a custom device for the Flutter SDK. You can specify the device name, IP address, and other information to customize your development environment.

- **delete:** Delete a custom device configuration.
   - The `delete` command allows you to remove a previously configured custom device from your settings.

- **list:** List configured custom devices.
   - The `list` command displays a list of all the custom devices that is available on the flutter SDK.

- **update-ip:** Update the IP address of a custom device.
   - The `update-ip` command is used to modify the IP address of an existing custom device configuration. This is useful when the device's IP address changes, such as due to DHCP, and you need to update your settings. Example:
``` bash
snapp_cli update-ip -d raspberry -i 192.168.115.92 
```


------------


Each command has specific options and usage, which you can explore further by running `snapp_cli --help` or `snapp_cli <command> --help`.

## add Command

The `add` command allows you to add and configure a custom device for the Flutter SDK. When you run this command, `snapp_cli` will prompt you with a series of questions to gather the necessary information for custom device configuration.


Use this command to interactively specify the settings for a custom device that you want to use for your Flutter development. The questions will cover details such as:

- SSH Connection Details: You'll be asked for the IP address of your remote device and the username for the SSH connection.

- Path to Flutter on the Remote Device: You'll be prompted to provide the exact path to the Flutter installation on your remote device.

#### Usage 
To add a custom device, simply run the following command:

```
snapp_cli add
```

snapp_cli will then guide you through the process, prompting you with questions to gather the necessary information for your custom device configuration. Follow the on-screen prompts to complete the configuration.
