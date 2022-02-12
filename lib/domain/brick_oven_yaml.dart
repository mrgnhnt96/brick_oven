import 'dart:async';

import 'package:file/file.dart';
import 'package:path/path.dart';
import 'package:watcher/watcher.dart';

/// {@template brick_oven_yaml}
/// Brick Oven configuration yaml file which contains metadata
/// used when interacting with the Brick Oven CLI.
/// {@endtemplate}
class BrickOvenYaml {
  /// the name of the brick oven yaml file
  static const file = 'brick_oven.yaml';

  /// finds the nearest ancestor directory that contains
  /// the brick oven yaml file
  static File? findNearest(Directory cwd) {
    Directory? prev;
    var dir = cwd;

    while (prev?.path != dir.path) {
      final brickOvenConfig = dir.fileSystem.file(join(dir.path, file));

      if (brickOvenConfig.existsSync()) {
        return brickOvenConfig;
      }

      prev = dir;
      dir = dir.parent;
    }

    return null;
  }

  /// the watcher that listens to changes within the configuration file
  static FileWatcher get ovenWatcher => FileWatcher(file);

  /// watches changes in the configuration [file]
  static Future<bool> watchForChanges({void Function()? onChange}) async {
    final watchCompleter = Completer<void>();

    final _yamlListener = ovenWatcher.events.listen((event) {
      onChange?.call();

      watchCompleter.complete();
    });

    await watchCompleter.future;
    await _yamlListener.cancel();

    return true;
  }
}
