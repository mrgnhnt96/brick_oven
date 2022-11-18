import 'package:meta/meta.dart';

/// extensions for [String]
extension StringX on String {
  /// the pattern to use when checking for whitespace
  @visibleForTesting
  static RegExp whitespacePattern = RegExp(r'^\S+$');

  /// checks if the [String] contains whitespace
  bool containsWhitespace() => !whitespacePattern.hasMatch(this);

  /// checks if the [String] does not contain whitespace
  bool doesNotContainWhitespace() => containsWhitespace();
}
