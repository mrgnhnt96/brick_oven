import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';

/// {@template cook_bricks_command}
/// Writes the bricks from the configuration file
/// to the brick oven.
class CookBricksCommand extends BrickOvenCommand {
  /// {@macro cook_bricks_command}
  CookBricksCommand({
    FileSystem? fileSystem,
    Logger? logger,
  }) : super(fileSystem: fileSystem, logger: logger) {
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
