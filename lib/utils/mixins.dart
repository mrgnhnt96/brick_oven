import 'package:args/command_runner.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:mason_logger/mason_logger.dart';

/// the variables for quit after flag
mixin QuitAfterMixin on Command<int> {
  int _updates = 0;

  /// the count of file updates have occurred
  int get updates => _updates;

  /// increments [updates] by 1
  void fileChanged({Logger? logger}) {
    _updates++;
    if (shouldQuit) {
      logger?.info('Quitting after $updates updates');

      throw MaxUpdateException(quitAfter!);
    }
  }

  /// the number of updates that must occur before the command exits
  ///
  /// `null` means that the command will not exit
  int? get quitAfter =>
      _quitAfterArg == null ? null : int.parse(_quitAfterArg!);

  String? get _quitAfterArg => argResults?['quit-after'] as String?;

  /// whether the command should exit based on [updates]
  bool get shouldQuit => quitAfter != null && updates >= quitAfter!;
}
