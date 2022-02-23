import 'package:equatable/equatable.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/utils/extensions.dart';

/// {@template variable}
/// Represents the variable values provided in the `brick_oven.yaml` file
/// {@endtemplate}
class Variable extends Equatable {
  /// {@macro variable}
  const Variable({
    required this.placeholder,
    required this.name,
    MustacheFormat? format,
    this.suffix,
    this.prefix,
  }) : format = format ?? MustacheFormat.camelCase;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
    required this.suffix,
    required this.prefix,
    MustacheFormat? format,
  }) : format = format ?? MustacheFormat.camelCase;

  /// Parses the [yaml] into a variable
  ///
  /// The [name] is the replacement value for [placeholder]
  factory Variable.fromYaml(String name, YamlMap? yaml) {
    final map = yaml?.data ?? <String, dynamic>{};

    final formatString = map.remove('format') as String?;
    final format = MustacheFormat.values.retrieve(formatString);
    final placeholder = map.remove('placeholder') as String?;
    final suffix = map.remove('suffix') as String?;
    final prefix = map.remove('prefix') as String?;

    if (map.isNotEmpty) {
      throw ArgumentError('Unknown keys in variable: ${map.keys}');
    }

    return Variable._fromYaml(
      placeholder: placeholder ?? name,
      name: name,
      format: format,
      suffix: suffix,
      prefix: prefix,
    );
  }

  /// the placeholder that currently lives in a file
  /// that will be replaced by [name]
  final String placeholder;

  /// the name of variable to replace [placeholder]
  ///
  /// Will be wrapped as `{{#someCase}}{{{name}}}{{/someCase}}`
  final String name;

  /// the value to be prepended to the [formatName]
  final String? prefix;

  /// the value to be appended to the [formatName]
  final String? suffix;

  /// the format in which [name] will be wrapped
  final MustacheFormat format;

  /// formats [name] by wrapping it with mustache
  ///
  /// [prefix] & [suffix] will be applied but
  /// not included within the [name] mustache variable
  /// eg: `{{#someCase}}prefix{{{name}}}suffix{{/someCase}}`
  ///
  /// [format] determines which case to wrap the values
  String formatName(MustacheFormat format) {
    return format.toMustache('${prefix ?? ''}{{{$name}}}${suffix ?? ''}');
  }

  /// wraps [name] with mustache using [format]
  String get formattedName => formatName(format);

  @override
  List<Object?> get props => [
        placeholder,
        name,
        prefix,
        suffix,
        format,
      ];
}
