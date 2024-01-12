// ignore_for_file: join_return_with_assignment

import 'package:args/args.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/src/constants/constants.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';

/// extensions for [BrickOvenRunner]
extension BrickOvenRunnerX on BrickOvenRunner {
  /// whether the user passed the 'update' command
  bool calledUpdate(ArgResults results) {
    return results.command?.name == UpdateCommand.commandName;
  }

  /// the message to display when the user can update to the latest version
  static const update = '''

Update available! CURRENT_VERSION → NEW_VERSION
Changelog: https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-vNEW_VERSION
Run `brick_oven update` to update
''';

  /// formats the [update] message with color and
  /// with [current] and [latest] versions
  static String formatUpdate(String current, String latest) {
    var update = BrickOvenRunnerX.update;

    update = update.replaceAll('CURRENT_VERSION', current);
    update = update.replaceAll('NEW_VERSION', latest);

    update = update.replaceAll(
      'Update available!',
      cyan.wrap('Update available!')!,
    );

    update = update.replaceAll(
      'brick_oven update',
      green.wrap('brick_oven update')!,
    );
    update = update.replaceAll(
      '$current → $latest',
      darkGray.wrap('$current → $latest')!,
    );

    update = update.replaceAllMapped(
      RegExp(r'(https:\/\/.*)'),
      (match) => yellow.wrap(match[1])!,
    );

    return update;
  }

  /// checks if there is an update available for the tool
  Future<void> checkForUpdates() async {
    try {
      final latestVersion =
          await di<PubUpdater>().getLatestVersion(Constants.packageName);
      final isUpToDate = packageVersion == latestVersion;

      if (!isUpToDate) {
        di<Logger>().info(formatUpdate(packageVersion, latestVersion));
      }
    } catch (_) {}
  }
}
