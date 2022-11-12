import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late CookAllBricks command;
  late Logger mockLogger;
  late Progress mockProgress;
  late FileSystem memoryFileSystem;

  setUp(() {
    mockLogger = MockLogger();

    mockProgress = MockProgress();

    when(() => mockProgress.complete(any())).thenReturn(voidCallback());
    when(() => mockProgress.fail(any())).thenReturn(voidCallback());
    when(() => mockProgress.update(any())).thenReturn(voidCallback());

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    memoryFileSystem = MemoryFileSystem();

    command = CookAllBricks(
      logger: mockLogger,
      fileSystem: memoryFileSystem,
    );
  });

  group('$CookAllBricks', () {
    test('description displays correctly', () {
      expect(command.description, 'Cook all bricks');
    });

    test('name displays correctly', () {
      expect(command.name, 'all');
    });

    group('#isWatch', () {
      test('returns true when watch flag is provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'watch': true},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.isWatch, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'watch': false},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.isWatch, isFalse);
      });
    });

    group('#shouldSync', () {
      test('returns true when watch flag is provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'sync': true},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.shouldSync, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'sync': false},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.shouldSync, isFalse);
      });
    });

    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'output': 'output/dir'},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{},
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.outputDir, null);
      });
    });

    group('#run', () {
      test('returns ${ExitCode.config.code} when bricks returns an error', () {
        final command = TestCookAllBricks(
          bricksOrError: const BrickOrError(null, 'error'),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        expect(command.run(), completion(ExitCode.config.code));
      });

      test('returns gracefully', () {
        final command = TestCookAllBricks(
          bricksOrError: const BrickOrError({}, null),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
          putInOvenOverride: ExitCode.success,
        );

        expect(command.run(), completion(ExitCode.success.code));
      });
    });
  });
}

class TestCookAllBricks extends CookAllBricks {
  TestCookAllBricks({
    required Logger logger,
    required FileSystem fileSystem,
    this.bricksOrError,
    this.fileWatchers,
    Map<String, dynamic>? argResults,
    this.putInOvenOverride,
  })  : _argResults = argResults ?? <String, dynamic>{},
        super(
          logger: logger,
          fileSystem: fileSystem,
        );

  final Map<String, dynamic> _argResults;
  final List<FileWatcher?>? fileWatchers;
  final BrickOrError? bricksOrError;
  final ExitCode? putInOvenOverride;

  @override
  BrickOrError bricks() => bricksOrError ?? const BrickOrError({}, null);

  int _callCount = 0;

  @override
  FileWatcher watcher(String path) {
    if (fileWatchers != null && fileWatchers!.length > _callCount) {
      final mock = MockFileWatcher();
      when(() => mock.events).thenAnswer((_) => const Stream.empty());

      return fileWatchers![_callCount++] ?? mock;
    }
    return super.watcher(path);
  }

  @override
  Future<ExitCode> putInOven(Set<Brick> bricks) async {
    if (putInOvenOverride != null) {
      return putInOvenOverride!;
    }

    return super.putInOven(bricks);
  }

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
