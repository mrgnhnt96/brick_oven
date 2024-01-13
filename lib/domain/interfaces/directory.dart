import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/domain/take_2/directory_config.dart';
import 'package:brick_oven/domain/take_2/utils/variables_mixin.dart';

/// {@template directory}
/// A directory is a collection of files that can be copied, altered, and/or
/// generated into a new project.
/// {@endtemplate}
abstract class Directory extends DirectoryConfig with VariablesMixin {
  /// {@macro directory}
  Directory(super.config) : super.self();

  /// the path to the directory
  String get path;

  Name? get name;

  Include? get include;

  /// applies the [path] with any configured parts from [path] and
  /// formats them with mustache
  String apply(
    String path, {
    required String pathWithoutSourceDir,
  });
}
