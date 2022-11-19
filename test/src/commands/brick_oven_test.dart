import 'package:args/args.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/bricks_or_error.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../test_utils/fakes.dart';
import '../../test_utils/mocks.dart';

void main() {
  late FileSystem fs;
  late BrickOvenCommand brickOvenCommand;
  late Logger mockLogger;

  void createFile(String path, String content) {
    fs.file(path)
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  setUp(() {
    fs = MemoryFileSystem();
    mockLogger = MockLogger();

    brickOvenCommand = TestBrickOvenCommand(
      fs,
      logger: mockLogger,
    );
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('returns error when when ${BrickOvenYaml.file} is bad', () {
        const content = '';

        createFile(BrickOvenYaml.file, content);

        expect(
          brickOvenCommand.bricks(),
          const BricksOrError(null, 'Invalid brick oven configuration file'),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('returns error when ${BrickOvenYaml.file} does not exist', () {
        expect(
          brickOvenCommand.bricks(),
          const BricksOrError(null, 'No ${BrickOvenYaml.file} file found'),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError with error yaml has bad syntax', () {
        const content = '''
bricks:
  some:
  1
''';

        createFile(BrickOvenYaml.file, content);

        final result = brickOvenCommand.bricks();

        expect(result.isError, isTrue);
        expect(
          result.error,
          startsWith('Invalid configuration, '),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError with error when extra keys are provided', () {
        const content = '''
bricks:
  first:
    source: path/to/first
second:
  source: path/to/second
''';

        createFile(BrickOvenYaml.file, content);

        final result = brickOvenCommand.bricks();

        expect(result.isError, isTrue);
        expect(
          result.error,
          'Invalid brick_oven.yaml config:\n'
          'Unknown keys: "second"',
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError error when source is null in sub config file',
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError error when config file does not exist', () {
        const path = 'path/to/first';
        const content = '''
bricks:
  first: $path.yaml
''';

        createFile(BrickOvenYaml.file, content);

        final result = brickOvenCommand.bricks();

        expect(result, const BricksOrError(<Brick>{}, null));

        verify(
          () => mockLogger.warn(
            'Brick configuration file not found | (first) -- $path.yaml',
          ),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError error when config file is not type map', () {
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('return $BricksOrError error when brick is not correct type', () {
        const content = '''
bricks:
  first: ${123}
''';

        createFile(BrickOvenYaml.file, content);

        final result = brickOvenCommand.bricks();

        expect(result.isError, isTrue);
        expect(
          result.error,
          'Invalid brick config: "first"\n'
          'Reason: Expected `Map` or `String` (path to brick configuration file)',
        );

        verifyNoMoreInteractions(mockLogger);
      });
    });

    group('#cwd', () {
      test('returns the current working directory', () {
        final cwd = brickOvenCommand.cwd;

        expect(cwd, isNotNull);
        expect(cwd.path, fs.currentDirectory.path);

        verifyNoMoreInteractions(mockLogger);
      });
    });
  });
}

class TestBrickOvenCommand extends BrickOvenCommand {
  TestBrickOvenCommand(
    FileSystem fs, {
    required Logger logger,
  }) : super(
          fileSystem: fs,
          logger: logger,
        );

  @override
  ArgResults get argResults => FakeArgResults(data: <String, dynamic>{});

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();
}

class MockBrickOvenCommand extends Mock implements BrickOvenCommand {}
