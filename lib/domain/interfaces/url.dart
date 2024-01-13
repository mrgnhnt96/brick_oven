import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/domain/take_2/url_config.dart';
import 'package:brick_oven/domain/take_2/utils/variables_mixin.dart';

/// {@template url}
/// A url is a collection of files that can be copied, altered, and/or
/// generated into a new project.
/// {@endtemplate}
abstract class Url extends UrlConfig with VariablesMixin {
  /// {@macro url}
  Url(super.config) : super.self();

  Name? get name;

  Include? get include;

  /// the path to the url
  String get path;

  String formatName();
}
