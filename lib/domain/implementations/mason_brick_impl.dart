import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/domain/interfaces/mason_brick.dart';
import 'package:brick_oven/domain/config/mason_brick_config.dart';
import 'package:brick_oven/utils/yaml_to_json.dart';
import 'package:brick_oven/src/constants/constants.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@macro mason_brick}
class MasonBrickImpl extends MasonBrickConfig implements MasonBrick {
  /// {@macro mason_brick}
  MasonBrickImpl(
    super.config, {
    required this.shouldSync,
  }) : super.self();

  @override
  final bool shouldSync;

  @override
  Map<dynamic, dynamic> brickYamlContent() {
    return YamlToJson.fromPath(path);
  }

  @override
  void check(Brick brick) {
    if (!shouldSync) {
      return;
    }

    final brickOvenFileName = brick.configPath ?? 'brick_oven.yaml';

    var isInSync = true;

    final brickYaml = brickYamlContent();

    if (brickYaml.isEmpty) {
      return;
    }

    if (brick.name != brickYaml['name']) {
      isInSync = false;
      di<Logger>().warn(
        '`name` (${brickYaml['name']}) in brick.yaml does not '
        'match the name in $brickOvenFileName (${brick.name})',
      );
    }

    final varsRaw = brickYaml['vars'];
    Iterable<String> vars = [];
    if (varsRaw is Map) {
      vars = varsRaw.keys.map((e) => '$e');
    } else if (varsRaw is List) {
      vars = varsRaw.map((e) => '$e');
    }

    final alwaysRemove = ['', ...Constants.variablesToIgnore, ...ignoreVars];

    final variables = {...brick.vars.expand((e) => e.split('.'))}
      ..removeAll(alwaysRemove);

    final variablesInBrickYaml = {...vars}..removeAll(alwaysRemove);

    if (variablesInBrickYaml.difference(variables).isNotEmpty) {
      isInSync = false;
      final vars =
          '"${variablesInBrickYaml.difference(variables).join('", "')}"';
      di<Logger>().warn(
        'Variables ($vars) exist in brick.yaml but not in $brickOvenFileName',
      );
    }

    if (variables.difference(variablesInBrickYaml).isNotEmpty) {
      isInSync = false;
      final vars =
          '"${variables.difference(variablesInBrickYaml).join('", "')}"';

      di<Logger>().warn(
        'Variables ($vars) exist in $brickOvenFileName but not in brick.yaml',
      );
    }

    if (isInSync) {
      di<Logger>().info(darkGray.wrap('brick.yaml is in sync'));
    } else {
      di<Logger>().err('brick.yaml is out of sync');
    }
  }
}
