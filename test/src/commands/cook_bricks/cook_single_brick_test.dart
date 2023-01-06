// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';

void main() {
  late CookSingleBrick cookSingleBrickCommand;
  late Brick brick;
  late Logger mockLogger;
  late Analytics mockAnalytics;

  setUp(() {
    mockLogger = MockLogger();
    mockAnalytics = MockAnalytics()..stubMethods();

    brick = Brick(
      source: BrickSource(
        localPath: 'path/to/first',
        fileSystem: MemoryFileSystem(),
      ),
      name: 'first',
      logger: mockLogger,
      fileSystem: MemoryFileSystem(),
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

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
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
          watcher: SourceWatcher.config(
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
      group('gracefully', () {
        test('when shouldSync and isWatch are default values', () async {
          final runner = CookSingleBrick(
            mockBrick,
            analytics: mockAnalytics,
            logger: mockLogger,
            fileSystem: memoryFileSystem,
          );

          final result = await runner.run();

          verifyInOrder([
            mockLogger.preheat,
            mockBrick.cook,
            mockLogger.dingDing,
          ]);

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
            () =>
                mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
          ).called(1);

          verifyNoMoreInteractions(mockAnalytics);
          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockBrick);

          expect(result, ExitCode.success.code);
        });

        group('when shouldSync', () {
          test('is false', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              analytics: mockAnalytics,
              logger: mockLogger,
              fileSystem: memoryFileSystem,
              shouldSync: false,
            );

            final result = await runner.run();

            verifyInOrder([
              mockLogger.preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: false,
                    watch: false,
                  ),
              mockLogger.dingDing,
            ]);

            verify(
              () => mockAnalytics.sendEvent(
                'cook',
                'one',
                label: 'no-watch',
                value: 0,
                parameters: {
                  'bricks': '1',
                  'sync': 'false',
                },
              ),
            ).called(1);

            verify(
              () => mockAnalytics.waitForLastPing(
                timeout: BrickOvenRunner.timeout,
              ),
            ).called(1);

            verifyNoMoreInteractions(mockAnalytics);
            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              analytics: mockAnalytics,
              logger: mockLogger,
              fileSystem: memoryFileSystem,
              shouldSync: true,
            );

            final result = await runner.run();

            verifyInOrder([
              mockLogger.preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: false,
                  ),
              mockLogger.dingDing,
            ]);

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
                timeout: BrickOvenRunner.timeout,
              ),
            ).called(1);

            verifyNoMoreInteractions(mockAnalytics);
            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);

            expect(result, ExitCode.success.code);
          });
        });

        group('when isWatch', () {
          late Completer<int> exitCompleter;
          late KeyPressListener keyPressListener;

          setUp(() {
            exitCompleter = Completer<int>();

            final mockStdin = MockStdin();

            when(() => mockStdin.hasTerminal).thenReturn(true);

            when(mockStdin.asBroadcastStream).thenAnswer(
              (_) => Stream.fromIterable([
                'q'.codeUnits,
              ]),
            );

            keyPressListener = KeyPressListener(
              stdin: mockStdin,
              logger: mockLogger,
              toExit: exitCompleter.complete,
            );

            final mockBrickSource = MockBrickSource();
            final mockSourceWatcher = MockSourceWatcher();

            when(() => mockBrick.source).thenReturn(mockBrickSource);
            when(() => mockBrickSource.watcher).thenReturn(mockSourceWatcher);

            when(() => mockSourceWatcher.hasRun).thenAnswer((_) => true);
            when(mockSourceWatcher.start).thenAnswer((_) => Future.value());
            when(mockSourceWatcher.stop).thenAnswer((_) => Future.value());
          });

          tearDown(() {
            KeyPressListener.stream = null;
          });

          test('is false', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              analytics: mockAnalytics,
              logger: mockLogger,
              fileSystem: memoryFileSystem,
              isWatch: false,
              keyPressListener: keyPressListener,
            );

            final result = await runner.run();

            verifyInOrder([
              mockLogger.preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: false,
                  ),
              mockLogger.dingDing,
            ]);

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
                timeout: BrickOvenRunner.timeout,
              ),
            ).called(1);

            verifyNoMoreInteractions(mockAnalytics);
            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              analytics: mockAnalytics,
              logger: mockLogger,
              fileSystem: memoryFileSystem,
              isWatch: true,
              keyPressListener: keyPressListener,
            );

            final runResult = await runner.run();

            verify(() => mockBrick.configPath).called(1);
            verify(() => mockBrick.source).called(1);

            verifyInOrder([
              mockLogger.preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: true,
                  ),
              mockLogger.dingDing,
              mockLogger.watching,
              mockLogger.quit,
              mockLogger.reload,
              mockLogger.exiting,
            ]);

            verify(
              () => mockAnalytics.sendEvent(
                'cook',
                'one',
                label: 'watch',
                value: 0,
                parameters: {
                  'bricks': '1',
                  'sync': 'true',
                },
              ),
            ).called(1);

            verify(
              () => mockAnalytics.waitForLastPing(
                timeout: BrickOvenRunner.timeout,
              ),
            ).called(1);

            verifyNoMoreInteractions(mockAnalytics);
            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);

            final result = await exitCompleter.future;

            expect(result, ExitCode.success.code);
            expect(runResult, ExitCode.success.code);
          });
        });
      });

      test('when unknown error occurs', () async {
        when(mockBrick.cook).thenThrow(Exception('error'));
        when(() => mockBrick.name).thenReturn('BRICK');

        final runner = CookSingleBrick(
          mockBrick,
          analytics: mockAnalytics,
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await runner.run();

        verifyInOrder([
          mockLogger.preheat,
          mockBrick.cook,
          () => mockLogger.warn('Unknown error: Exception: error'),
          () => mockLogger.err('Could not cook brick: BRICK'),
          mockLogger.dingDing,
        ]);

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
          () => mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
        ).called(1);

        expect(result, ExitCode.success.code);
      });

      test('when config error occurs', () async {
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

        verifyInOrder([
          mockLogger.preheat,
          mockBrick.cook,
          () => mockLogger.warn('Invalid brick config: "BRICK"\nReason: error'),
          () => mockLogger.err('Could not cook brick: BRICK'),
          mockLogger.dingDing,
        ]);

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
          () => mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
        ).called(1);

        expect(result, ExitCode.success.code);
      });
    });
  });
}

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick(
    Brick brick, {
    required FileSystem fileSystem,
    required Analytics analytics,
    required Logger logger,
    bool? isWatch,
    bool? shouldSync,
    KeyPressListener? keyPressListener,
  })  : _isWatch = isWatch,
        _shouldSync = shouldSync,
        super(
          brick,
          fileSystem: fileSystem,
          analytics: analytics,
          logger: logger,
          keyPressListener: keyPressListener,
        );

  final bool? _isWatch;
  final bool? _shouldSync;

  @override
  bool get isWatch => _isWatch ?? super.isWatch;

  @override
  bool get shouldSync => _shouldSync ?? super.shouldSync;

  @override
  Future<bool> watchForConfigChanges(
    String _, {
    FutureOr<void> Function()? onChange,
  }) async {
    return true;
  }
}
