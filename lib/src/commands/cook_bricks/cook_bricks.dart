import 'package:args/args.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template cook_bricks_command}
/// Writes the bricks from the configuration file
/// to the brick oven.
class CookBricksCommand extends BrickOvenCommand {
  /// {@macro cook_bricks_command}
  CookBricksCommand({
    FileSystem? fileSystem,
    Logger? logger,
  }) : super(fileSystem: fileSystem, logger: logger) {
    argParser.addFlagsAndOptions();

    addSubcommand(
      CookAllBricks(
        fileSystem: fileSystem,
        logger: logger,
      ),
    );

    for (final brick in bricks) {
      addSubcommand(
        CookSingleBrick(
          brick,
          fileSystem: fileSystem,
          logger: logger,
        ),
      );
    }
  }

  @override
  String get description => 'Cook 👨‍🍳 bricks from the config file.';

  @override
  String get name => 'cook';
}

extension on ArgParser {
  void addFlagsAndOptions() {
    addOption(
      'output',
      abbr: 'o',
      help: 'Sets the output directory',
      valueHelp: 'path',
      defaultsTo: 'bricks',
    );

    addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch the configuration file for changes and '
          're-cook the bricks as they change.',
    );
  }
}
