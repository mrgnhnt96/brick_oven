import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  test('can be instanciated', () {
    expect(() => const BricksOrError(null, null), returnsNormally);
  });

  group('#bricks', () {
    test('return the bricks when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
          logger: mockLogger,
        )
      };

      final brickOrError = BricksOrError(bricks, null);

      expect(brickOrError.bricks, bricks);

      verifyNoMoreInteractions(mockLogger);
    });

    test('throws an error when value is error', () {
      const brickOrError = BricksOrError(null, 'error');

      expect(() => brickOrError.bricks, throwsA(isA<Error>()));
    });
  });

  group('#error', () {
    test('return the error when value is error', () {
      const brickOrError = BricksOrError(null, 'error');

      expect(brickOrError.error, 'error');
    });

    test('throws an error when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
          logger: mockLogger,
        )
      };

      final brickOrError = BricksOrError(bricks, null);

      expect(() => brickOrError.error, throwsA(isA<Error>()));

      verifyNoMoreInteractions(mockLogger);
    });
  });

  group('#isError', () {
    test('return true when value is error', () {
      const brickOrError = BricksOrError(null, 'error');

      expect(brickOrError.isError, true);
    });

    test('return false when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
          logger: mockLogger,
        )
      };

      final brickOrError = BricksOrError(bricks, null);

      expect(brickOrError.isError, false);

      verifyNoMoreInteractions(mockLogger);
    });
  });

  group('#isBricks', () {
    test('return true when value is bricks', () {
      final bricks = {
        Brick(
          name: 'brick',
          source: BrickSource.fromString('source'),
          logger: mockLogger,
        )
      };

      final brickOrError = BricksOrError(bricks, null);

      expect(brickOrError.isBricks, true);

      verifyNoMoreInteractions(mockLogger);
    });

    test('return false when value is error', () {
      const brickOrError = BricksOrError(null, 'error');

      expect(brickOrError.isBricks, false);
    });
  });
}
