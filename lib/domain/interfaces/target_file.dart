import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/domain/interfaces/directory.dart';
import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/domain/interfaces/url.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/domain/config/file_config.dart';
import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/utils/variables_mixin.dart';

/// {@template target_file}
/// A target file is a file that can be copied, altered, and/or
/// generated into a new project.
/// {@endtemplate}
abstract class TargetFile extends FileConfig with VariablesMixin {
  /// {@macro target_file}
  TargetFile(super.config) : super.self();

  /// the name of the file
  ///
  /// if provided, [formatName] will format the name
  /// using mustache
  Name? get name;

  String get pathWithoutSourceDir;

  Include? get include;

  /// the path to the source file
  String get sourcePath;

  /// the path to the target file
  String get targetDir;

  String get extension;

  /// the name of file with extension
  ///
  /// If [nameConfig], then the name will be formatted with mustache,
  /// prepended with prefix, and appended with suffix
  String formatName();

  /// the path to the target file
  FileWriteResult write({
    required Brick brick,
    required Set<Variable> outOfFileVariables,
  });

  /// updates the file path with the provided [urls] and [dirs]
  /// replacing the appropriate segments and file name
  ContentReplacement configurePath({
    required Iterable<Url> urls,
    required Iterable<Directory> dirs,
  });
}
