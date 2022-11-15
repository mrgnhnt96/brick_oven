import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'package:brick_oven/src/commands/brick_oven.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends BrickOvenCommand {
  /// {@macro update_command}
  UpdateCommand({
    PubUpdater? pubUpdater,
    required Logger logger,
  })  : _pubUpdater = pubUpdater ?? PubUpdater(),
        super(logger: logger);

  final PubUpdater _pubUpdater;

  @override
  final String description = 'Updates brick_oven to the latest version';

  @override
  final String name = 'update';

  @override
  Future<int> run() async {
    final updateCheckDone = logger.progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckDone.fail('Failed to get latest version');

      return ExitCode.software.code;
    }

    updateCheckDone.update('Successfully checked for updates');

    final isUpToDate = packageVersion == latestVersion;

    if (isUpToDate) {
      updateCheckDone.complete('brick_oven is already at the latest version.');

      return ExitCode.success.code;
    }

    try {
      updateCheckDone.update('Updating to $latestVersion');
      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      updateCheckDone.fail('Failed to update brick_oven');

      return ExitCode.software.code;
    }

    updateCheckDone
        .complete('Successfully updated brick_oven to $latestVersion');

    return ExitCode.success.code;
  }
}
