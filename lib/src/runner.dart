import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/src/commands/list.dart';
import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
import 'package:brick_oven/utils/extensions/brick_oven_runner_extensions.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage_io.dart';

/// the name of the package
const packageName = 'brick_oven';

/// {@template brick_oven_runner}
/// Runs the brick_oven commands
/// {@endtemplate}
class BrickOvenRunner extends CommandRunner<int> {
  /// {@macro brick_oven_runner}
  BrickOvenRunner({
    required Logger logger,
    required PubUpdater pubUpdater,
    required FileSystem fileSystem,
    required Analytics analytics,
  })  : _pubUpdater = pubUpdater,
        _logger = logger,
        _analytics = analytics,
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
        defaultsTo: 'true',
        allowedHelp: {
          'true': 'Enable anonymous usage statistics',
          'false': 'Disable anonymous usage statistics',
        },
      );

    addCommand(
      CookBricksCommand(
        logger: _logger,
        fileSystem: fileSystem,
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
    Future<void> runCheckForUpdates() async {
      if (!calledUpdate(topLevelResults)) {
        await checkForUpdates(
          updater: _pubUpdater,
          logger: _logger,
        );
      }
    }

    if (topLevelResults['analytics'] != null) {
      final optIn = topLevelResults['analytics'] == 'true';

      _analytics.enabled = optIn;

      _logger.info('analytics ${optIn ? 'enabled' : 'disabled'}.');

      await runCheckForUpdates();

      return ExitCode.success.code;
    }

    _analytics.askForConsent(_logger);

    if (topLevelResults['version'] == true) {
      _logger.alert(packageVersion);

      await runCheckForUpdates();

      return ExitCode.success.code;
    }

    final result = await super.runCommand(topLevelResults);

    await runCheckForUpdates();

    return result ?? ExitCode.unavailable.code;
  }
}
