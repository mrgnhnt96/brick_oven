import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:equatable/equatable.dart';

part 'name.g.dart';

/// {@template name}
/// Represents the name variable found within the configuration
/// {@endtemplate}

@autoequal
class Name extends Equatable {
  /// {@macro name}
  const Name(
    this.value, {
    String? prefix,
    String? suffix,
    this.tag,
  })  : prefix = prefix ?? '',
        suffix = suffix ?? '';

  /// {@macro name}
  ///
  /// Parses from [value] from [YamlValue]
  factory Name.fromYaml(YamlValue value, String backup) {
    String? name;
    String? prefix;
    String? suffix;
    MustacheTag? tag;

    if (value.isError()) {
      throw VariableException(
        variable: backup,
        reason: value.asError().value,
      );
    }

    if (value.isYaml()) {
      final nameConfig = value.asYaml().value.data;

      String? getValue(String key) {
        final yaml = YamlValue.from(nameConfig.remove(key));

        if (yaml.isNone()) {
          return null;
        }

        if (!yaml.isString()) {
          throw VariableException(
            variable: backup,
            reason: 'Expected type `String` or `null` for `$key`',
          );
        }

        return yaml.asString().value;
      }

      name = getValue('value') ?? backup;
      prefix = getValue('prefix');
      suffix = getValue('suffix');
      tag = MustacheTag.values.findFrom(getValue('format'));

      if (nameConfig.isNotEmpty) {
        throw VariableException(
          variable: name,
          reason: 'Unknown keys: "${nameConfig.keys.join('", "')}"',
        );
      }

      return Name(name, prefix: prefix, suffix: suffix, tag: tag);
    }

    if (value.isString()) {
      name = value.asString().value;

      return Name(name);
    }

    return Name(backup);
  }

  /// the format of the name
  final MustacheTag? tag;

  /// the prefix of the name
  final String prefix;

  /// the suffix of the name
  final String suffix;

  /// the value of the name
  final String value;

  @override
  List<Object?> get props => _$props;

  String get _toVariable {
    return '$prefix{{{$value}}}$suffix';
  }

  /// gets the name of the file with formatting to mustache
  String get formatted {
    if (tag != null) {
      return tag!.wrap(_toVariable);
    }

    return _toVariable;
  }

  /// gets the name of the file without formatting to mustache
  ///
  /// eg: `prefix{name}suffix`
  String get simple {
    return '$prefix{$value}$suffix';
  }
}
