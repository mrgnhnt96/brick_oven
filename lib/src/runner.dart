import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/commands/list.dart';
import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/version.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage_io.dart';

/// the name of the package
const packageName = 'brick_oven';

const _gaTrackingId = 'UA-134218670-3';

/// {@template brick_oven_runner}
/// Runs the brick_oven commands
/// {@endtemplate}
class BrickOvenRunner extends CommandRunner<int> {
  /// {@macro brick_oven_runner}
  BrickOvenRunner({
    required Logger logger,
    PubUpdater? pubUpdater,
    FileSystem? fileSystem,
    Analytics? analytics,
  })  : _pubUpdater = pubUpdater ?? PubUpdater(),
        _logger = logger,
        _analytics = analytics ??
            AnalyticsIO(
              _gaTrackingId,
              packageName,
              packageVersion,
            ),
        super(packageName, 'Generate your bricks 🧱 with this oven 🎛') {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version',
      )
      ..addOption(
        'analytics',
        help: 'Toggle anonymous usage statistics.',
        allowed: ['true', 'false'],
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      );

    addCommand(
      CookBricksCommand(
        logger: _logger,
        fileSystem: fileSystem ?? const LocalFileSystem(),
        analytics: _analytics,
      ),
    );

    addCommand(
      ListCommand(
        logger: _logger,
        fileSystem: fileSystem,
        analytics: _analytics,
      ),
    );

    addCommand(
      UpdateCommand(
        pubUpdater: _pubUpdater,
        logger: _logger,
      ),
    );
  }

  final PubUpdater _pubUpdater;

  /// the logger for the application
  final Logger _logger;

  final Analytics _analytics;

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  @override
  Future<int?> run(Iterable<String> args) async {
    try {
      if (_analytics.firstRun) {
        final response = _logger.prompt(
          lightGray.wrap(
            '''
+---------------------------------------------------+
|           Welcome to the Brick Oven!              |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''',
          ),
        );
        final normalizedResponse = response.toLowerCase().trim();
        _analytics.enabled =
            normalizedResponse == 'y' || normalizedResponse == 'yes';
      }

      final argResults = parse(args);

      final exitCode = await runCommand(argResults);

      return exitCode ?? ExitCode.success.code;
    } on FormatException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } catch (error) {
      _logger.err('$error');
      return ExitCode.software.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    int? exitCode = ExitCode.unavailable.code;

    if (topLevelResults['version'] == true) {
      _logger.alert(packageVersion);
      exitCode = ExitCode.success.code;
    } else if (topLevelResults['analytics'] != null) {
      final optIn = topLevelResults['analytics'] == 'true';
      _analytics.enabled = optIn;
      _logger.info('analytics ${_analytics.enabled ? 'enabled' : 'disabled'}.');
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    if (topLevelResults.command?.name != UpdateCommand.commandName) {
      await _checkForUpdates();
    }

    return exitCode;
  }

  Future<void> _checkForUpdates() async {
    try {
      final latestVersion = await _pubUpdater.getLatestVersion(packageName);
      final isUpToDate = packageVersion == latestVersion;
      final updateMessage = '''

+------------------------------------------------------------------------------------+
|                                                                                    |
|                   ${lightYellow.wrap('Update available!')} ${lightCyan.wrap(packageVersion)} \u2192 ${lightCyan.wrap(latestVersion)}                                  |
|  ${lightYellow.wrap('Changelog:')} ${lightCyan.wrap('https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-v$latestVersion')} |
|                             Run ${cyan.wrap('brick_oven update')} to update                        |
|                                                                                    |
+------------------------------------------------------------------------------------+
''';

      if (!isUpToDate) {
        _logger.info(updateMessage);
      }
    } catch (_) {}
  }
}
