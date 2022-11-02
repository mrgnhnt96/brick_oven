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
  late File brickOvenYaml;
  late BrickOvenCommand brickOvenCommand;

  void createBrickOvenFile({
    bool addExtraKey = false,
    bool addPathForExtraConfig = false,
    bool createExtraConfig = false,
  }) {
    var content = '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''';

    if (addExtraKey) {
      content += '''
extra:
''';
    }

    if (addPathForExtraConfig) {
      content += '''
  fourth: path/to/fourth.yaml
''';
    }

    brickOvenYaml
      ..createSync()
      ..writeAsStringSync(content);

    const configForFourth = '''
source: path/to/fourth
''';

    if (createExtraConfig) {
      fs.file('path/to/fourth.yaml')
        ..createSync(recursive: true)
        ..writeAsStringSync(configForFourth);
    }
  }

  setUp(() {
    fs = MemoryFileSystem();
    brickOvenYaml = fs.file(BrickOvenYaml.file);
    brickOvenCommand = TestBrickOvenCommand(fs);
  });

  group('$BrickOvenCommand', () {
    group('#bricks', () {
      test('returns a set of bricks', () {
        createBrickOvenFile();
        final bricks = brickOvenCommand.bricks.bricks;
        expect(bricks, isNotNull);
        expect(bricks.length, 3);
      });

      test(
        // ignore: lines_longer_than_80_chars
        'throws $BrickOvenNotFoundException when ${BrickOvenYaml.file} does not exist',
        () {
          expect(
            () => brickOvenCommand.bricks,
            throwsA(isA<BrickOvenNotFoundException>()),
          );
        },
      );

      test('return $BrickOrError with error', () {
        createBrickOvenFile(addExtraKey: true);

        expect(brickOvenCommand.bricks.isError, isTrue);
        expect(
          brickOvenCommand.bricks.error,
          'Unknown keys: extra, in brick_oven.yaml',
        );
      });

      test(
          'return $BrickOrError with brick when brick is provided path to config file',
          () {
        createBrickOvenFile(
          addPathForExtraConfig: true,
          createExtraConfig: true,
        );

        final bricks = brickOvenCommand.bricks.bricks;

        expect(bricks, isNotNull);
        expect(bricks.length, 4);
      });

      test(
          'return $BrickOrError with brick when brick is provided path to config file',
          () {
        createBrickOvenFile(addPathForExtraConfig: true);

        expect(brickOvenCommand.bricks.isError, isTrue);
        expect(
          brickOvenCommand.bricks.error,
          contains('FileSystemException'),
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
