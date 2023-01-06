import 'package:autoequal/autoequal.dart';
import 'package:equatable/equatable.dart';

import 'package:brick_oven/domain/brick.dart';

part 'bricks_or_error.g.dart';

/// returns the bricks or the error that occurred
/// when parsing the configuration file
@autoequal
class BricksOrError extends Equatable {
  /// returns the bricks or the error that occurred
  /// when parsing the configuration file
  const BricksOrError(this._bricks, this._error);

  final Set<Brick>? _bricks;
  final String? _error;

  /// the bricks of the configuration file
  Set<Brick> get bricks => _bricks!;

  /// the error that occurred while parsing the configuration file
  String get error => _error!;

  /// if the parsing the configuration file was successful
  bool get isBricks => _bricks != null;

  /// if there was an error parsing the configuration file
  bool get isError => _error != null;

  @override
  List<Object?> get props => _$props;
}
