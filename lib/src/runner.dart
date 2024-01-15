import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/commands/list.dart';
import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/constants/constants.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/extensions/brick_oven_runner_extensions.dart';

/// the name of the package

/// {@template brick_oven_runner}
/// Runs the brick_oven commands
/// {@endtemplate}
class BrickOvenRunner extends CommandRunner<int> {
  /// {@macro brick_oven_runner}
  BrickOvenRunner()
      : super(
          Constants.packageName,
          'Generate your bricks 🧱 with this oven 🎛',
        ) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version',
    );
    addCommand(CookBricksCommand());
    addCommand(ListCommand());
    addCommand(UpdateCommand());
  }

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      final exitCode = await runCommand(argResults);

      return exitCode;
    } on FormatException catch (e) {
      di<Logger>()
        ..err(e.message)
        ..info('\n$usage');
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      di<Logger>()
        ..err(e.message)
        ..info('\n$usage');
      return ExitCode.usage.code;
    } catch (error) {
      di<Logger>().err('$error');
      return ExitCode.software.code;
    }
  }

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    Future<void> runCheckForUpdates() async {
      if (!calledUpdate(topLevelResults)) {
        await checkForUpdates();
      }
    }

    if (topLevelResults['version'] == true) {
      di<Logger>().alert(packageVersion);

      await runCheckForUpdates();

      return ExitCode.success.code;
    }

    final result = await super.runCommand(topLevelResults);

    await runCheckForUpdates();

    return result ?? ExitCode.success.code;
  }
}
