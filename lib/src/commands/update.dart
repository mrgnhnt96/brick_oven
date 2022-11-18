import 'package:args/command_runner.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends Command<int> {
  /// {@macro update_command}
  UpdateCommand({
    required PubUpdater pubUpdater,
    required Logger logger,
  })  : _pubUpdater = pubUpdater,
        _logger = logger;

  final PubUpdater _pubUpdater;
  final Logger _logger;

  @override
  final String description = 'Updates brick_oven to the latest version';

  @override
  final String name = commandName;

  /// the name of the command
  static const commandName = 'update';

  @override
  Future<int> run() async {
    final progress = _logger.progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      progress.fail('Failed to get latest version');

      return ExitCode.software.code;
    }

    progress.update('Successfully checked for updates');

    final isUpToDate = packageVersion == latestVersion;

    if (isUpToDate) {
      progress.complete('brick_oven is already at the latest version.');

      return ExitCode.success.code;
    }

    try {
      progress.update('Updating to $latestVersion');
      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      progress.fail('Failed to update brick_oven');

      return ExitCode.software.code;
    }

    progress.complete('Successfully updated brick_oven to $latestVersion');

    return ExitCode.success.code;
  }
}
