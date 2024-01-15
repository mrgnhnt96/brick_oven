import 'package:brick_oven/utils/constants.dart';
import 'package:glob/glob.dart';

/// checks if the path should be excluded
bool shouldExcludePath(
  String path,
  Iterable<String> exclude,
) {
  for (final pattern in {
    ...exclude,
    ...Constants.excludedDirs,
  }) {
    if (Glob(pattern).matches(path)) {
      return true;
    }
  }

  return false;
}
