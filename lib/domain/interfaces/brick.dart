import 'package:brick_oven/domain/interfaces/directory.dart';
import 'package:brick_oven/domain/interfaces/mason_brick.dart';
import 'package:brick_oven/domain/interfaces/partial.dart';
import 'package:brick_oven/domain/interfaces/source.dart';
import 'package:brick_oven/domain/interfaces/url.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/domain/config/brick_config.dart';
import 'package:brick_oven/utils/variables_mixin.dart';

/// {@template brick}
/// A brick is a collection of files that can be copied, altered, and/or
/// generated into a new project.
/// {@endtemplate}
abstract class Brick extends BrickConfig with VariablesMixin {
  /// {@macro brick}
  Brick(super.config) : super.self();

  /// the name of the brick
  String get name;

  /// the directory to output the brick to
  String get outputDir;

  /// Whether the brick's [sourcePath] is being watched to react
  /// to file changes
  bool get watch;

  /// Whether to validate the brick.yaml file. That all inputs
  /// are valid and consumed
  bool get shouldSync;

  /// the file system watcher for the brick
  ///
  /// This is used to watch the brick's source directory/files and
  /// trigger a re-cook when changes are detected
  SourceWatcher get watcher;

  /// The brick's config file to be consumed by mason
  MasonBrick? get masonBrick;

  /// The list of partials that are configured for the brick
  Iterable<Partial> get partials;

  /// The list of directories that are configured for the brick
  Iterable<Directory> get directories;

  /// The list of urls that are configured for the brick
  Iterable<Url> get urls;

  /// the source files for the brick
  Source get source;

  /// cooks the brick, and outputs the files to [outputDir]
  void cook();
}
