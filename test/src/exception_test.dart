import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:test/test.dart';

void main() {
  test('$BrickOvenException can be instanciated', () {
    expect(() => const BrickOvenException('test'), returnsNormally);
  });

  test('$BrickOvenNotFoundException has the correct message', () {
    expect(
      const BrickOvenNotFoundException().message,
      'Cannot find ${BrickOvenYaml.file}.'
      '\nDid you forget to run brick_oven init?',
    );
  });

  test('$BrickNotFoundException has the correct message', () {
    const brick = 'test';
    expect(
      const BrickNotFoundException(brick).message,
      'Cannot find $brick.\n'
      'Make sure to provide a valid brick name '
      'from the ${BrickOvenYaml.file}.',
    );
  });

  test('$UnknownKeysException has the correct message', () {
    const keys = ['test', 'test2'];
    const location = 'location';
    expect(
      UnknownKeysException(keys, location).message,
      'Unknown keys: ${keys.join(', ')}, in $location',
    );
  });

  test('$MaxUpdateException has the correct message', () {
    expect(
      const MaxUpdateException(1).message,
      'Reached the maximum number of updates (1) allowed.',
    );
  });
}
