import 'package:brick_oven/domain/brick.dart';

/// returns the bricks or the error that occurred
/// when parsing the configuration file
class BrickOrError {
  /// returns the bricks or the error that occurred
  /// when parsing the configuration file
  const BrickOrError(this._bricks, this._error);

  final Set<Brick>? _bricks;
  final String? _error;

  /// the bricks of the configuration file
  Set<Brick> get bricks => _bricks!;

  /// the error that occurred while parsing the configuration file
  String get error => _error!;

  /// if the parsing the configuration file was successfull
  bool get isBricks => _bricks != null;

  /// if there was an error parsing the configuration file
  bool get isError => _error != null;
}
