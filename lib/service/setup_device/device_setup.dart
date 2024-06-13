import 'package:snapp_cli/service/setup_device/device_config_context.dart';

export 'package:snapp_cli/service/logger_service.dart';
export 'package:snapp_cli/commands/base_command.dart';

export 'src/device_host_provider.dart';
export 'src/device_type_provider.dart';
export 'src/app_executer_provider.dart';
export 'src/ssh_connection_provider.dart';

export 'package:snapp_cli/service/setup_device/device_config_context.dart';

/// The `DeviceSetup` class orchestrates a series of setup steps for configuring a [DeviceConfigContext].
/// It follows the Chain of Responsibility pattern, where each setup step processes the
/// device context and passes it to the next step in the sequence.
///
/// Example usage:
/// ```dart
/// List<DeviceSetupStep> steps = [
///   Step1(),
///   Step2(),
///   Step3(),
/// ];
///
/// DeviceSetup deviceSetup = DeviceSetup(steps: steps);
/// DeviceConfigContext context = await deviceSetup.setup();
/// ```
///
/// In this example, `Step1`, `Step2`, and `Step3` are custom implementations of `DeviceSetupStep`.
/// Each step modifies the `DeviceConfigContext` and passes it to the next step in the sequence.
class DeviceSetup {
  DeviceSetup({
    required List<DeviceSetupStep> steps,
  })  : assert(steps.isNotEmpty, 'steps list cannot be empty'),
        _chain = steps.reduce((a, b) {
          a.setNext(b);
          return b;
        });

  final DeviceSetupStep _chain;

  /// Starts the setup process by passing the [context] to the first handler in the chain.
  ///
  /// If no context is provided, the default context `DeviceSetupContext.empty` is used.
  ///
  /// Returns a `Future<DeviceSetupContext>` representing the final context after all steps
  /// have processed it.
  ///
  /// The [context] parameter is the initial setup context to be processed. If not provided,
  /// the default empty context is used.
  ///
  /// Example usage with a custom context:
  /// ```dart
  /// DeviceSetupContext initialContext = DeviceSetupContext(id: '123', label: 'My Device');
  /// DeviceSetupContext result = await deviceSetup.setup(customContext);
  /// ```
  Future<DeviceConfigContext> setup(
      [DeviceConfigContext context = DeviceConfigContext.empty]) {
    return _chain.handle(context);
  }
}

/// The `DeviceSetupStep` class represents a single step in the device setup process.
/// It is an abstract class that defines the interface for processing a `DeviceConfigContext`.
///
/// Each concrete subclass must implement the `execute` method to perform specific actions
/// on the provided context.
///
/// The `DeviceSetupStep` class supports chaining by holding a reference to the next step,
/// allowing a sequence of steps to be linked together.
///
/// Example subclass implementation:
/// ```dart
/// class Step1 extends DeviceSetupStep {
///   @override
///   Future<DeviceConfigContext> execute(DeviceConfigContext context) async {
///     // Perform specific actions to modify the context
///     // For example, set some properties or check conditions
///     return context.copyWith(...);
///   }
/// }
/// ```
abstract class DeviceSetupStep {
  DeviceSetupStep? nextHandler;

  void setNext(DeviceSetupStep handler) {
    nextHandler = handler;
  }

  Future<DeviceConfigContext> execute(DeviceConfigContext context);

  Future<DeviceConfigContext> handle(DeviceConfigContext context) async {
    final DeviceConfigContext updatedContext = await execute(context);

    if (nextHandler != null) {
      return nextHandler!.handle(updatedContext);
    }

    return updatedContext;
  }
}
