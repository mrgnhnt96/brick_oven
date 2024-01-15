import 'package:path/path.dart' as p;

import 'package:brick_oven/domain/implementations/include_impl.dart';
import 'package:brick_oven/domain/implementations/name_impl.dart';
import 'package:brick_oven/domain/interfaces/directory.dart';
import 'package:brick_oven/domain/interfaces/include.dart';
import 'package:brick_oven/domain/interfaces/name.dart';
import 'package:brick_oven/utils/patterns.dart';

///{@macro directory}
class DirectoryImpl extends Directory {
  ///{@macro directory}
  DirectoryImpl(super.config, {required this.path})
      : name = config.nameConfig == null
            ? null
            : NameImpl(
                config.nameConfig!,
                originalName: p.basename(path),
              ),
        include = config.includeConfig == null
            ? null
            : IncludeImpl(config.includeConfig!);

  @override
  final String path;

  @override
  final Name? name;

  @override
  final Include? include;

  @override
  String apply(String path, {required String pathWithoutSourceDir}) {
    final originalParts = _separatePath(pathWithoutSourceDir);
    final configuredParts = _separatePath(this.path);

    for (var i = 0;; i++) {
      if (i >= originalParts.length) {
        if (i >= configuredParts.length) {
          break;
        }

        return path;
      }

      if (i >= configuredParts.length) {
        break;
      }

      final pathPart = originalParts[i];
      final configuredPart = configuredParts[i];

      if (pathPart != configuredPart) {
        return path;
      }
    }

    final index = configuredParts.length - 1;
    final pathParts = _separatePath(_cleanPath(path));

    final nameFormatted = name?.format();
    if (nameFormatted != null) {
      pathParts[index] = nameFormatted;
    }

    if (include != null) {
      pathParts[index] = include!.apply(pathParts[index]);
    }

    final configuredPath = p.joinAll(pathParts);

    return configuredPath;
  }

  List<String> _separatePath(String path) {
    final cleanPath = _cleanPath(path);
    final pathParts = cleanPath.split(Patterns.pathSeparator)
      ..removeWhere((part) => part.isEmpty);

    return pathParts;
  }

  String _cleanPath(String path) {
    if (path == './' || path == '.' || path == r'.\') {
      return '';
    }

    final str = p.normalize(path);

    return str.replaceAll(Patterns.leadingAndTrailingSlash, '');
  }
}
