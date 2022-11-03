import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:test/test.dart';

void main() {
  test('can be instanciated', () {
    expect(() => const BrickOrError(null, null), returnsNormally);
  });

  group('#bricks', () {
    test('return the bricks when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
        )
      };

      final brickOrError = BrickOrError(bricks, null);

      expect(brickOrError.bricks, bricks);
    });

    test('throws an error when value is error', () {
      const brickOrError = BrickOrError(null, 'error');

      expect(() => brickOrError.bricks, throwsA(isA<Error>()));
    });
  });

  group('#error', () {
    test('return the error when value is error', () {
      const brickOrError = BrickOrError(null, 'error');

      expect(brickOrError.error, 'error');
    });

    test('throws an error when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
        )
      };

      final brickOrError = BrickOrError(bricks, null);

      expect(() => brickOrError.error, throwsA(isA<Error>()));
    });
  });

  group('#isError', () {
    test('return true when value is error', () {
      const brickOrError = BrickOrError(null, 'error');

      expect(brickOrError.isError, true);
    });

    test('return false when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
        )
      };

      final brickOrError = BrickOrError(bricks, null);

      expect(brickOrError.isError, false);
    });
  });

  group('#isBricks', () {
    test('return true when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
        )
      };

      final brickOrError = BrickOrError(bricks, null);

      expect(brickOrError.isBricks, true);
    });

    test('return false when value is error', () {
      const brickOrError = BrickOrError(null, 'error');

      expect(brickOrError.isBricks, false);
    });
  });
}
