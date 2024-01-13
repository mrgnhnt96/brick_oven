import 'package:glob/glob.dart';

/// checks if the path should be excluded
bool shouldExcludePath(
  String path,
  Iterable<String> exclude,
) {
  for (final pattern in exclude) {
    if (Glob(pattern).matches(path)) {
      return true;
    }
  }

  return false;
}
