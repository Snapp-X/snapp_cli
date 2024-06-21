<!-- <p align="center">
    <a href="https://www.snappembedded.io/"><img src="https://img.shields.io/badge/made_by-snapp_embedded-blue" alt="Snapp Embedded"></a>
    <br>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/flutter-platform/snapp_cli" alt="Platforms"></a>
    <br>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://img.shields.io/pub/v/snapp_cli?logo=dart&logoColor=white" alt="Pub Version"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/points/snapp_cli" alt="Pub points"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/likes/snapp_cli" alt="Pub Likes"></a>
    <a href="https://pub.dev/packages/snapp_cli"><img src="https://badgen.net/pub/popularity/snapp_cli" alt="Pub popularity"></a>
    <br>    
    <a href="https://github.com/Snapp-Embedded/snapp_cli/pulls"><img src="https://img.shields.io/github/issues-pr/Snapp-Embedded/snapp_cli" alt="Repo PRs"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/issues?q=is%3Aissue+is%3Aopen"><img src="https://img.shields.io/github/issues/Snapp-Embedded/snapp_cli" alt="Repo issues"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli"><img src="https://img.shields.io/github/stars/Snapp-Embedded/snapp_cli?style=social" alt="Repo stars"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/graphs/contributors"><img src="https://badgen.net/github/contributors/Snapp-Embedded/snapp_cli" alt="Contributors"></a>
    <a href="https://github.com/Snapp-Embedded/snapp_cli/blob/main/LICENSE"><img src="https://badgen.net/github/license/Snapp-Embedded/snapp_cli" alt="License"></a>
    <br>       
</p> -->
# Snapp CLI
#### Power Up Your Raspberry Pi for Flutter


## What is snapp_cli?

Imagine You have a **Raspberry Pi** sitting on your desk or tucked away in a drawer, collecting dust. You bought it with grand ideas of developing **Flutter** apps on it, but the thought of setting it up for development has always seemed too complicated. Now, picture a tool that makes this process simple and effortless – that’s **Snapp CLI**. 🚀

**Snapp CLI** allows you to control everything from your laptop 💻. Here’s how it simplifies your development process:

1. 🔗 **Effortless Connection:** Snapp CLI sets up a secure, passwordless SSH link from your laptop to your Raspberry Pi, so you can manage it without direct interaction.

2. 🔧 **Automated Installation:** Snapp CLI automates the installation of Flutter and all necessary dependencies on your Raspberry Pi. You run Snapp CLI from your laptop, and it handles everything remotely. But that's not all – Snapp CLI also supports custom embedders like Flutter-pi.

3. ⚙️ **Custom Device Configuration:** Snapp CLI configures your Raspberry Pi to appear as a custom device in your IDE. You can easily select it and run your Flutter apps, just like you would on a phone or emulator.

4. 🛠️ **Seamless Remote Development:** Develop and debug your Flutter apps directly from your laptop. Snapp CLI enables hot reload, restart, and access to DevTools, so you can run and test apps on your Raspberry Pi with all the tools you need for smooth and efficient remote development.

**In essence**, Snapp CLI transforms your idle Raspberry Pi into a powerful Flutter development platform, all managed from your laptop. Whether you're new to Flutter or an experienced developer, Snapp CLI makes remote development simple and effective.

## Installation

Snapp CLI is a Dart-based command-line tool. If you already have Flutter installed on your laptop, getting Snapp CLI up and running is quick and easy. Just run the following command in your terminal:

``` bash
dart pub global activate snapp_cli
```

Make sure that system cache bin directory is added to your system's PATH to use snapp_cli globally. follow this link for more information: [Running a script from your PATH](https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path "Running a script from your PATH")

## Usage

#### Single Command Setup - **Bootstrap**

Bootstrap command is a way to setup a device from scratch.
It will add a new device to custom devices, create a ssh connection to the device,
install flutter on the device and finally help you to run your app on the device.

```bash
$ snapp_cli bootstrap
```

#### Device Management

- **List Devices:** Display all connected/embedded devices.
    ```bash
    $ snapp_cli devices list
    ```
