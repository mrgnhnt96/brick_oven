import 'package:args/args.dart';
import 'package:brick_oven/domain/brick_or_error.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../utils/fakes.dart';

void main() {
  late FileSystem fs;
  late BrickOvenCommand brickOvenCommand;

  void createFile(String path, String content) {
    fs.file(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  setUp(() {
    fs = MemoryFileSystem();
    brickOvenCommand = TestBrickOvenCommand(fs);
  });

  group('$BrickOvenCommand', () {
    group('#bricks', () {
      test('returns a set of bricks', () {
        const content = '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''';

        createFile(BrickOvenYaml.file, content);

        final bricks = brickOvenCommand.bricks().bricks;
        expect(bricks, isNotNull);
        expect(bricks.length, 3);
      });

      test('throws $ConfigException when ${BrickOvenYaml.file} is empty', () {
        const content = '';

        createFile(BrickOvenYaml.file, content);

        expect(
          brickOvenCommand.bricks,
          throwsA(isA<BrickOvenException>()),
        );
      });

      test('throws $ConfigException when bricks is not yaml', () {
        const content = '''
bricks: Not YAML
''';

        createFile(BrickOvenYaml.file, content);

        expect(
          brickOvenCommand.bricks,
          throwsA(isA<BrickOvenException>()),
        );
      });

      test(
        'throws $BrickOvenNotFoundException when ${BrickOvenYaml.file} does not exist',
        () {
          expect(
            brickOvenCommand.bricks,
            throwsA(isA<BrickOvenNotFoundException>()),
          );
        },
      );

      test('return $BrickOrError with error when extra keys are provided', () {
        const content = '''
bricks:
  first:
    source: path/to/first
second:
  source: path/to/second
''';

        createFile(BrickOvenYaml.file, content);

        expect(brickOvenCommand.bricks().isError, isTrue);
        expect(
          brickOvenCommand.bricks().error,
          'Unknown keys: second, in brick_oven.yaml',
        );
      });

      test('return $BrickOrError error when source is null in sub config file',
          () {
        const path = 'path/to';
        const file = 'file';
        const content = '''
bricks:
  $file: $path/$file.yaml
''';

        const content2 = '''
source:
''';

        createFile(BrickOvenYaml.file, content);
        createFile('$path/$file.yaml', content2);

        final result = brickOvenCommand.bricks();

        expect(result.isError, isTrue);
        expect(
          result.error,
          contains('`source` value is required in sub config files'),
        );
      });

      test('return $BrickOrError error when config file does not exist', () {
        const path = 'path/to/first';
        const content = '''
bricks:
  first: $path.yaml
''';

        createFile(BrickOvenYaml.file, content);

        expect(brickOvenCommand.bricks().isError, isTrue);
        expect(
          brickOvenCommand.bricks().error,
          contains('Brick configuration file not found'),
        );
      });

      test('return $BrickOrError error when config file is not type map', () {
        const path = 'path/to/first';
        const content = '''
bricks:
  first: $path.yaml
''';
        const content2 = '''
- some value
''';

        createFile(BrickOvenYaml.file, content);
        createFile('$path.yaml', content2);

        expect(brickOvenCommand.bricks().isError, isTrue);
        expect(
          brickOvenCommand.bricks().error,
          contains('Brick configuration file must be of type'),
        );
      });

      test('return $BrickOrError error when brick is not correct type', () {
        const content = '''
bricks:
  first: ${123}
''';

        createFile(BrickOvenYaml.file, content);

        expect(brickOvenCommand.bricks().isError, isTrue);
        expect(
          brickOvenCommand.bricks().error,
          contains('Invalid brick configuration'),
        );
      });
    });

    group('#cwd', () {
      test('returns the current working directory', () {
        final cwd = brickOvenCommand.cwd;

        expect(cwd, isNotNull);
        expect(cwd.path, fs.currentDirectory.path);
      });
    });
  });
}

class TestBrickOvenCommand extends BrickOvenCommand {
  TestBrickOvenCommand(FileSystem fs) : super(fileSystem: fs);
  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();

  @override
  ArgResults get argResults => FakeArgResults(data: <String, dynamic>{});
}

class MockBrickOvenCommand extends Mock implements BrickOvenCommand {}
