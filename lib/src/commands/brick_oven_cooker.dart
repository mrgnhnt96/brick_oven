import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template brick_oven_cooker}
/// A base class for `BrickOvenCommand`s that cook bricks.
/// {@endtemplate}
abstract class BrickOvenCooker extends BrickOvenCommand implements OvenMixin {
  /// {@macro brick_oven_cooker}
  BrickOvenCooker({
    FileSystem? fileSystem,
    required Logger logger,
  }) : super(
          fileSystem: fileSystem,
          logger: logger,
        );
}
