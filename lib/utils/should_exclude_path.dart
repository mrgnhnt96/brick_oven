import 'package:path/path.dart';

/// checks if the path should be excluded
bool shouldExcludePath(
  String path,
  List<String> excludedDirs,
  List<String> excludedFiles,
) {
  if (excludedFiles.contains(path)) {
    return true;
  }

  for (final dir in excludedDirs) {
    final segments = split(path);
    if (segments.contains(dir)) {
      return true;
    }
  }

  return false;
}
