// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late CookAllBricks command;
  late Logger mockLogger;
  late FileSystem memoryFileSystem;
  late Analytics mockAnalytics;
  late Brick mockBrick;

  setUp(() {
    mockBrick = MockBrick();
    mockLogger = MockLogger();
    mockAnalytics = MockAnalytics()..stubMethods();

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

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    test('name displays correctly', () {
      expect(command.name, 'all');

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockAnalytics);
    });

    group('#run', () {
      group('gracefully', () {
        test('when shouldSync and isWatch are default values', () async {
          final command = TestCookAllBricks(
            analytics: mockAnalytics,
            bricksOrError: BricksOrError({mockBrick}, null),
            logger: mockLogger,
            fileSystem: memoryFileSystem,
          );

          final result = await command.run();

          verifyInOrder([
            mockLogger.preheat,
            mockBrick.cook,
            mockLogger.dingDing,
          ]);

          verify(
            () => mockAnalytics.sendEvent(
              'cook',
              'all',
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

          expect(result, ExitCode.success.code);

          verifyNoMoreInteractions(mockBrick);
          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockAnalytics);
        });

        group('when #shouldSync', () {
          test('is false', () async {
            final command = TestCookAllBricks(
              analytics: mockAnalytics,
              bricksOrError: BricksOrError({mockBrick}, null),
              logger: mockLogger,
              shouldSync: false,
              fileSystem: memoryFileSystem,
            );

            final result = await command.run();

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
                'all',
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

            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);
            verifyNoMoreInteractions(mockAnalytics);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final command = TestCookAllBricks(
              analytics: mockAnalytics,
              bricksOrError: BricksOrError({mockBrick}, null),
              logger: mockLogger,
              shouldSync: true,
              fileSystem: memoryFileSystem,
            );

            final result = await command.run();

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
                'all',
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

            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);
            verifyNoMoreInteractions(mockAnalytics);

            expect(result, ExitCode.success.code);
          });
        });

        group('when #isWatch', () {
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
            final command = TestCookAllBricks(
              analytics: mockAnalytics,
              bricksOrError: BricksOrError({mockBrick}, null),
              logger: mockLogger,
              isWatch: false,
              fileSystem: memoryFileSystem,
              keyPressListener: keyPressListener,
            );

            final result = await command.run();

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
                'all',
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

            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);
            verifyNoMoreInteractions(mockAnalytics);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final command = TestCookAllBricks(
              analytics: mockAnalytics,
              bricksOrError: BricksOrError({mockBrick}, null),
              logger: mockLogger,
              isWatch: true,
              fileSystem: memoryFileSystem,
              keyPressListener: keyPressListener,
            );

            final runResult = await command.run();

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
                'all',
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

            verifyNoMoreInteractions(mockLogger);
            verifyNoMoreInteractions(mockBrick);
            verifyNoMoreInteractions(mockAnalytics);

            final result = await exitCompleter.future;

            expect(result, ExitCode.success.code);
            expect(runResult, ExitCode.success.code);
          });
        });
      });

      test('when error occurs when parsing bricks', () async {
        final command = TestCookAllBricks(
          analytics: mockAnalytics,
          bricksOrError: const BricksOrError(null, 'error'),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await command.run();

        verify(() => mockLogger.err('error')).called(1);

        expect(result, ExitCode.config.code);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('when unknown error occurs', () async {
        when(() => mockBrick.name).thenReturn('BRICK');
        when(() => mockBrick.cook()).thenThrow(Exception('error'));

        final command = TestCookAllBricks(
          analytics: mockAnalytics,
          bricksOrError: BricksOrError({mockBrick}, null),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await command.run();

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
            'all',
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

        verify(() => mockBrick.name).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockBrick);
        verifyNoMoreInteractions(mockAnalytics);

        expect(result, ExitCode.success.code);
      });

      test('when config error occurs', () async {
        when(() => mockBrick.name).thenReturn('BRICK');
        when(() => mockBrick.cook())
            .thenThrow(const BrickException(brick: 'BRICK', reason: 'error'));

        final command = TestCookAllBricks(
          analytics: mockAnalytics,
          bricksOrError: BricksOrError({mockBrick}, null),
          logger: mockLogger,
          fileSystem: memoryFileSystem,
        );

        final result = await command.run();

        verifyInOrder([
          mockLogger.preheat,
          mockBrick.cook,
          () => mockLogger.warn(
                'Invalid brick config: "BRICK"\n'
                'Reason: error',
              ),
          () => mockLogger.err('Could not cook brick: BRICK'),
          mockLogger.dingDing,
        ]);

        verify(
          () => mockAnalytics.sendEvent(
            'cook',
            'all',
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

        verify(() => mockBrick.name).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockBrick);
        verifyNoMoreInteractions(mockAnalytics);
      });
    });
  });
}

class TestCookAllBricks extends CookAllBricks {
  TestCookAllBricks({
    required Logger logger,
    required FileSystem fileSystem,
    this.bricksOrError,
    bool? isWatch,
    bool? shouldSync,
    Map<String, dynamic>? argResults,
    required Analytics analytics,
    KeyPressListener? keyPressListener,
  })  : _argResults = argResults ?? <String, dynamic>{},
        _isWatch = isWatch,
        _shouldSync = shouldSync,
        super(
          logger: logger,
          fileSystem: fileSystem,
          analytics: analytics,
          keyPressListener: keyPressListener,
        );

  final Map<String, dynamic> _argResults;

  final BricksOrError? bricksOrError;
  final bool? _isWatch;
  final bool? _shouldSync;

  @override
  bool get isWatch => _isWatch ?? super.isWatch;

  @override
  bool get shouldSync => _shouldSync ?? super.shouldSync;

  @override
  BricksOrError bricks() => bricksOrError ?? const BricksOrError({}, null);

  @override
  Future<bool> watchForConfigChanges(
    String _, {
    FutureOr<void> Function()? onChange,
  }) async {
    return true;
  }

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
