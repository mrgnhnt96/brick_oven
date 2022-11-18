import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';
import 'package:watcher/watcher.dart';

import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late CookAllBricks command;
  late Logger mockLogger;
  late Progress mockProgress;
  late FileSystem memoryFileSystem;
  late Analytics mockAnalytics;

  setUp(() {
    mockLogger = MockLogger();
    mockProgress = MockProgress();
    mockAnalytics = MockAnalytics()..stubMethods();

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    memoryFileSystem = MemoryFileSystem();

    command = CookAllBricks(
      logger: mockLogger,
      fileSystem: memoryFileSystem,
      analytics: mockAnalytics,
    );
  });

  group('$CookAllBricks', () {
    test('description displays correctly', () {
      expect(command.description, 'Cook all bricks');
    });

    test('name displays correctly', () {
      expect(command.name, 'all');
    });

    group('#run', () {
      test('gracefully', () async {
        final command = TestCookAllBricks(
          analytics: mockAnalytics,
          bricksOrError: const BrickOrError({}, null),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await command.run();

        expect(result, ExitCode.success.code);
      });

      test('returns ${ExitCode.config.code} when bricks returns an error',
          () async {
        final command = TestCookAllBricks(
          analytics: mockAnalytics,
          bricksOrError: const BrickOrError(null, 'error'),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await command.run();

        expect(result, ExitCode.config.code);
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
    required Analytics analytics,
  })  : _argResults = argResults ?? <String, dynamic>{},
        super(
          logger: logger,
          fileSystem: fileSystem,
          analytics: analytics,
        );

  final Map<String, dynamic> _argResults;
  final List<FileWatcher?>? fileWatchers;
  final BrickOrError? bricksOrError;

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
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
