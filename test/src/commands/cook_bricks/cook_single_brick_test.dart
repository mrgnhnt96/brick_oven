import 'dart:io';

import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../test_utils/fakes.dart';
import '../../../test_utils/mocks.dart';
import '../../../test_utils/test_directory_watcher.dart';
import '../../../test_utils/test_file_watcher.dart';

void main() {
  late FileSystem memoryFileSystem;
  late CookSingleBrick brickOvenCommand;
  late Brick brick;
  late Logger mockLogger;
  late Progress mockProgress;

  setUp(() {
    memoryFileSystem = MemoryFileSystem();
    mockLogger = MockLogger();

    mockProgress = MockProgress();

    when(() => mockProgress.complete(any())).thenReturn(voidCallback());
    when(() => mockProgress.fail(any())).thenReturn(voidCallback());
    when(() => mockProgress.update(any())).thenReturn(voidCallback());

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    memoryFileSystem.file(BrickOvenYaml.file)
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

    brickOvenCommand = CookSingleBrick(
      brick,
      fileSystem: memoryFileSystem,
      logger: mockLogger,
    );
  });

  group('$CookSingleBrick', () {
    test('instanciate without an explicit file system or logger', () {
      expect(
        () => CookSingleBrick(
          brick,
          logger: mockLogger,
        ),
        returnsNormally,
      );
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
        final command = TestCookSingleBrick(
          logger: mockLogger,
          brick: MockBrick(),
          argResults: <String, dynamic>{'watch': true},
        );

        expect(command.isWatch, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command = TestCookSingleBrick(
          logger: mockLogger,
          brick: MockBrick(),
          argResults: <String, dynamic>{'watch': false},
        );

        expect(command.isWatch, isFalse);
      });
    });

    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCookSingleBrick(
          logger: mockLogger,
          brick: MockBrick(),
          argResults: <String, dynamic>{'output': 'output/dir'},
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCookSingleBrick(
          logger: mockLogger,
          brick: MockBrick(),
          argResults: <String, dynamic>{},
        );

        expect(command.outputDir, 'bricks');
      });
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

    test('#run calls cook with output and exit with code 0', () async {
      final runner = TestCookSingleBrick(
        logger: mockLogger,
        brick: mockBrick,
        argResults: <String, dynamic>{
          'output': 'output/dir',
        },
      );

      final result = await runner.run();

      verify(mockLogger.cooking).called(1);

      verify(() => mockBrick.cook(output: 'output/dir')).called(1);

      expect(result, ExitCode.success.code);
    });
  });
}

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick({
    required Map<String, dynamic> argResults,
    required Logger logger,
    required Brick brick,
    KeyPressListener? keyPressListener,
  })  : _argResults = argResults,
        super(
          brick,
          logger: logger,
          keyPressListener: keyPressListener,
        );

  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
