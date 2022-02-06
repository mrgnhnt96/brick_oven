import 'package:brick_oven/domain/brick_arguments.dart';
import 'package:brick_oven/domain/brick_config.dart';

export 'package:brick_oven/domain/brick_arguments.dart';

/// runs the brick oven, generating bricks
Future<void> runBrickOven(BrickArguments arguments) async {
  await BrickConfig(arguments).writeMason();
}
