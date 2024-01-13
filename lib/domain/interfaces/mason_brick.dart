import 'package:brick_oven/domain/interfaces/brick.dart';

/// {@template mason_brick}
/// The base class for a mason brick yaml file
/// {@endtemplate}
abstract class MasonBrick {
  /// the path to the brick's config file `brick.yaml`
  String? get path;

  /// Whether to validate the brick.yaml file. That all inputs
  /// are valid and consumed
  bool get shouldSync;

  /// Retrieves the brick.yaml file
  Map<dynamic, dynamic>? brickYamlContent();

  /// Validates the brick.yaml file
  void check(Brick brick);
}
