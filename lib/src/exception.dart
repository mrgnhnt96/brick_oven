/// {@template brick_oven_exception}
/// An exception thrown by an internal brick oven command.
/// {@endtemplate}
class BrickOvenException implements Exception {
  /// {@macro brick_oven_exception}
  const BrickOvenException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;
}

/// {@template config_exception}
/// An exception thrown when a configuration is invalid.
/// {@endtemplate}
abstract class ConfigException implements BrickOvenException {}

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

/// {@template partial_exception}
/// An exception thrown when a partial is not configured correctly.
/// {@endtemplate}
class PartialException implements ConfigException {
  /// {@macro variable_exception}
  const PartialException({
    required this.partial,
    required this.reason,
  });

  /// the reason the partial is not configured correctly
  final String reason;

  /// the partial that is not configured correctly
  final String partial;

  @override
  String get message => 'Partial "$partial" is invalid -- $reason';
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

/// {@template url_exception}
/// An exception thrown when a URL is not configured correctly.
/// {@endtemplate}
class UrlException implements ConfigException {
  /// {@macro url_exception}
  const UrlException({
    required this.url,
    required this.reason,
  });

  /// the URL that is not configured correctly
  final String url;

  /// the reason the URL is not configured correctly
  final String reason;

  @override
  String get message => 'Invalid URL config: "$url"\nReason: $reason';
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

/// {@template file_exception}
/// An exception thrown when a file is setup incorrectly.
/// {@endtemplate}
class FileException implements ConfigException {
  /// {@macro config_file}
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

/// {@template brick_config_exception}
/// An exception thrown when a configuration is done incorrectly.
/// {@endtemplate}
class BrickConfigException implements ConfigException {
  /// {@macro brick_config_exception}
  const BrickConfigException({
    required this.reason,
  });

  /// the reason the brick is not configured correctly
  final String reason;

  @override
  String get message => reason;
}
