import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:usage/usage_io.dart';

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends Command<int> {
  /// {@macro update_command}
  UpdateCommand({
    required PubUpdater pubUpdater,
    required Logger logger,
    required Analytics analytics,
  })  : _pubUpdater = pubUpdater,
        _logger = logger,
        _analytics = analytics;

  final PubUpdater _pubUpdater;
  final Logger _logger;
  final Analytics _analytics;

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

      unawaited(
        _analytics.sendEvent(
          'update',
          'up-to-date',
          value: ExitCode.success.code,
          parameters: {
            'version': latestVersion,
          },
        ),
      );

      await _analytics.waitForLastPing(timeout: BrickOvenRunner.timeout);

      return ExitCode.success.code;
    }

    try {
      progress.update('Updating to $latestVersion');
      unawaited(
        _analytics.sendEvent(
          'update',
          'success',
          value: ExitCode.success.code,
          parameters: {
            'old version': packageVersion,
            'new version': latestVersion,
          },
        ),
      );

      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      progress.fail('Failed to update brick_oven');

      return ExitCode.software.code;
    }

    progress.complete('Successfully updated brick_oven to $latestVersion');

    await _analytics.waitForLastPing(timeout: BrickOvenRunner.timeout);

    return ExitCode.success.code;
  }
}
