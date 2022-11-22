import 'cook.dart';

/// [brickName] will be used for
/// - Accessing fixture files
///   - test/integration/fixtures/[brickName]
/// - Accessing source files
///   - test/integration/sources/[brickName]
/// - Accessing running command
///   - brick_oven cook [brickName]
Future<void> cookBrick(
  String brickName, {
  required int numberOfFiles,
}) async {
  await cook(
    brickName: brickName,
    command: brickName,
    numberOfFiles: numberOfFiles,
  );
}
