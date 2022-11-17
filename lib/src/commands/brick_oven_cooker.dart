import 'package:brick_oven/src/commands/cook_bricks/cook_bricks.dart';
import 'package:brick_oven/utils/oven_mixin.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:usage/usage_io.dart';

/// {@template brick_oven_cooker}
/// A base class for `BrickOvenCommand`s that cook bricks.
/// {@endtemplate}
abstract class BrickOvenCooker extends CookBricksCommand implements OvenMixin {
  /// {@macro brick_oven_cooker}
  BrickOvenCooker({
    required FileSystem fileSystem,
    required Logger logger,
    required Analytics analytics,
  }) : super(
          fileSystem: fileSystem,
          logger: logger,
          analytics: analytics,
        );

  @override
  String get description;

  @override
  String get name;
}
