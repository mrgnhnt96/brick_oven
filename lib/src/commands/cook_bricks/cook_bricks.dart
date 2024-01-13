import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/config/brick_oven_config.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/utils/brick_cooker.dart';

import 'package:brick_oven/utils/yaml_to_json.dart';

/// {@template cook_bricks_command}
/// Writes the bricks from the configuration file
/// to the brick oven.
/// {@endtemplate}
class CookBricksCommand extends BrickOvenCommand with BrickCookerArgs {
  /// {@macro cook_bricks_command}
  CookBricksCommand() {
    addSubcommand(CookAllBricks());

    final configFile = BrickOvenYaml.findNearest(cwd);

    if (configFile == null) {
      _subBricksWarning = '\n[WARNING] No ${BrickOvenYaml.file} file found';
      return;
    }

    final json = YamlToJson.fromFile(configFile);

    final config = BrickOvenConfig.fromJson(json, configPath: configFile.path);

    final bricks = config.resolveBricks();

    for (final MapEntry(key: name, value: brick) in bricks.entries) {
      addSubcommand(CookSingleBrick(name, brick));
    }
  }

  @override
  String get description => 'Cook 👨‍🍳 bricks from the config file';

  @override
  String get name => 'cook';

  String? _subBricksWarning;

  @override
  String? get usageFooter => _subBricksWarning;
}
