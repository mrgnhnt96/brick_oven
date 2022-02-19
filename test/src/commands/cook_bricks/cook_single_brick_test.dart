import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_single_brick.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import '../../../utils/fakes.dart';

void main() {
  late FileSystem fs;
  late CookSingleBrick brickOvenCommand;
  late Brick brick;

  setUp(() {
    fs = MemoryFileSystem();
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
}

class TestCookSingleBrick extends CookSingleBrick {
  TestCookSingleBrick({required Map<String, dynamic> argResults})
      : _argResults = argResults,
        super(FakeBrick());

  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
