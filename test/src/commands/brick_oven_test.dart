import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/brick_oven.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem fs;
  late File brickOvenYaml;
  late BrickOvenCommand brickOvenCommand;

  void createBrickOvenFile([String? contents]) {
    final content = contents ??
        '''
bricks:
  first:
    source: path/to/first
  second:
    source: path/to/second
  third:
    source: path/to/third
''';

    brickOvenYaml
      ..createSync()
      ..writeAsStringSync(content);
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
        final bricks = brickOvenCommand.bricks;
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

      test('throws when extra keys exist', () {
        createBrickOvenFile('extra:');

        expect(
          () => brickOvenCommand.bricks,
          throwsA(isA<UnknownKeysException>()),
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
}
