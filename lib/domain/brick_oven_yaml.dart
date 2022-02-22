import 'package:file/file.dart';
import 'package:path/path.dart';

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
      final configFile = dir.fileSystem.file(join(dir.path, file));

      if (configFile.existsSync()) {
        return configFile;
      }

      prev = dir;
      dir = dir.parent;
    }

    return null;
  }
}
