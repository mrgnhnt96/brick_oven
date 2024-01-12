import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:brick_oven/utils/di.dart';
import 'package:brick_oven/src/constants/constants.dart';
import 'package:brick_oven/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends Command<int> {
  /// {@macro update_command}
  UpdateCommand();

  @override
  final String description = 'Updates brick_oven to the latest version';

  @override
  final String name = commandName;

  /// the name of the command
  static const commandName = 'update';

  @override
  Future<int> run() async {
    final updater = di<PubUpdater>();

    final progress = di<Logger>().progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await updater.getLatestVersion(Constants.packageName);
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

      await updater.update(packageName: Constants.packageName);
    } catch (error) {
      progress.fail('Failed to update brick_oven');

      return ExitCode.software.code;
    }

    progress.complete('Successfully updated brick_oven to $latestVersion');

    return ExitCode.success.code;
  }
}
