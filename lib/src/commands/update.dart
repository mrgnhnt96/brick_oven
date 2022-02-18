import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/package_details.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// {@template update_command}
/// `mason update` command which updates mason.
/// {@endtemplate}
class UpdateCommand extends BrickOvenCommand {
  /// {@macro update_command}
  UpdateCommand({
    required PubUpdater pubUpdater,
    Logger? logger,
  })  : _pubUpdater = pubUpdater,
        super(logger: logger ?? Logger());

  final PubUpdater _pubUpdater;

  @override
  final String description = 'Update brick_oven.';

  @override
  final String name = 'update';

  @override
  Future<int> run() async {
    final updateCheckDone = logger.progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await _pubUpdater.getLatestVersion(packageName);
    } catch (error) {
      updateCheckDone();
      logger.err('$error');

      return ExitCode.software.code;
    }

    updateCheckDone('Checked for updates');

    final isUpToDate = packageVersion == latestVersion;

    if (isUpToDate) {
      logger.info('brick_oven is already at the latest version.');

      return ExitCode.success.code;
    }

    final updateDone = logger.progress('Updating to $latestVersion');

    try {
      await _pubUpdater.update(packageName: packageName);
    } catch (error) {
      updateDone();
      logger.err('$error');

      return ExitCode.software.code;
    }

    updateDone('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}
