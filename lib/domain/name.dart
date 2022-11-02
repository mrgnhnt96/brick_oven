import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';

import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/utils/extensions.dart';

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
    this.format,
  })  : prefix = prefix ?? '',
        suffix = suffix ?? '';

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
    String? name;
    String? prefix;
    String? suffix;
    MustacheFormat? format;

    if (value.isYaml()) {
      final nameConfig = value.asYaml().value.data;

      name = nameConfig.remove('value') as String? ?? backup;
      prefix = nameConfig.remove('prefix') as String?;
      suffix = nameConfig.remove('suffix') as String?;
      format = MustacheFormat.values
          .getMustacheValue(nameConfig.remove('format') as String?);

      if (name == null) {
        throw ArgumentError('The name was not provided');
      }

      if (nameConfig.isNotEmpty == true) {
        throw ArgumentError(
          'Unrecognized keys in file config: ${nameConfig.keys}',
        );
      }

      return Name(name, prefix: prefix, suffix: suffix, format: format);
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
  final String prefix;

  /// the suffix of the name
  final String suffix;

  /// the format of the name
  final MustacheFormat? format;

  /// gets the name of the file without formatting to mustache
  ///
  /// eg: `prefix{name}suffix`
  String get simple {
    return '$prefix{$value}$suffix';
  }

  /// gets the name of the file with formatting to mustache
  String get formatted {
    if (format != null) {
      return format!.toMustache(_toVariable);
    }

    return _toVariable;
  }

  String get _toVariable {
    return '$prefix{{{$value}}}$suffix';
  }

  /// gets the name of the file with formatting to mustache from [format]
  String formatWith(MustacheFormat format) {
    return format.toMustache(_toVariable);
  }

  @override
  List<Object?> get props => _$props;
}
