import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/exception.dart';

void main() {
  test('$BrickOvenException can be instanciated', () {
    expect(() => const BrickOvenException('test'), returnsNormally);
  });

  group('$BrickOvenNotFoundException', () {
    test('can be instanciated', () {
      expect(const BrickOvenNotFoundException(), isA<BrickOvenException>());

      expect(() => const BrickOvenNotFoundException(), returnsNormally);
    });

    test('has the correct message', () {
      expect(
        const BrickOvenNotFoundException().message,
        'Cannot find ${BrickOvenYaml.file}.'
        '\nDid you forget to run brick_oven init?',
      );
    });
  });

  group('$BrickNotFoundException', () {
    test('can be instanciated', () {
      expect(const BrickNotFoundException('brick'), isA<BrickOvenException>());

      expect(() => const BrickNotFoundException('brick'), returnsNormally);
    });

    test('has the correct message', () {
      const brick = 'test';
      expect(
        const BrickNotFoundException(brick).message,
        'Cannot find $brick.\n'
        'Make sure to provide a valid brick name '
        'from the ${BrickOvenYaml.file}.',
      );
    });
  });

  group('$UnknownKeysException', () {
    test('can be instanciated', () {
      expect(UnknownKeysException(['test'], 'loc'), isA<BrickOvenException>());

      expect(() => UnknownKeysException(['test'], 'loc'), returnsNormally);
    });

    test('has the correct message', () {
      const keys = ['test', 'test2'];
      const location = 'location';
      expect(
        UnknownKeysException(keys, location).message,
        'Unknown keys: ${keys.join(', ')}, in $location',
      );
    });
  });

  group('$MaxUpdateException', () {
    test('can be instanciated', () {
      expect(const MaxUpdateException(1), isA<BrickOvenException>());

      expect(() => const MaxUpdateException(1), returnsNormally);
    });

    test('has the correct message', () {
      expect(
        const MaxUpdateException(1).message,
        'Reached the maximum number of updates (1) allowed.',
      );
    });
  });
}
