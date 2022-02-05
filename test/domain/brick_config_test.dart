import 'package:brick_oven/domain/brick_config.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
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
    expect(BrickConfig.new, throwsA(isA<Exception>()));
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

    for (final brick in instance.directories) {
      expect(bricks.keys, contains(brick.name));
      expect(bricks.values, contains(brick.source.localPath));
    }
  });

  test('file is brick_oven.yaml', () {
    expect(BrickConfig.file, 'brick_oven.yaml');
  });
}
