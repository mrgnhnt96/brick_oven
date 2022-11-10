import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:equatable/equatable.dart';

part 'brick_partial.g.dart';

/// {@template brick_partial}
/// A partial is a template that can be re-used within files
/// {@endtemplate}
@autoequal
class BrickPartial extends Equatable {
  /// {@macro brick_partial}
  const BrickPartial({
    required this.path,
    this.variables = const [],
  });

  /// {@macro brick_partial}
  factory BrickPartial.fromYaml(YamlValue yaml, String path) {
    if (yaml.isError()) {
      throw PartialException(
        partial: path,
        reason: 'Invalid configuration',
      );
    }

    if (yaml.isNone()) {
      return BrickPartial(path: path);
    }

    if (!yaml.isYaml()) {
      throw PartialException(
        partial: path,
        reason: 'Expected type `Map` or `null`',
      );
    }

    final data = yaml.asYaml().value;

    final varsYaml = YamlValue.from(data['vars']);

    if (varsYaml.isError()) {
      throw PartialException(
        partial: path,
        reason: 'Invalid variables configuration',
      );
    }

    if (varsYaml.isNone()) {
      return BrickPartial(path: path);
    }

    if (!varsYaml.isYaml()) {
      throw PartialException(
        partial: path,
        reason: 'Expected type `Map` or `null`',
      );
    }

    final vars = varsYaml.asYaml().value.data;

    final variables = <Variable>[];

    for (final entry in vars.entries) {
      try {
        final variable = Variable.fromYaml(
          YamlValue.from(entry.value),
          entry.key,
        );
        variables.add(variable);
      } on ConfigException catch (e) {
        throw PartialException(
          partial: path,
          reason: e.message,
        );
      }
    }

    return BrickPartial(
      path: path,
      variables: variables,
    );
  }

  /// the path to the partial file
  final String path;

  /// the variables within the partial
  final List<Variable> variables;

  @override
  List<Object?> get props => _$props;
}
