import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';
import '../../key_listener_test.dart';

class MockKeyPressListener extends Mock implements KeyPressListener {}

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

        expect(command.outputDir, 'bricks');
      });
    });
  });

  group('brick_oven cook all', () {
    late Brick mockBrick;
    late Stdin mockStdin;
    late Logger mockLogger;
    late FileSystem memoryFileSystem;
    late TestFileWatcher testFileWatcher;
    late TestDirectoryWatcher testDirectoryWatcher;

    setUp(() {
      mockBrick = MockBrick();
      testFileWatcher = TestFileWatcher();
      mockLogger = MockLogger();
      mockStdin = MockStdin();
      memoryFileSystem = MemoryFileSystem();
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

    test('#run calls cook with output and exit with code 0', () async {
      final runner = TestCookAllBricks(
        logger: mockLogger,
        fileSystem: memoryFileSystem,
        argResults: <String, dynamic>{
          'output': 'output/dir',
        },
      );

      final result = await runner.run();

      verify(mockLogger.cooking).called(1);

      verify(() => mockBrick.cook(output: 'output/dir')).called(1);

      expect(result, ExitCode.success.code);
    });

    group(
      '#run --watch',
      () {
        test('gracefully runs with watcher', () async {
          when(mockStdin.asBroadcastStream).thenAnswer(
            (_) => Stream.fromIterable([
              'q'.codeUnits,
              [0x1b]
            ]),
          );

          final codeCompleter = Completer<int>();

          final keyPressListener = KeyPressListener(
            stdin: mockStdin,
            logger: mockLogger,
            toExit: codeCompleter.complete,
          );

          final brick = Brick.memory(
            name: '',
            source: BrickSource.memory(
              localPath: '',
              fileSystem: memoryFileSystem,
              watcher: BrickWatcher.config(
                dirPath: '',
                watcher: testDirectoryWatcher,
              ),
            ),
            fileSystem: memoryFileSystem,
            logger: mockLogger,
          );

          final runner = TestCookAllBricks(
            logger: mockLogger,
            bricksOrError: BrickOrError({brick}, null),
            fileSystem: memoryFileSystem,
            keyPressListener: keyPressListener,
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
          );

          unawaited(runner.run());

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          expect(await codeCompleter.future, ExitCode.success.code);
        });

        test('listens to config changes and returns code 75', () async {
          final runner = TestCookAllBricks(
            logger: mockLogger,
            fileSystem: memoryFileSystem,
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
          );

          final result = await runner.run();

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          verify(() => mockBrick.cook(output: 'output/dir', watch: true))
              .called(1);

          verify(
            () => mockLogger.configChanged(),
          );

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
          final runner = TestCookAllBricks(
            logger: mockLogger,
            fileSystem: memoryFileSystem,
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
          );

          final result = await runner.run();

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
    required Logger logger,
    required FileSystem fileSystem,
    this.bricksOrError,
    this.fileWatchers,
    Map<String, dynamic>? argResults,
    KeyPressListener? keyPressListener,
  })  : _argResults = argResults ?? <String, dynamic>{},
        super(
          logger: logger,
          keyPressListener: keyPressListener,
          fileSystem: fileSystem,
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
