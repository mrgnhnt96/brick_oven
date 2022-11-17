import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/utils/brick_cooker.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage_io.dart';

/// {@template cook_bricks_command}
/// Writes the bricks from the configuration file
/// to the brick oven.
class CookBricksCommand extends BrickOvenCommand with BrickCookerArgs {
  /// {@macro cook_bricks_command}
  CookBricksCommand({
    required FileSystem fileSystem,
    required Logger logger,
    required Analytics analytics,
  }) : super(fileSystem: fileSystem, logger: logger) {
    addSubcommand(
      CookAllBricks(
        fileSystem: fileSystem,
        logger: logger,
        analytics: analytics,
      ),
    );

    final bricksOrError = this.bricks();

    if (bricksOrError.isError) {
      logger
        ..warn(bricksOrError.error)
        ..err('Error reading ${BrickOvenYaml.file}');
      return;
    }

    final bricks = bricksOrError.bricks;

    for (final brick in bricks) {
      addSubcommand(
        CookSingleBrick(
          brick,
          fileSystem: fileSystem,
          logger: logger,
          analytics: analytics,
        ),
      );
    }
  }

  @override
  String get description => 'Cook 👨‍🍳 bricks from the config file';

  @override
  String get name => 'cook';
}
