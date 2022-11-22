import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:equatable/equatable.dart';

part 'name.g.dart';

/// {@template name}
/// Represents the name variable found within the configuration
/// {@endtemplate}

@autoequal
class Name extends Equatable {
  /// {@macro name}
  Name(
    this.value, {
    String? prefix,
    String? suffix,
    this.section,
    this.invertedSection,
    this.tag,
    int? braces,
  })  : prefix = prefix ?? '',
        suffix = suffix ?? '',
        braces = braces ?? kDefaultBraces,
        assert(
          braces == null || braces > 1 && braces < 4,
          'braces must be 2 or 3',
        ),
        assert(tag == null || tag.isFormat, 'tag must be a format tag'),
        assert(
          section == null || invertedSection == null,
          'section and invertedSection cannot both be set',
        ),
        assert(
          tag == null || section == null && invertedSection == null,
          'tag cannot be set when section or invertedSection is set',
        ),
        assert(
          value != kIndexValue ||
              value == kIndexValue &&
                  (section != null || invertedSection != null),
          'to access the index value, section or '
          'inverted section must be provided',
        );

  /// {@macro name}
  ///
  /// Parses from [value] from [YamlValue]
  factory Name.fromYaml(YamlValue value, String backup) {
    String? name;
    String? prefix;
    String? suffix;
    MustacheTag? format;

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
      format =
          MustacheTag.values.findFrom(getValue('format'), onlyFormat: true);

      final section = getValue('section');
      final invertedSection = getValue('inverted_section');

      if (section != null && invertedSection != null) {
        throw VariableException(
          variable: backup,
          reason: 'Cannot have both `section` and `inverted_section`',
        );
      }

      if (format != null && (section != null || invertedSection != null)) {
        throw VariableException(
          variable: backup,
          reason: 'Cannot have `format` and `section`/`inverted_section`',
        );
      }

      final braces = int.tryParse('${nameConfig.remove('braces')}');

      if (braces != null && (braces < 2 || braces > 3)) {
        throw VariableException(
          variable: backup,
          reason: '`braces` must be 2 or 3',
        );
      }

      if (nameConfig.isNotEmpty) {
        throw VariableException(
          variable: name,
          reason: 'Unknown keys: "${nameConfig.keys.join('", "')}"',
        );
      }

      return Name(
        name,
        prefix: prefix,
        suffix: suffix,
        tag: format,
        section: section,
        invertedSection: invertedSection,
        braces: braces,
      );
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

  /// if the name is to be wrapped with a section tag
  final String? section;

  /// if the name is to be wrapped with an inverted section tag
  final String? invertedSection;

  /// the number of braces to wrap the name with
  final int braces;

  @override
  List<Object?> get props => _$props;

  /// gets the name of the file with formatting to mustache
  String format() {
    var result = value;

    if (result == kIndexValue) {
      result = '.';
    }

    if (tag != null) {
      result = tag!.wrap(value, braceCount: braces);
    } else {
      final startBraces = '{' * braces;
      final endBraces = '}' * braces;
      result = '$startBraces$result$endBraces';
    }

    if (section != null || invertedSection != null) {
      String start;
      String end;

      if (section != null) {
        start = MustacheTag.if_.wrap(section!);
        end = MustacheTag.endIf.wrap(section!);
      } else {
        start = MustacheTag.ifNot.wrap(invertedSection!);
        end = MustacheTag.endIf.wrap(invertedSection!);
      }

      result = '$start$result$end';
    }

    return '$prefix$result$suffix';
  }
}