- **Add a Device:** Add a new device to the Flutter SDK.
   ```bash
   $ snapp_cli devices add 
   ```
- **Delete a Device:** Remove a device from the Flutter SDK.
    ```bash
    $ snapp_cli devices delete
    ```
- **Update Device IP:** Update the IP address of a device.
    ```bash
    $ snapp_cli devices update-ip
    ```
- **Install Flutter:** Install Flutter directly onto a device.
    ```bash
    $ snapp_cli devices install-flutter
    ```

#### SSH Connection

- **Create SSH Connection:** Create a passwordless SSH connection to a device.
    ```bash
    $ snapp_cli ssh create-connection
    ```
- **Test SSH Connection:** Test a passwordless SSH connection to a device.
    ```bash
    $ snapp_cli ssh test-connection
    ```

------------------------------------

Each command has specific options and usage, which you can explore further by running `snapp_cli --help` or `snapp_cli <command> --help`.

## Troubleshooting

### Running Commands in Verbose Mode

If you encounter any issues while using the `snapp_cli` tool, you can run the commands in verbose mode to obtain more detailed information about the error. To do this, simply add the `-v` flag to your command. For example:


```bash
$ snapp_cli bootstrap -v
```

### SSH Connection Issues

Sometimes, you may face difficulties establishing an SSH connection to a device due to various reasons, such as an incorrect IP address, username, password, or SSH key. To verify whether the SSH connection is functioning correctly, you can execute the `snapp_cli ssh test-connection` command. If the connection fails, attempt to establish a new connection using the `snapp_cli ssh create-connection` command.

If you still cannot establish an SSH connection, it may be necessary to review the SSH configurations on both your host (e.g., your PC) and the remote device (e.g., Raspberry Pi).

However, be cautious: if you have any other SSH connections to your remote device or to other devices, using the following commands will remove them.


#### Host Device - Your PC
* Clear the `.snapp_cli` directory: 
    ``` bash 
    rm -r ~/.snapp_cli
    ```
* Clear the known hosts file: 
    ``` bash 
    ssh-keygen -R yourIpAddress
    ```
* Clear the ssh-agent saved keys:  
    ``` bash 
    ssh-add -D
    ```

#### Remote Device - Raspberry Pi
Connect to your remote device via a simple SSH connection:

``` bash 
ssh [username]@[ipAddress]
```

After successfully connecting to your remote device, remove the `.ssh` folder that contains the SSH keys:

``` bash 
rm -r ~/.ssh
```

### Notes:
* Ensure you replace yourIpAddress with the actual IP address of your device.
* Be explicit about replacing placeholders like username@ipAddress with the appropriate user and IP address for the Raspberry Pi.

### Manually Editing `flutter_custom_devices.json`

In some cases, you may need to manually edit the `flutter_custom_devices.json` file, which stores the configurations for custom devices. Here are the steps to follow if you encounter this situation:

1. **Locate the `flutter_custom_devices.json` File:**
   - The location of the `flutter_custom_devices.json` file can vary depending on the operating system you are using. You can find it with the `snapp_cli list` command.

2. **Backup the File:**
   - Before making any manual changes, it's a good practice to create a backup of the `flutter_custom_devices.json` file in case something goes wrong.

3. **Edit the JSON File:**
   - Use a text editor to open the `flutter_custom_devices.json` file. You can make changes to the device configurations as needed. Ensure that the JSON structure is valid; any syntax errors can cause issues.

4. **Test the Configuration:**
   - To test the changed configuration you need to run your app again.


Keep in mind that manually editing the `flutter_custom_devices.json` file should be done with caution, as incorrect changes can lead to configuration issues. It's recommended to use the CLI tool to add, update, or delete custom devices whenever possible.


## Contributing

If you encounter any issues with this package or have suggestions for improvements, please [open an issue](https://github.com/Snapp-Embedded/snapp_cli/issues). You are welcome to contribute to the development of this project by forking the repository and submitting pull requests.

## License

This project is licensed under the MIT License

