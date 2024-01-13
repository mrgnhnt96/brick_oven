/// {@template variable}
/// A variable found within a file
/// {@endtemplate}
abstract class Variable {
  /// The name of the variable
  String get name;

  /// The placeholder, or content to be replaced with [name]
  String get placeholder;
}
