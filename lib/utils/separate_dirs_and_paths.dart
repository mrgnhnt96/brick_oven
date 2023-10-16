import 'package:path/path.dart';

/// separates the directories and files from the provided [paths]
(List<String> dirs, List<String> files) separateDirsAndPaths(
  Iterable<String> paths,
) {
  final dirs = <String>[];
  final files = <String>[];

  for (final e in paths) {
    final path = normalize(e);

    if (extension(path).isNotEmpty) {
      files.add(path);
    } else {
      dirs.add(path);
    }
  }

  return (dirs, files);
}
