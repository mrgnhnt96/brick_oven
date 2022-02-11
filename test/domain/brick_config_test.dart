import 'package:brick_oven/brick_oven.dart';
import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_config.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem();
  });

  void createYaml(String contents) {
    const fileName = BrickConfig.file;
    fileSystem.file(fileName)
      ..createSync()
      ..writeAsStringSync(contents);
  }

  void createFakeDir(String path) {
    final files = [
      join(path, 'file.dart'),
      join(path, 'another.dart'),
      join(path, 'some', 'file.dart'),
      join(path, 'some', 'another.dart'),
    ];

    for (final file in files) {
      fileSystem.file(file).createSync(recursive: true);
    }
  }

  test('throws error when ${BrickConfig.file} does not exist', () {
    expect(
      () => BrickConfig(BrickArguments.from([])),
      throwsA(isA<Exception>()),
    );
  });

  test('#config throws error when ${BrickConfig.file} does not exist', () {
    expect(
      () => BrickConfig.config(MemoryFileSystem()),
      throwsA(isA<Exception>()),
    );
  });

  test('throws error when extra keys are provided', () {
    const yamlContent = '''
extra:
  value: something
''';

    createYaml(yamlContent);

    expect(() => BrickConfig.config(fileSystem), throwsA(isA<ArgumentError>()));
  });

  test('parses the directories', () {
    final bricks = {
      'target': join('lib', 'target'),
      'other': join('lib', 'target', 'other'),
    };

    final bricksMapping = bricks.keys
        .map(
          (e) => [
            '  $e:',
            '    source: ${bricks[e]}',
          ].join('\n'),
        )
        .join('\n');

    final yamlContents = '''
bricks:
$bricksMapping
''';

    createYaml(yamlContents);
    for (final path in bricks.values) {
      createFakeDir(path);
    }
    final instance = BrickConfig.config(fileSystem);

    for (final brick in instance.bricks) {
      expect(bricks.keys, contains(brick.name));
      expect(bricks.values, contains(brick.source.localPath));
    }
  });

  group('#writeBricks', () {
    late Brick mockBrick;
    // ignore: omit_local_variable_types, prefer_function_declarations_over_variables
    final void Function() voidCallback = () {};

    setUp(() {
      mockBrick = MockBrick();
    });

    test('write brick is called', () {
      final brickConfig = BrickConfig.create(bricks: [mockBrick]);

      when(() => mockBrick.writeBrick(any())).thenReturn(voidCallback());

      verifyNever(() => mockBrick.writeBrick(any()));

      brickConfig.writeBricks();

      verify(() => mockBrick.writeBrick(any())).called(1);
    });

    test('when watch arg is provided, watch brick is called', () {
      final brickConfig = BrickConfig.create(
        bricks: [mockBrick],
        arguments: const BrickArguments(watch: true),
      );

      when(() => mockBrick.writeBrick(any())).thenReturn(voidCallback());
      when(() => mockBrick.watchBrick(any())).thenReturn(voidCallback());
      final mockSource = MockBrickSource();
      final mockWatcher = MockBrickWatcher();

      when(() => mockWatcher.isRunning).thenReturn(false);
      when(() => mockSource.watcher).thenReturn(mockWatcher);
      when(() => mockBrick.source).thenReturn(mockSource);

      verifyNever(() => mockBrick.watchBrick(any()));
      verifyNever(() => mockBrick.writeBrick(any()));

      brickConfig.writeBricks();

      verify(() => mockBrick.watchBrick(any())).called(1);
    });
  });

  test('file is brick_oven.yaml', () {
    expect(BrickConfig.file, 'brick_oven.yaml');
  });
}

class MockBrickSource extends Mock implements BrickSource {}

class MockBrickWatcher extends Mock implements BrickWatcher {}

class MockBrick extends Mock implements Brick {}
