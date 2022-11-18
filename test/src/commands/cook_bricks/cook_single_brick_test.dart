import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';

void main() {
  late CookSingleBrick cookSingleBrickCommand;
  late Brick brick;
  late Logger mockLogger;
  late Progress mockProgress;
  late Analytics mockAnalytics;

  setUp(() {
    mockLogger = MockLogger();
    mockAnalytics = MockAnalytics()..stubMethods();
    mockProgress = MockProgress();

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    brick = Brick(
      source: BrickSource(localPath: 'path/to/first'),
      name: 'first',
      logger: mockLogger,
    );

    cookSingleBrickCommand = CookSingleBrick(
      brick,
      fileSystem: MemoryFileSystem(),
      logger: mockLogger,
      analytics: mockAnalytics,
    );
  });

  group('$CookSingleBrick', () {
    test('description displays correctly', () {
      expect(
        cookSingleBrickCommand.description,
        'Cook the brick: ${brick.name}',
      );
    });

    test('name is cook', () {
      expect(cookSingleBrickCommand.name, brick.name);
    });
  });

  group('brick_oven cook', () {
    late Brick mockBrick;
    late Stdin mockStdin;
    late FileSystem memoryFileSystem;
    late TestFileWatcher testFileWatcher;
    late TestDirectoryWatcher testDirectoryWatcher;

    setUp(() {
      mockBrick = MockBrick();
      mockStdin = MockStdin();
      memoryFileSystem = MemoryFileSystem();
      testFileWatcher = TestFileWatcher();
      testDirectoryWatcher = TestDirectoryWatcher();

      when(() => mockStdin.hasTerminal).thenReturn(true);

      when(() => mockBrick.source).thenReturn(
        BrickSource.memory(
          localPath: '',
          fileSystem: memoryFileSystem,
          watcher: BrickWatcher.config(
            dirPath: '',
            watcher: testDirectoryWatcher,
          ),
        ),
      );
    });

    tearDown(() {
      testFileWatcher.close();
      testDirectoryWatcher.close();
    });

    group('#run', () {
      test('gracefully', () async {
        final runner = CookSingleBrick(
          mockBrick,
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await runner.run();

        verify(mockLogger.preheat).called(1);
        verify(mockBrick.cook).called(1);
        verify(mockLogger.dingDing).called(1);

        verify(
          () => mockAnalytics.sendEvent(
            'cook',
            'one',
            label: 'no-watch',
            value: 0,
            parameters: {
              'bricks': '1',
              'sync': 'true',
            },
          ),
        ).called(1);

        verify(
          () => mockAnalytics.waitForLastPing(
            timeout: any(named: 'timeout'),
          ),
        ).called(1);

        expect(result, ExitCode.success.code);
      });

      test('logs when unknown error occurs', () async {
        when(mockBrick.cook).thenThrow(Exception('error'));
        when(() => mockBrick.name).thenReturn('BRICK');

        final runner = CookSingleBrick(
          mockBrick,
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await runner.run();

        verify(mockLogger.preheat).called(1);
        verify(mockBrick.cook).called(1);
        verify(mockLogger.dingDing).called(1);

        verify(() => mockLogger.err('Could not cook brick: BRICK')).called(1);
        verify(() => mockLogger.warn('Unknown error: Exception: error'));

        verify(
          () => mockAnalytics.sendEvent(
            'cook',
            'one',
            label: 'no-watch',
            value: 0,
            parameters: {
              'bricks': '1',
              'sync': 'true',
            },
          ),
        ).called(1);

        verify(
          () => mockAnalytics.waitForLastPing(
            timeout: any(named: 'timeout'),
          ),
        ).called(1);

        expect(result, ExitCode.success.code);
      });

      test('logs when config error occurs', () async {
        when(mockBrick.cook)
            .thenThrow(const BrickException(brick: 'BRICK', reason: 'error'));
        when(() => mockBrick.name).thenReturn('BRICK');

        final runner = CookSingleBrick(
          mockBrick,
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await runner.run();

        verify(mockLogger.preheat).called(1);
        verify(mockBrick.cook).called(1);
        verify(mockLogger.dingDing).called(1);

        verify(() => mockLogger.err('Could not cook brick: BRICK')).called(1);
        verify(
          () => mockLogger.warn('Invalid brick config: "BRICK"\nReason: error'),
        );

        verify(
          () => mockAnalytics.sendEvent(
            'cook',
            'one',
            label: 'no-watch',
            value: 0,
            parameters: {
              'bricks': '1',
              'sync': 'true',
            },
          ),
        ).called(1);

        verify(
          () => mockAnalytics.waitForLastPing(
            timeout: any(named: 'timeout'),
          ),
        ).called(1);

        expect(result, ExitCode.success.code);
      });
    });
  });
}
