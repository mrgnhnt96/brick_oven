import 'package:equatable/equatable.dart';

import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/utils/extensions.dart';

/// {@template name}
/// Represents the name variable found within the configuration
/// {@endtemplate}
class Name extends Equatable {
  /// {@macro name}
  const Name(
    this.value, {
    this.prefix,
    this.suffix,
  });

  /// {@macro name}
  ///
  /// Parses from [value] to [YamlValue]
  factory Name.from(dynamic value, [String? backup]) {
    final nameConfigYaml = YamlValue.from(value);

    return Name.fromYamlValue(nameConfigYaml, backup);
  }

  /// {@macro name}
  ///
  /// Parses from [value] from [YamlValue]
  factory Name.fromYamlValue(YamlValue value, [String? backup]) {
    String? name, prefix, suffix;

    if (value.isYaml()) {
      final nameConfig = value.asYaml().value.data;

      name = nameConfig.remove('value') as String? ?? backup;
      prefix = nameConfig.remove('prefix') as String?;
      suffix = nameConfig.remove('suffix') as String?;

      if (name == null) {
        throw ArgumentError('The name was not provided');
      }

      if (nameConfig.isNotEmpty == true) {
        throw ArgumentError(
          'Unrecognized keys in file config: ${nameConfig.keys}',
        );
      }

      return Name(name, prefix: prefix, suffix: suffix);
    } else if (value.isString()) {
      name = value.asString().value;

      return Name(name);
    } else if (backup != null) {
      return Name(backup);
    } else {
      throw ArgumentError('The name was not provided');
    }
  }

  /// the value of the name
  final String value;

  /// the prefix of the name
  final String? prefix;

  /// the suffix of the name
  final String? suffix;

  /// gets the name of the file without formatting to mustache
  ///
  /// eg: `prefix{name}suffix`
  String get simple {
    final prefix = this.prefix ?? '';
    final suffix = this.suffix ?? '';

    return '$prefix{$value}$suffix';
  }

  /// formats the [value] to a mustache [format]
  String format(MustacheFormat format) {
    final prefix = this.prefix ?? '';
    final suffix = this.suffix ?? '';

    final formattedName = '$prefix{{{$value}}}$suffix';
    final mustacheName = format.toMustache(formattedName);

    return mustacheName;
  }

  @override
  List<Object?> get props => [value, prefix, suffix];
}
