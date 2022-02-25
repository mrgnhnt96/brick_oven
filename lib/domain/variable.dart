import 'package:equatable/equatable.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/yaml_value.dart';
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
    this.suffix,
    this.prefix,
  }) ;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
    required this.suffix,
    required this.prefix,
  }) ;

  /// Parses the [yaml] into a variable
  ///
  /// The [name] is the replacement value for [placeholder]
  factory Variable.fromYaml(String name, YamlMap? yaml) {
    final map = yaml?.data ?? <String, dynamic>{};

    final placeholder = map.remove('placeholder') as String?;
    final suffix = map.remove('suffix') as String?;
    final prefix = map.remove('prefix') as String?;

    if (map.isNotEmpty) {
      throw ArgumentError('Unknown keys in variable: ${map.keys}');
    }

    return Variable._fromYaml(
      placeholder: placeholder ?? name,
      name: name,
      suffix: suffix,
      prefix: prefix,
    );
  }

  /// parses the [value] to [YamlValue]
  factory Variable.from(String name, dynamic value) {
    final yamlValue = YamlValue.from(value);

    if (yamlValue.isYaml()) {
      return Variable.fromYaml(name, yamlValue.asYaml().value);
    } else if (yamlValue.isString()) {
      return Variable(name: name, placeholder: yamlValue.asString().value);
    } else {
      return Variable(name: name, placeholder: name);
    }
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


  @override
  List<Object?> get props => [
        placeholder,
        name,
        prefix,
        suffix,
      ];
}
