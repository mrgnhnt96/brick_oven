import 'package:args/args.dart';
import 'package:meta/meta.dart';

/// extensions for [ArgParser]
extension ArgParserX on ArgParser {
  /// adds the [ArgParser] for `BrickCooker`
  void addCookOptionsAndFlags() {
    addOutputOption();
    addWatchFlag();
    addSyncFlag();
  }

  /// the output directory
  @visibleForTesting
  void addOutputOption() {
    addOption(
      'output',
      abbr: 'o',
      help: 'Sets the output directory',
      valueHelp: 'path',
      defaultsTo: 'bricks',
    );
  }

  /// adds the sync flag to validate the brick.yaml file
  @visibleForTesting
  void addSyncFlag() {
    addFlag(
      'sync',
      abbr: 's',
      help: 'Verifies that the brick.yaml file '
          'is synced with the brick_oven.yaml file.\n'
          'Only works if the `brick_config` key '
          'is set in the brick_oven.yaml file.',
      defaultsTo: true,
    );
  }

  /// watches the local source files
  @visibleForTesting
  void addWatchFlag() {
    addFlag(
      'watch',
      abbr: 'w',
      negatable: false,
      help: 'Watch for file changes and '
          're-cook the bricks as they change.',
    );
  }
}
