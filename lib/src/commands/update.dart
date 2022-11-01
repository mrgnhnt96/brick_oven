import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/package_details.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends BrickOvenCommand {
  /// {@macro update_command}
  UpdateCommand({
    PubUpdater? pubUpdater,
    Logger? logger,
  })  : _pubUpdater = pubUpdater ?? PubUpdater(),
        super(logger: logger ?? Logger());

  final PubUpdater _pubUpdater;

  @override
  final String description = 'Updates brick_oven to the latest version.';

  @override
  final String name = 'update';

  @override
  Future<int> run() async {
    final updateCheckDone = logger.progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckDone.complete();
      logger.err('$error');

      return ExitCode.software.code;
    }

    updateCheckDone.update('Successfully checked for updates');

    final isUpToDate = packageVersion == latestVersion;

    if (isUpToDate) {
      updateCheckDone.complete('brick_oven is already at the latest version.');

      return ExitCode.success.code;
    }

    try {
      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      updateCheckDone.fail('Failed to update brick_oven');
      logger.err('$error');

      return ExitCode.software.code;
    }

    updateCheckDone.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
