// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';

import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';

/// {@template lists_command}
/// Lists the configured bricks within the config file
/// {@endtemplate}
class ListCommand extends BrickOvenCommand {
  /// {@macro lists_command}
  ListCommand({
    required Logger logger,
    FileSystem? fileSystem,
  }) : super(
          logger: logger,
          fileSystem: fileSystem,
        ) {
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Lists the bricks with their file & dir configurations',
    );
  }

  @override
  String get description =>
      'Lists all configured bricks from ${BrickOvenYaml.file}.';

  @override
  String get name => 'list';

  @override
  Future<int> run() async {
    logger.info('\nBricks in the oven:');
    const tab = '  ';

    String varString(Variable variable) {
      return '${tab * 4}- '
          '${variable.placeholder} ${green.wrap('->')} {${variable.name}}';
    }

    String fileString(BrickFile file) {
      final segments = BrickPath.separatePath(file.path);
      final originalName = segments.removeLast();
      final dir = segments.join(separator) + separator;

      final vars = tab * 3 +
          cyan.wrap('vars')! +
          ':\n' +
          file.variables.map(varString).join('\n');

      return '${tab * 2}- ${darkGray.wrap(dir)}$originalName'
          // ignore: lines_longer_than_80_chars
          '${file.hasConfiguredName ? ' ${green.wrap('->')} ${file.simpleName}' : ''}'
          '${file.variables.isNotEmpty ? '\n$vars' : ''}';
    }

    String dirString(BrickPath dir) {
      final parts = dir.configuredParts;
      final originalDir = parts.removeLast();

      final pathWithoutName = darkGray.wrap(parts.join(separator) + separator);
      final dirDescription = '${tab * 2}- $pathWithoutName$originalDir';

      if (dir.name?.simple != null) {
        return '$dirDescription ${green.wrap('->')} ${dir.name!.simple}';
      }

      return dirDescription;
    }

    final bricksOrError = this.bricks();
    if (bricksOrError.isError) {
      logger.err(bricksOrError.error);
      return ExitCode.config.code;
    }

    final bricks = bricksOrError.bricks;

    for (final brick in bricks) {
      if (isVerbose) {
        final configFiles = brick.files.toList()
          ..sort((a, b) => a.path.compareTo(b.path));
        final configDirs = brick.dirs.toList()
          ..sort((a, b) => a.path.compareTo(b.path));

        final files = configFiles.isEmpty
            ? ''
            : '\n$tab${cyan.wrap('files')}:'
                '\n${configFiles.map(fileString).join('\n')}';

        final dirs = configDirs.isEmpty
            ? ''
            : '\n$tab${cyan.wrap('dirs')}:'
                '\n${configDirs.map(dirString).join('\n')}';

        logger.info(
          '${lightYellow.wrap(brick.name)}'
          '\n${tab}source: ${brick.source.sourceDir}'
          '$files'
          '$dirs\n',
        );
      } else {
        logger.info(
          '''
${lightYellow.wrap(brick.name)}
${tab}source: ${brick.source.sourceDir}
$tab${cyan.wrap('files')}: ${brick.files.length}
$tab${cyan.wrap('dirs')}: ${brick.dirs.length}\n''',
        );
      }
    }
    logger.info('');

    return ExitCode.success.code;
  }

  /// whether to list the output in verbose mode
  bool get isVerbose => argResults['verbose'] as bool? ?? false;
}
