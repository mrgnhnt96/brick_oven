import 'package:autoequal/autoequal.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/yaml_map_extensions.dart';
import 'package:brick_oven/utils/include_mixin.dart';
import 'package:equatable/equatable.dart';
import 'package:path/path.dart';

part 'url.g.dart';

/// {@template url}
/// Represents a URL configured in a brick
/// {@endtemplate}
@autoequal
class Url extends Equatable with IncludeMixin {
  /// {macro url}
  Url(
    this.path, {
    this.name,
    this.includeIf,
    this.includeIfNot,
  })  : assert(extension(path).isEmpty, 'path must not have an extension'),
        assert(
          includeIf == null || includeIfNot == null,
          'includeIf and includeIfNot cannot both be set',
        );

  /// {macro url}
  factory Url.fromYaml(YamlValue yaml, String path) {
    if (extension(path).isNotEmpty) {
      throw UrlException(
        url: path,
        reason: 'path must not have an extension',
      );
    }

    if (yaml.isError()) {
      throw UrlException(
        url: path,
        reason: 'Invalid url: ${yaml.asError().value}',
      );
    }

    if (yaml.isNone()) {
      return Url(path);
    }

    if (!yaml.isYaml() && !yaml.isString()) {
      throw UrlException(
        url: path,
        reason: 'Expected type `String`, `null`, or `Map`',
      );
    }

    final backupName = basename(path);

    if (yaml.isString()) {
      final name = yaml.asString().value;

      return Url(
        path,
        name: Name(name),
      );
    }

    final data = yaml.asYaml().value.data;

    final name = Name.fromYaml(YamlValue.from(data.remove('name')), backupName);

    String? getInclude(String key) {
      final yaml = YamlValue.from(data.remove(key));
      return IncludeMixin.getInclude(yaml, key);
    }

    final includeIf = getInclude('include_if');
    final includeIfNot = getInclude('include_if_not');

    if (includeIf != null && includeIfNot != null) {
      throw FileException(
        file: path,
        reason: 'Cannot use both `include_if` and `include_if_not`',
      );
    }

    if (data.isNotEmpty) {
      throw UrlException(
        url: path,
        reason: 'Unexpected keys: ${data.keys.join(', ')}',
      );
    }

    return Url(
      path,
      name: name,
      includeIf: includeIf,
      includeIfNot: includeIfNot,
    );
  }

  /// the path to the URL file
  final String path;

  /// the name of the file for the URL
  final Name? name;

  Name get _replacementName => name ?? Name(basename(path));

  /// gets the variables used within the URL
  List<String> get variables {
    final variables = <String>[..._replacementName.variables];

    return variables;
  }

  /// returns the name of the URL file
  String formatName() {
    final name = _replacementName;

    return name.format(
      postStartBraces: '% ',
      preEndBraces: ' %',
    );
  }

  @override
  final String? includeIf;

  @override
  final String? includeIfNot;

  @override
  List<Object?> get props => _$props;
}
