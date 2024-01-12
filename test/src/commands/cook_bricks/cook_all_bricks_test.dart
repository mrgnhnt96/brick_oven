// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../test_utils/di.dart';
import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';

void main() {
  late CookAllBricks command;
  late Brick mockBrick;

  setUp(() {
    setupTestDi();

    mockBrick = MockBrick();
    command = CookAllBricks();
  });

  group('$CookAllBricks', () {
    test('description displays correctly', () {
      expect(command.description, 'Cook all bricks');

      verifyNoMoreInteractions(di<Logger>());
    });

    test('name displays correctly', () {
      expect(command.name, 'all');

      verifyNoMoreInteractions(di<Logger>());
    });

    group('#run', () {
      group('gracefully', () {
        test('when shouldSync and isWatch are default values', () async {
          final command = TestCookAllBricks(
            bricksOrError: BricksOrError({mockBrick}, null),
          );

          final result = await command.run();

          verifyInOrder([
            di<Logger>().preheat,
            mockBrick.cook,
            di<Logger>().dingDing,
          ]);

          expect(result, ExitCode.success.code);

          verifyNoMoreInteractions(mockBrick);
          verifyNoMoreInteractions(di<Logger>());
        });

        group('when #shouldSync', () {
          test('is false', () async {
            final command = TestCookAllBricks(
              bricksOrError: BricksOrError({mockBrick}, null),
              shouldSync: false,
            );

            final result = await command.run();

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
            final command = TestCookAllBricks(
              bricksOrError: BricksOrError({mockBrick}, null),
              shouldSync: true,
            );

            final result = await command.run();

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
            final command = TestCookAllBricks(
              bricksOrError: BricksOrError({mockBrick}, null),
              isWatch: false,
              keyPressListener: keyPressListener,
            );

            final result = await command.run();

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
            final command = TestCookAllBricks(
              bricksOrError: BricksOrError({mockBrick}, null),
              isWatch: true,
              keyPressListener: keyPressListener,
            );

            final runResult = await command.run();

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

      test('when error occurs when parsing bricks', () async {
        final command = TestCookAllBricks(
          bricksOrError: const BricksOrError(null, 'error'),
        );

        final result = await command.run();

        verify(() => di<Logger>().err('error')).called(1);

        expect(result, ExitCode.config.code);

        verifyNoMoreInteractions(di<Logger>());
      });

      test('when unknown error occurs', () async {
        when(() => mockBrick.name).thenReturn('BRICK');
        when(() => mockBrick.cook()).thenThrow(Exception('error'));

        final command = TestCookAllBricks(
          bricksOrError: BricksOrError({mockBrick}, null),
        );

        final result = await command.run();

        verifyInOrder([
          di<Logger>().preheat,
          mockBrick.cook,
          () => di<Logger>().warn('Unknown error: Exception: error'),
          () => di<Logger>().err('Could not cook brick: BRICK'),
          di<Logger>().dingDing,
        ]);

        verify(() => mockBrick.name).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(mockBrick);

        expect(result, ExitCode.success.code);
      });

      test('when config error occurs', () async {
        when(() => mockBrick.name).thenReturn('BRICK');
        when(() => mockBrick.cook())
            .thenThrow(const BrickException(brick: 'BRICK', reason: 'error'));

        final command = TestCookAllBricks(
          bricksOrError: BricksOrError({mockBrick}, null),
        );

        final result = await command.run();

        verifyInOrder([
          di<Logger>().preheat,
          mockBrick.cook,
          () => di<Logger>().warn(
                'Invalid brick config: "BRICK"\n'
                'Reason: error',
              ),
          () => di<Logger>().err('Could not cook brick: BRICK'),
          di<Logger>().dingDing,
        ]);

        expect(result, ExitCode.success.code);

        verify(() => mockBrick.name).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(mockBrick);
      });
    });
  });
}

class TestCookAllBricks extends CookAllBricks {
  TestCookAllBricks({
    this.bricksOrError,
    bool? isWatch,
    bool? shouldSync,
    Map<String, dynamic>? argResults,
    super.keyPressListener,
  })  : _argResults = argResults ?? <String, dynamic>{},
        _isWatch = isWatch,
        _shouldSync = shouldSync;

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
