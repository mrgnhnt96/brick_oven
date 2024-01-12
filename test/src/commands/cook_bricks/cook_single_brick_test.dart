// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:io';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/di.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../test_utils/di.dart';
import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';

void main() {
  late CookSingleBrick cookSingleBrickCommand;
  late Brick brick;

  setUp(() {
    setupTestDi();

    brick = Brick(
      source: BrickSource(
        localPath: 'path/to/first',
      ),
      name: 'first',
    );

    cookSingleBrickCommand = CookSingleBrick(
      brick,
    );
  });

  group('$CookSingleBrick', () {
    test('description displays correctly', () {
      expect(
        cookSingleBrickCommand.description,
        'Cook the brick: ${brick.name}',
      );

      verifyNoMoreInteractions(di<Logger>());
    });

    test('name is cook', () {
      expect(cookSingleBrickCommand.name, brick.name);
    });
  });

  group('brick_oven cook', () {
    late Brick mockBrick;
    late Stdin mockStdin;
    late TestFileWatcher testFileWatcher;
    late TestDirectoryWatcher testDirectoryWatcher;

    setUp(() {
      mockBrick = MockBrick();
      mockStdin = MockStdin();
      testFileWatcher = TestFileWatcher();
      testDirectoryWatcher = TestDirectoryWatcher();

      when(() => mockStdin.hasTerminal).thenReturn(true);

      when(() => mockBrick.source).thenReturn(
        BrickSource.memory(
          localPath: '',
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
          );

          final result = await runner.run();

          verifyInOrder([
            di<Logger>().preheat,
            mockBrick.cook,
            di<Logger>().dingDing,
          ]);

          verifyNoMoreInteractions(di<Logger>());
          verifyNoMoreInteractions(mockBrick);

          expect(result, ExitCode.success.code);
        });

        group('when shouldSync', () {
          test('is false', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              shouldSync: false,
            );

            final result = await runner.run();

            verifyInOrder([
              di<Logger>().preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: false,
                    watch: false,
                  ),
              di<Logger>().dingDing,
            ]);

            verifyNoMoreInteractions(di<Logger>());
            verifyNoMoreInteractions(mockBrick);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              shouldSync: true,
            );

            final result = await runner.run();

            verifyInOrder([
              di<Logger>().preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: false,
                  ),
              di<Logger>().dingDing,
            ]);

            verifyNoMoreInteractions(di<Logger>());
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
              toExit: exitCompleter.complete,
            );

            final mockBrickSource = MockBrickSource();
            final mockSourceWatcher = MockSourceWatcher();

            when(() => mockBrick.source).thenReturn(mockBrickSource);
            when(() => mockBrickSource.watcher).thenReturn(mockSourceWatcher);

            when(() => mockSourceWatcher.hasRun).thenAnswer((_) => true);
            when(() => mockSourceWatcher.start(any()))
                .thenAnswer((_) => Future.value());
            when(mockSourceWatcher.stop).thenAnswer((_) => Future.value());
          });

          tearDown(() {
            KeyPressListener.stream = null;
          });

          test('is false', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              isWatch: false,
              keyPressListener: keyPressListener,
            );

            final result = await runner.run();

            verifyInOrder([
              di<Logger>().preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: false,
                  ),
              di<Logger>().dingDing,
            ]);

            verifyNoMoreInteractions(di<Logger>());
            verifyNoMoreInteractions(mockBrick);

            expect(result, ExitCode.success.code);
          });

          test('is true', () async {
            final runner = TestCookSingleBrick(
              mockBrick,
              isWatch: true,
              keyPressListener: keyPressListener,
            );

            final runResult = await runner.run();

            verify(() => mockBrick.configPath).called(1);
            verify(() => mockBrick.source).called(1);

            verifyInOrder([
              di<Logger>().preheat,
              () => mockBrick.cook(
                    output: any(named: 'output'),
                    shouldSync: true,
                    watch: true,
                  ),
              di<Logger>().dingDing,
              di<Logger>().watching,
              di<Logger>().quit,
              di<Logger>().reload,
              di<Logger>().exiting,
            ]);

            verifyNoMoreInteractions(di<Logger>());
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
        );

        final result = await runner.run();

        verifyInOrder([
          di<Logger>().preheat,
          mockBrick.cook,
          () => di<Logger>().warn('Unknown error: Exception: error'),
          () => di<Logger>().err('Could not cook brick: BRICK'),
          di<Logger>().dingDing,
        ]);

        expect(result, ExitCode.success.code);
      });

      test('when config error occurs', () async {
        when(mockBrick.cook)
            .thenThrow(const BrickException(brick: 'BRICK', reason: 'error'));
        when(() => mockBrick.name).thenReturn('BRICK');

        final runner = CookSingleBrick(
          mockBrick,
        );

        final result = await runner.run();

        verifyInOrder([
          di<Logger>().preheat,
          mockBrick.cook,
          () =>
              di<Logger>().warn('Invalid brick config: "BRICK"\nReason: error'),
          () => di<Logger>().err('Could not cook brick: BRICK'),
          di<Logger>().dingDing,
        ]);

        expect(result, ExitCode.success.code);
      });
    });
  });
}

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick(
    super.brick, {
    bool? isWatch,
    bool? shouldSync,
    super.keyPressListener,
  })  : _isWatch = isWatch,
        _shouldSync = shouldSync;

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
