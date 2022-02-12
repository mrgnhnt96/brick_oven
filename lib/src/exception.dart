import 'package:brick_oven/domain/brick_oven_yaml.dart';

/// {@template brick_oven_exception}
/// An exception thrown by an internal brick oven command.
/// {@endtemplate}
class BrickOvenException implements Exception {
  /// {@macro brick_oven_exception}
  const BrickOvenException(this.message);

  /// The error message which will be displayed to the user via stderr.
  final String message;
}

/// {@template brick_oven_not_found_exception}
/// An exception thrown when a brick oven configuration file is not found.
/// {@endtemplate}
class BrickOvenNotFoundException extends BrickOvenException {
  /// {@macro brick_oven_not_found_exception}
  const BrickOvenNotFoundException()
      : super(
          'Cannot find ${BrickOvenYaml.file}.'
          '\nDid you forget to run brick_oven init?',
        );
}

/// {@template brick_oven_not_found_exception}
/// An exception thrown when a brick is not found.
/// {@endtemplate}
class BrickNotFoundException extends BrickOvenException {
  /// {@macro brick_oven_not_found_exception}
  const BrickNotFoundException(String brick)
      : super(
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
