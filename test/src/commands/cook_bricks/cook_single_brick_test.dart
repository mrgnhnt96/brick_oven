import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:watcher/watcher.dart';
import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';
import '../../key_listener_test.dart';
import 'cook_all_bricks_test.dart';

void main() {
  late FileSystem fs;
  late CookSingleBrick brickOvenCommand;
  late Brick brick;
  late Logger mockLogger;

  late Progress mockProgress;

  setUp(() {
    fs = MemoryFileSystem();
    mockLogger = MockLogger();

    mockProgress = MockProgress();

    when(() => mockProgress.complete(any())).thenReturn(voidCallback());
    when(() => mockProgress.fail(any())).thenReturn(voidCallback());
    when(() => mockProgress.update(any())).thenReturn(voidCallback());

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    fs.file(BrickOvenYaml.file)
      ..createSync()
      ..writeAsStringSync(
        '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''',
      );

    brick = Brick(
      source: BrickSource(localPath: 'path/to/first'),
      name: 'first',
      logger: mockLogger,
    );

    brickOvenCommand = CookSingleBrick(brick, fileSystem: fs);
  });

  group('$CookSingleBrick', () {
    test('instanciate without an explicit file system or logger', () {
      expect(() => CookSingleBrick(brick), returnsNormally);
    });

    test('description displays correctly', () {
      expect(
        brickOvenCommand.description,
        'Cook the brick: ${brick.name}.',
      );
    });

    test('name is cook', () {
      expect(brickOvenCommand.name, brick.name);
    });

    group('#isWatch', () {
      test('returns true when watch flag is provided', () {
        final command =
            TestCookSingleBrick(argResults: <String, dynamic>{'watch': true});

        expect(command.isWatch, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command =
            TestCookSingleBrick(argResults: <String, dynamic>{'watch': false});

        expect(command.isWatch, isFalse);
      });
    });

    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCookSingleBrick(
          argResults: <String, dynamic>{'output': 'output/dir'},
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCookSingleBrick(argResults: <String, dynamic>{});

        expect(command.outputDir, 'bricks');
      });
    });
  });

  group('brick_oven cook', () {
    late TestFileWatcher testFileWatcher;
    late FileSystem memoryFileSystem;
    late Brick mockBrick;
    late Stdin mockStdin;

    setUp(() {
      mockBrick = MockBrick();
      testFileWatcher = TestFileWatcher();
      memoryFileSystem = MemoryFileSystem();
      mockStdin = MockStdin();

      when(() => mockStdin.hasTerminal).thenReturn(true);

      when(() => mockBrick.source).thenReturn(
        BrickSource.memory(
          localPath: '',
          fileSystem: memoryFileSystem,
          watcher: BrickWatcher.config(
            dirPath: '',
            watcher: TestDirectoryWatcher(),
          ),
        ),
      );
    });

    tearDown(() {
      testFileWatcher.close();
    });

    test('#run calls cook with output and exit with code 0', () async {
      final runner = TestCookSingleBrick(
        logger: mockLogger,
        brick: mockBrick,
        fileWatchers: [testFileWatcher],
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

          final runner = TestCookSingleBrick(
            logger: mockLogger,
            brick: Brick.memory(
              name: '',
              source: BrickSource.memory(
                localPath: '',
                fileSystem: memoryFileSystem,
                watcher: BrickWatcher.config(
                  dirPath: '',
                  watcher: TestDirectoryWatcher(),
                ),
              ),
              fileSystem: memoryFileSystem,
              logger: mockLogger,
            ),
            fileWatchers: [testFileWatcher],
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
            keyPressListener: keyPressListener,
          );

          unawaited(runner.run());

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          expect(await codeCompleter.future, ExitCode.success.code);
        });

        test('listens to config changes and exits with code 76', () async {
          final streamController = StreamController<List<int>>();

          when(mockStdin.asBroadcastStream).thenAnswer(
            (_) => streamController.stream,
          );

          final codeCompleter = Completer<int>();

          final keyPressListener = KeyPressListener(
            stdin: mockStdin,
            logger: mockLogger,
            toExit: (_) {},
          );
          final runner = TestCookSingleBrick(
            logger: mockLogger,
            brick: Brick.memory(
              name: '',
              source: BrickSource.memory(
                localPath: '',
                fileSystem: memoryFileSystem,
                watcher: BrickWatcher.config(
                  dirPath: '',
                  watcher: TestDirectoryWatcher(),
                ),
              ),
              fileSystem: memoryFileSystem,
              logger: mockLogger,
            ),
            fileWatchers: [testFileWatcher],
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
            keyPressListener: keyPressListener,
          );

          unawaited(runner.run().then(codeCompleter.complete));

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.configChanged).called(1);

          expect(await codeCompleter.future, ExitCode.tempFail.code);
        });

        test('listens to config path changes', () async {
          final streamController = StreamController<List<int>>();

          when(mockStdin.asBroadcastStream).thenAnswer(
            (answer) => streamController.stream,
          );

          final codeCompleter = Completer<int>();

          final keyPressListener = KeyPressListener(
            stdin: mockStdin,
            logger: mockLogger,
            toExit: codeCompleter.complete,
          );
          final runner = TestCookSingleBrick(
            logger: mockLogger,
            brick: Brick.memory(
              name: '',
              configPath: 'config/path',
              source: BrickSource.memory(
                localPath: '',
                fileSystem: memoryFileSystem,
                watcher: BrickWatcher.config(
                  dirPath: '',
                  watcher: TestDirectoryWatcher(),
                ),
              ),
              fileSystem: memoryFileSystem,
              logger: mockLogger,
            ),
            fileWatchers: [testFileWatcher, null],
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
            keyPressListener: keyPressListener,
          );

          unawaited(runner.run());

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.cooking).called(1);
          verify(mockLogger.watching).called(1);

          expect(runner.completers.keys, ['config/path', 'brick_oven.yaml']);

          testFileWatcher.triggerEvent(WatchEvent(ChangeType.MODIFY, ''));

          await Future<void>.delayed(Duration.zero);

          verify(mockLogger.configChanged).called(1);
          expect(runner.completers.keys, isEmpty);
          expect(runner.brick.source.watcher?.isRunning, isFalse);

          streamController.add('q'.codeUnits);
        });

        test('returns code 74 when watcher is not running', () async {
          final runner = TestCookSingleBrick(
            logger: mockLogger,
            brick: mockBrick,
            fileWatchers: [testFileWatcher],
            argResults: <String, dynamic>{
              'output': 'output/dir',
              'watch': true,
            },
            keyPressListener: MockKeyPressListener(),
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

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick({
    required Map<String, dynamic> argResults,
    Logger? logger,
    Brick? brick,
    KeyPressListener? keyPressListener,
    this.fileWatchers,
  })  : _argResults = argResults,
        super(
          brick ?? FakeBrick(),
          logger: logger,
          keyPressListener: keyPressListener,
        );

  final Map<String, dynamic> _argResults;

  final List<FileWatcher?>? fileWatchers;

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

class MockFileWatcher extends Mock implements FileWatcher {}
