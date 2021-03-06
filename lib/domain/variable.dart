import 'package:equatable/equatable.dart';

import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/utils/extensions.dart';

/// {@template variable}
/// Represents the variable values provided in the `brick_oven.yaml` file
/// {@endtemplate}
class Variable extends Equatable {
  /// {@macro variable}
  const Variable({
    required this.name,
    String? placeholder,
  }) : placeholder = placeholder ?? name;

  const Variable._fromYaml({
    required this.placeholder,
    required this.name,
  });

  /// Parses the [yaml] into a variable
  ///
  /// The [name] is the replacement value for [placeholder]
  factory Variable.fromYaml(String name, YamlValue? yaml) {
    if (yaml == null) {
      return Variable._fromYaml(
        placeholder: name,
        name: name,
      );
    }

    String placeholder;

    if (yaml.isString()) {
      placeholder = yaml.asString().value;
    } else if (yaml.isYaml()) {
      final map = yaml.asYaml().value.data;

      if (map.isEmpty) {
        placeholder = name;
      } else {
        throw ArgumentError('Unknown keys in variable: ${map.keys}');
      }
    } else {
      throw ArgumentError('Missing value for variable: $name');
    }

    return Variable._fromYaml(
      name: name,
      placeholder: placeholder,
    );
  }

  /// parses the [value] to [YamlValue]
  factory Variable.from(String name, dynamic value) {
    final yamlValue = YamlValue.from(value);

    if (yamlValue.isYaml()) {
      throw ArgumentError('Variable $name cannot be a map');
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

  /// formats [name] by wrapping it with mustache
  ///
  /// [format] determines which case to wrap the values
  String formatName(MustacheFormat format) {
    return format.toMustache(
      '{{{$name}}}',
    );
  }

  @override
  List<Object?> get props => [placeholder, name];
}
