import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  late FileSystem memoryFS;

  setUp(() {
    memoryFS = MemoryFileSystem();
  });

  test('can be instanciated', () {
    expect(() => const BrickYamlConfig(path: 'brick.yaml'), returnsNormally);
  });

  group('#data', () {
    test('return null when config file does not exist', () {
      final config = BrickYamlConfig(
        path: 'does_not_exist.yaml',
        fileSystem: memoryFS,
      );

      expect(config.data(), isNull);
    });

    test('return null when config file is not yaml', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        fileSystem: memoryFS,
      );

      memoryFS.file('brick.yaml').writeAsStringSync('not yaml');

      expect(config.data(), isNull);
    });

    test('returns data of config file', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        fileSystem: memoryFS,
      );

      const content = '''
name: My Brick

vars:
  var1:
  var2:
''';

      memoryFS.file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: ['var1', 'var2'],
      );

      expect(config.data(), data);
    });
  });
}
