import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:brick_oven/utils/extensions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../utils/fakes.dart';
import '../../../utils/mocks.dart';

void main() {
  late FileSystem fs;
  late CookSingleBrick brickOvenCommand;
  late Brick brick;
  late Logger mockLogger;

  setUp(() {
    fs = MemoryFileSystem();
    mockLogger = MockLogger();

    when(() => mockLogger.progress(any())).thenReturn(([_]) => (String _) {});

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
      configuredDirs: const [],
      configuredFiles: const [],
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
    late Brick mockBrick;

    late MockBrickWatcher mockBrickWatcher;

    setUp(() {
      mockBrick = MockBrick();
      mockBrickWatcher = MockBrickWatcher();
      final mockSource = FakeBrickSource(mockBrickWatcher);

      when(() => mockBrickWatcher.isRunning).thenReturn(true);

      when(() => mockBrick.source).thenReturn(mockSource);
    });

    CookSingleBrick command({
      bool? watch,
      bool allowConfigChanges = false,
      bool fakeBrick = false,
    }) {
      return TestCookSingleBrick(
        logger: mockLogger,
        brick: fakeBrick ? FakeBrick() : mockBrick,
        argResults: <String, dynamic>{
          'output': 'output/dir',
          if (watch == true) 'watch': true,
        },
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

          verify(() => mockBrick.cook(output: 'output/dir', watch: true))
              .called(1);

          expect(result, ExitCode.success.code);
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

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick({
    required Map<String, dynamic> argResults,
    Logger? logger,
    Brick? brick,
    this.allowConfigChanges = false,
  })  : _argResults = argResults,
        super(
          brick ?? FakeBrick(),
          logger: logger,
        );

  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);

  final bool allowConfigChanges;

  var _hasWatchedConfigChanges = false;

  @override
  Future<bool> watchForConfigChanges({void Function()? onChange}) async {
    if (allowConfigChanges && !_hasWatchedConfigChanges) {
      _hasWatchedConfigChanges = true;
      return true;
    }

    return false;
  }
}
