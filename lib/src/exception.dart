import 'package:brick_oven/domain/brick_oven_yaml.dart';

/// {@template brick_oven_exception}
/// An exception thrown by an internal brick oven command.
/// {@endtemplate}
class BrickOvenException implements Exception {
  /// {@macro brick_oven_exception}
  const BrickOvenException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;

  @override
  String toString() => message;
}

/// {@template brick_oven_not_found_exception}
/// An exception thrown when a brick oven configuration file is not found.
/// {@endtemplate}
class BrickOvenNotFoundException extends BrickOvenException {
  /// {@macro brick_oven_not_found_exception}
  const BrickOvenNotFoundException()
      // coverage:ignore-start
      : super(
          // coverage:ignore-end
          'Cannot find ${BrickOvenYaml.file}.'
          '\nCreate the file and try again.',
        );
}

/// {@template brick_oven_not_found_exception}
/// An exception thrown when a brick is not found.
/// {@endtemplate}
class BrickNotFoundException extends BrickOvenException {
  /// {@macro brick_oven_not_found_exception}
  const BrickNotFoundException(String brick)
      // coverage:ignore-start
      : super(
          // coverage:ignore-end
          'Cannot find $brick.\n'
          'Make sure to provide a valid brick name '
          'from the ${BrickOvenYaml.file}.',
        );
}

/// {@template unknown_keys_exception}
/// An exception thrown when an unknown key is found in a brick oven
/// configuration file.
/// {@endtemplate}
class UnknownKeysException extends BrickOvenException {
  /// {@macro unknown_keys_exception}
  UnknownKeysException(
    Iterable<String> keys,
    String location,
  ) : super('Unknown keys: ${keys.join(', ')}, in $location');
}

/// {@template config_exception}
/// An exception thrown when a configuration is invalid.
/// {@endtemplate}
abstract class ConfigException implements BrickOvenException {
  @override
  String toString() => message;
}

/// {@template variable_exception}
/// An exception thrown when a variable is not configured correctly.
/// {@endtemplate}
class VariableException implements ConfigException {
  /// {@macro variable_exception}
  const VariableException({
    required this.variable,
    required this.reason,
  });

  /// the reason the variable is not configured correctly
  final String reason;

  /// the variable that is not configured correctly
  final String variable;

  @override
  String get message => 'Variable "$variable" is invalid -- $reason';
}

/// {@template directory_exception}
/// An exception thrown when a directory is not configured correctly.
/// {@endtemplate}
class DirectoryException implements ConfigException {
  /// {@macro directory_exception}
  const DirectoryException({
    required this.directory,
    required this.reason,
  });

  /// the directory that is not configured correctly
  final String directory;

  /// the reason the directory is not configured correctly
  final String reason;

  @override
  String get message =>
      'Invalid directory config: "$directory"\nReason: $reason';
}

/// {@template source_exception}
/// An exception thrown when a source is not configured correctly.
/// {@endtemplate}
class SourceException implements ConfigException {
  /// {@macro source_exception}
  const SourceException({
    required this.source,
    required this.reason,
  });

  /// the reason the source is not configured correctly
  final String reason;

  /// the source that is not configured correctly
  final String source;

  @override
  String get message => 'Invalid source config: "$source"\nReason: $reason';
}

/// {@template directory_exception}
/// An exception thrown when a brick is not configured correctly.
/// {@endtemplate}
class BrickException implements ConfigException {
  /// {@macro directory_exception}
  const BrickException({
    required this.brick,
    required this.reason,
  });

  /// the directory that is not configured correctly
  final String brick;

  /// the reason the directory is not configured correctly
  final String reason;

  @override
  String get message => 'Invalid brick config: "$brick"\nReason: $reason';
}

/// {@template config_exception}
/// An exception thrown when a configuration is setup incorrectly.
/// {@endtemplate}
class FileException implements ConfigException {
  /// {@macro config_exception}
  const FileException({
    required this.file,
    required this.reason,
  });

  /// the file that is not configured correctly
  final String file;

  /// the reason the file is not configured correctly
  final String reason;

  @override
  String get message => 'Invalid file config: "$file"\nReason: $reason';
}
