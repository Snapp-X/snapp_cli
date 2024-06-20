import 'package:interact_cli/interact_cli.dart' as interact_cli;
import 'package:mason_logger/mason_logger.dart' as mason_logger;
import 'package:snapp_cli/service/logger_service.dart';

abstract class Actor {
  const Actor._({required this.logger});

  factory Actor.cli({required LoggerService logger}) =>
      InteractCliActor(logger: logger);

  factory Actor.mason({
    required LoggerService logger,
    mason_logger.Logger? mason,
  }) =>
      MasonActor(logger: logger, mason: mason);

  final LoggerService logger;

  bool confirm({
    required String prompt,
    bool? defaultValue,
  });

  String input({String prompt = 'input', Object? defaultValue});
  String inputWithValidation({
    String prompt = 'input',
    required String? Function(String) validator,
    Object? defaultValue,
  });

  String select(
    String message, {
    required List<String> options,
  });

  int selectIndex(
    String prompt, {
    required List<String> options,
  }) {
    final selected = select(prompt, options: options);
    return options.indexOf(selected);
  }
}

class InteractCliActor extends Actor {
  const InteractCliActor({required super.logger}) : super._();

  @override
  bool confirm({
    required String prompt,
    bool? defaultValue,
  }) {
    return interact_cli.Confirm(
      prompt: prompt,
      defaultValue: defaultValue,
      waitForNewLine: true,
    ).interact();
  }

  @override
  String input({String prompt = 'input', Object? defaultValue}) {
    return interact_cli.Input(
      prompt: prompt,
      defaultValue: defaultValue?.toString(),
    ).interact();
  }

  @override
  String inputWithValidation({
    String prompt = 'input',
    required String? Function(String) validator,
    Object? defaultValue,
  }) {
    while (true) {
      final result = input(prompt: prompt, defaultValue: defaultValue);

      final validatorError = validator(result);

      if (validatorError == null) {
        return result;
      }

      logger.err(validatorError);

      logger.spaces();
    }
  }

  @override
  String select(String message, {required List<String> options}) {
    final index = interact_cli.Select(
      prompt: message,
      options: options,
    ).interact();

    return options[index];
  }

  @override
  int selectIndex(String prompt, {required List<String> options}) {
    return interact_cli.Select(
      prompt: prompt,
      options: options,
    ).interact();
  }
}

class MasonActor extends Actor {
  MasonActor({
    required super.logger,
    mason_logger.Logger? mason,
  })  : this.mason = mason ?? mason_logger.Logger(),
        super._();

  final mason_logger.Logger mason;

  @override
  bool confirm({
    required String prompt,
    bool? defaultValue,
  }) =>
      mason.confirm(
        prompt,
        defaultValue: defaultValue ?? false,
      );

  @override
  String input({
    String prompt = 'input',
    Object? defaultValue,
  }) =>
      mason.prompt(
        prompt,
        defaultValue: defaultValue,
      );

  @override
  String inputWithValidation({
    String prompt = 'input',
    required String? Function(String p1) validator,
    Object? defaultValue,
  }) {
    while (true) {
      final result = input(prompt: prompt, defaultValue: defaultValue);

      final validatorError = validator(result);

      if (validatorError == null) {
        return result;
      }

      logger.err(validatorError);

      logger.spaces();
    }
  }

  @override
  String select(String message, {required List<String> options}) =>
      mason.chooseOne(message, choices: options);
}
