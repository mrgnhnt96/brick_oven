import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/enums/mustache_loops.dart';
import 'package:equatable/equatable.dart';
import 'package:file/file.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

class BrickFile extends Equatable {
  const BrickFile(this.path)
      : variables = const [],
        prefix = null,
        suffix = null,
        providedName = null;

  const BrickFile._fromYaml(
    this.path, {
    required this.variables,
    required this.prefix,
    required this.suffix,
    required String? name,
  }) : providedName = name;

  const BrickFile._({
    required this.variables,
    required this.prefix,
    required this.suffix,
    required String? name,
    required this.path,
  }) : providedName = name;

  factory BrickFile.fromYaml(
    YamlMap yaml, {
    required String path,
  }) {
    final data = yaml.value;

    final variablesData = data.remove('vars') as YamlMap?;

    Iterable<Variable> variables() sync* {
      if (variablesData == null) {
        return;
      }

      for (final entry in variablesData.entries) {
        final name = entry.key as String;
        final value = entry.value as YamlMap;

        yield Variable.fromYaml(name, value);
      }
    }

    final fileConfigYaml = data.remove('file') as YamlMap?;
    final fileConfig = fileConfigYaml?.value;

    final name = fileConfig?.remove('name') as String?;
    final prefix = fileConfig?.remove('prefix') as String?;
    final suffix = fileConfig?.remove('suffix') as String?;

    if (data.isNotEmpty) {
      throw ArgumentError('Unrecognized keys in file config: ${data.keys}');
    }

    if (fileConfig?.isNotEmpty == true) {
      throw ArgumentError(
        'Unrecognized keys in file config: ${fileConfig!.keys}',
      );
    }

    return BrickFile._fromYaml(
      path,
      variables: variables(),
      prefix: prefix,
      suffix: suffix,
      name: name,
    );
  }

  final String path;
  final Iterable<Variable> variables;
  final String? prefix;
  final String? suffix;
  final String? providedName;

  String get fileName {
    if (providedName == null) {
      return basename(path);
    }
    final prefix = this.prefix ?? '';
    final suffix = this.suffix ?? '';

    final name = '$prefix{{{$providedName}}}$suffix';
    final formattedName = MustacheFormat.snakeCase.toMustache(name);

    return '$formattedName$_extension';
  }

  String get _extension => extension(path, 10);

  void writeTargetFile({
    required String targetDir,
    required File sourceFile,
    required Iterable<BrickPath> configuredDirs,
    required FileSystem fileSystem,
  }) {
    var path = this.path;

    if (path.contains(separator)) {
      final originalPath = path;

      for (final layerPath in configuredDirs) {
        path = layerPath.apply(path, originalPath: originalPath);
      }
    }

    final file = fileSystem.file(join(targetDir, path));

    try {
      file.createSync(recursive: true);
    } catch (e) {
      print(e);
      return;
    }

    if (variables.isEmpty == true) {
      sourceFile.copySync(file.path);

      return;
    }

    var content = sourceFile.readAsStringSync();

    for (final variable in variables) {
      final pattern = RegExp('(.*)${variable.placeholder}' r'(\w*!?)(.*)');
      content = content.replaceAllMapped(pattern, (match) {
        final value = match.group(2);

        final loop = MustacheLoops.values.retrieve(value);
        if (loop != null) {
          return MustacheLoops.toMustache(variable.name, () => loop);
        }

        final format = MustacheFormat.values.retrieve('${value}Case');

        String result;
        if (format == null) {
          result = variable.formattedName;
        } else {
          result = variable.formatName(format);
        }

        final prefix = match.group(1) ?? '';
        final suffix = match.group(3) ?? '';

        return '$prefix$result$suffix';
      });
    }

    file.writeAsStringSync(content);
  }

  @override
  List<Object?> get props => [
        path,
        variables.toList(),
        prefix,
        suffix,
        providedName,
      ];
}
