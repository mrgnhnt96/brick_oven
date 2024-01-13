/// A collection of regular expressions used by the package.
class Patterns {
  const Patterns._();

  /// Matches a path separator that is not preceded by one or
  /// more opening curly braces.
  static final pathSeparator = RegExp(r'(?<!{+)[\/\\]');

  /// the pattern to remove all preceding and trailing slashes
  static final leadingAndTrailingSlash = RegExp(r'^[\/\\]+|[\/\\]+$');
}
