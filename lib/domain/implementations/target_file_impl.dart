import 'package:file/file.dart' hide Directory;
import 'package:path/path.dart' as p;

import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/implementations/include_impl.dart';
import 'package:brick_oven/domain/implementations/name_impl.dart';
import 'package:brick_oven/domain/implementations/variable_impl.dart';
import 'package:brick_oven/domain/interfaces/brick.dart';
import 'package:brick_oven/domain/interfaces/directory.dart';
import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/domain/interfaces/target_file.dart';
import 'package:brick_oven/domain/interfaces/url.dart';
import 'package:brick_oven/domain/interfaces/variable.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/file_replacements.dart';
import 'package:brick_oven/utils/patterns.dart';

/// {@macro target_file}
class TargetFileImpl extends TargetFile with FileReplacements {
  /// {@macro target_file}
  TargetFileImpl(
    super.config, {
    required this.sourcePath,
    required this.targetDir,
    required this.pathWithoutSourceDir,
  })  : name = config?.nameConfig == null
            ? null
            : config!.nameConfig!.isObject
                ? NameImpl(
                    config.nameConfig!.object!,
                    originalName: p.basename(pathWithoutSourceDir),
                  )
                : null,
        include = config?.includeConfig == null
            ? null
            : IncludeImpl(config!.includeConfig!);

  @override
  final String sourcePath;

  @override
  final String targetDir;

  @override
  final Name? name;

  @override
  final String pathWithoutSourceDir;

  @override
  final Include? include;

  @override
  String get extension => p.extension(sourcePath);

  @override
  FileWriteResult write({
    required Brick brick,
    required Set<Variable> outOfFileVariables,
  }) {
    final targetPathConfig = configurePath(
      urls: brick.urls,
      dirs: brick.directories,
    );

    final targetPath = p.join(targetDir, targetPathConfig.content);

    if (targetPathConfig.data['url'] != null) {
      di<FileSystem>().file(targetPath).createSync(recursive: true);
      return FileWriteResult(
        usedVariables: targetPathConfig.used,
        usedPartials: const {},
      );
    }

    try {
      final configuredVariables = [
        for (final MapEntry(key: placeholder, value: variable)
            in (variableConfig ?? {}).entries)
          VariableImpl(
            name: variable ?? placeholder,
            placeholder: placeholder,
          ),
      ];

      final writeResult = writeFile(
        targetPath: targetPath,
        sourcePath: sourcePath,
        variables: configuredVariables,
        outOfFileVariables: outOfFileVariables,
        partials: brick.partials,
      );

      return FileWriteResult(
        usedPartials: writeResult.usedPartials,
        usedVariables: {
          ...writeResult.usedVariables,
          ...targetPathConfig.used,
        },
      );
    } catch (e) {
      if (e is ConfigException) {
        throw FileException(
          file: sourcePath,
          reason: e.message,
        );
      }
      throw FileException(
        file: sourcePath,
        reason: e.toString(),
      );
    }
  }

  @override
  String formatName() {
    final name = this.name?.format(trailing: extension) ??
        p.basename(pathWithoutSourceDir);

    return include?.apply(name) ?? name;
  }

  @override
  ContentReplacement configurePath({
    required Iterable<Url> urls,
    required Iterable<Directory> dirs,
  }) {
    final variablesUsed = <String>{};

    var newPath = pathWithoutSourceDir;
    newPath = newPath.replaceAll(p.basename(newPath), '');

    Url? url;
    final urlPaths = {
      for (final url in urls) url.path: url,
    };

    if (urlPaths.containsKey(sourcePath)) {
      url = urlPaths[sourcePath];
      variablesUsed.addAll(url!.vars);

      newPath = p.join(newPath, url.formatName());
      variablesUsed.addAll(url.name?.vars ?? []);
    } else {
      newPath = p.join(newPath, formatName());
      variablesUsed
        ..addAll(name?.vars ?? [])
        ..addAll(include?.vars ?? []);
    }

    variablesUsed.addAll(name?.vars ?? []);

    if (Patterns.pathSeparator.hasMatch(newPath)) {
      for (final configDir in dirs) {
        final comparePath = newPath;
        newPath = configDir.apply(
          newPath,
          pathWithoutSourceDir: pathWithoutSourceDir,
        );

        if (newPath != comparePath) {
          variablesUsed.addAll(configDir.vars);
        }
      }
    }

    return ContentReplacement(
      content: newPath,
      used: variablesUsed,
      data: {
        'url': url,
      },
    );
  }
}
