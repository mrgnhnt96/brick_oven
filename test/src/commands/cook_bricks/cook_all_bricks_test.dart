import 'dart:async';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/key_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../utils/fakes.dart';
import '../../../utils/mocks.dart';

class MockKeyPressListener extends Mock implements KeyPressListener {}

void main() {
  late CookAllBricks command;
  late MockLogger mockLogger;
  late MockKeyPressListener mockKeyPressListener;

  setUp(() {
    mockLogger = MockLogger();
    mockKeyPressListener = MockKeyPressListener();

    command = CookAllBricks(
      logger: mockLogger,
      keyPressListener: mockKeyPressListener,
    );
  });

  group('$CookAllBricks', () {
    test('description displays correctly', () {
      expect(command.description, 'Cook all bricks.');
    });

    test('name displays correctly', () {
      expect(command.name, 'all');
    });

    group('#isWatch', () {
      test('returns true when watch flag is provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'watch': true},
          logger: mockLogger,
        );

        expect(command.isWatch, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'watch': false},
          logger: mockLogger,
        );

        expect(command.isWatch, isFalse);
      });
    });

    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'output': 'output/dir'},
          logger: mockLogger,
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{},
          logger: mockLogger,
        );

        expect(command.outputDir, 'bricks');
      });
    });
  });

  group('brick_oven cook all', () {
    late Brick mockBrick;
    late Logger mockLogger;
    late MockBrickWatcher mockBrickWatcher;

    setUp(() {
      mockBrick = MockBrick();
      mockLogger = MockLogger();
      mockBrickWatcher = MockBrickWatcher();
      final fakeSource = FakeBrickSource(mockBrickWatcher);

      when(() => mockBrick.source).thenReturn(fakeSource);
      when(() => mockBrickWatcher.isRunning).thenReturn(true);
    });

    CookAllBricks command({
      bool? watch,
      bool allowConfigChanges = false,
    }) {
      watch ??= false;
      return TestCookAllBricks(
        logger: mockLogger,
        bricks: BrickOrError({mockBrick}, null),
        argResults: <String, dynamic>{
          'output': 'output/dir',
          if (watch) 'watch': true,
        },
        allowConfigChanges: allowConfigChanges,
        keyPressListener: mockKeyPressListener,
      );
    }

    test('#run calls cook with output and exit with code 0', () async {
      final result = await command().run();

      verify(mockLogger.cooking).called(1);

      verify(() => mockBrick.cook(output: 'output/dir')).called(1);

      expect(result, ExitCode.success.code);
    });

    group(
      '#run --watch',
      () {
        test('gracefully runs with watcher', () async {
          final result = await command(watch: true).run();

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);
          verify(mockKeyPressListener.qToQuit).called(1);

          verify(() => mockBrick.cook(output: 'output/dir', watch: true))
              .called(1);

          expect(result, ExitCode.success.code);
        });

        test('listens to config changes and returns code 75', () async {
          when(mockBrickWatcher.stop).thenAnswer((_) => Future<void>.value());

          final runner = command(watch: true, allowConfigChanges: true);
          final result = await runner.run();

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          verify(() => mockBrick.cook(output: 'output/dir', watch: true))
              .called(1);

          verify(
            () => mockLogger.configChanged(),
          );

          verify(mockBrickWatcher.stop).called(1);

          expect(result, ExitCode.tempFail.code);

          // verify(
          //   () => mockBrickWatcher.addEvent(
          //     mockLogger.cooking, // any() passes
          //     runBefore: true,
          //   ),
          // ).called(1);

          // verify(
          //   () => mockBrickWatcher.addEvent(
          //     mockLogger.watching,
          //     runAfter: true,
          //   ),
          // ).called(1);

          // verify(
          //   () =>
          //       mockBrickWatcher.addEvent(mockLogger.qToQuit, runAfter: true),
          // ).called(1);

          // verify(
          //   () => mockBrickWatcher.addEvent(
          //     () => runner.fileChanged(logger: mockLogger),
          //   ),
          // ).called(1);
        });

        test('returns code 74 when watcher is not running', () async {
          reset(mockBrickWatcher);
          when(() => mockBrickWatcher.isRunning).thenReturn(false);

          final result =
              await command(watch: true, allowConfigChanges: true).run();

          verify(mockLogger.cooking).called(1);
          verify(
            () => mockLogger.err(
              'There are no bricks currently watching local files, ending',
            ),
          ).called(1);

          verify(() => mockBrick.cook(output: 'output/dir', watch: true))
              .called(1);

          expect(result, ExitCode.ioError.code);
        });
      },
    );
  });
}

class TestCookAllBricks extends CookAllBricks {
  TestCookAllBricks({
    Map<String, dynamic>? argResults,
    this.bricks = const BrickOrError({}, null),
    required Logger logger,
    this.allowConfigChanges = false,
    KeyPressListener? keyPressListener,
  })  : _argResults = argResults ?? <String, dynamic>{},
        super(
          logger: logger,
          keyPressListener: keyPressListener,
        );

  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);

  @override
  final BrickOrError bricks;

  final bool allowConfigChanges;

  var _hasWatchedConfigChanges = false;

  @override
  Future<bool> watchForConfigChanges({
    FutureOr<void> Function()? onChange,
  }) async {
    if (allowConfigChanges && !_hasWatchedConfigChanges) {
      _hasWatchedConfigChanges = true;
      await onChange?.call();
      return true;
    }

    return false;
  }
}
