import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import '../test_utils/mocks.dart';

void main() {
  late FileSystem memoryFS;
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();

    memoryFS = MemoryFileSystem();
  });

  test('can be instantiated', () {
    expect(
      () => BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      ),
      returnsNormally,
    );
  });

  group('#fromYaml', () {
    test('throws $BrickConfigException when yaml is wrong type', () {
      final yaml = loadYaml('''
brick_config:
  - Hi
''');

      expect(
        () => BrickYamlConfig.fromYaml(
          YamlValue.from(yaml),
          fileSystem: MemoryFileSystem(),
          configPath: '',
        ),
        throwsA(isA<BrickConfigException>()),
      );
    });

    test('throws $BrickConfigException when yaml is error', () {
      expect(
        () => BrickYamlConfig.fromYaml(
          const YamlValue.error('error'),
          fileSystem: MemoryFileSystem(),
          configPath: '',
        ),
        throwsA(isA<BrickConfigException>()),
      );
    });

    test('returns $BrickYamlConfig when yaml is string', () {
      final config = BrickYamlConfig.fromYaml(
        YamlValue.from('brick.yaml'),
        fileSystem: MemoryFileSystem(),
        configPath: '',
      );

      expect(config.path, 'brick.yaml');
    });

    test('returns $BrickYamlConfig when yaml is map', () {
      final yaml = loadYaml('''
path: brick.yaml
''');

      final config = BrickYamlConfig.fromYaml(
        YamlValue.from(yaml),
        fileSystem: MemoryFileSystem(),
        configPath: '',
      );

      expect(config.path, 'brick.yaml');
    });

    test('throws $BrickConfigException when extra keys are provided', () {
      final yaml = loadYaml('''
path: brick.yaml
extra: key
''');

      expect(
        () => BrickYamlConfig.fromYaml(
          YamlValue.from(yaml),
          fileSystem: MemoryFileSystem(),
          configPath: '',
        ),
        throwsA(isA<BrickConfigException>()),
      );
    });

    test('can parse successfully', () {
      final yaml = loadYaml('''
path: brick.yaml
ignore_vars:
  - ignore
''');

      final config = BrickYamlConfig.fromYaml(
        YamlValue.from(yaml),
        fileSystem: MemoryFileSystem(),
        configPath: '',
      );

      final expected = BrickYamlConfig(
        path: 'brick.yaml',
        fileSystem: MemoryFileSystem(),
        ignoreVars: const ['ignore'],
      );

      expect(config, expected);
    });

    test('returns path with provided configPath', () {
      final yaml = loadYaml('''
path: brick.yaml
''');

      final config = BrickYamlConfig.fromYaml(
        YamlValue.from(yaml),
        fileSystem: MemoryFileSystem(),
        configPath: join('path', 'to', 'config'),
      );

      final expected = BrickYamlConfig(
        path: join('path', 'to', 'config', 'brick.yaml'),
        fileSystem: MemoryFileSystem(),
        ignoreVars: const [],
      );

      expect(config, expected);
    });
  });

  group('#data', () {
    test('return null when config file does not exist', () {
      final config = BrickYamlConfig(
        path: 'does_not_exist.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      );

      expect(config.data(logger: mockLogger), isNull);

      verify(
        () => mockLogger.warn('`brick.yaml` not found at does_not_exist.yaml'),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('return null when config file is not yaml', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      );

      memoryFS.file('brick.yaml').writeAsStringSync('not yaml');

      expect(config.data(logger: mockLogger), isNull);

      verify(
        () => mockLogger.warn('Error reading `brick.yaml`'),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('supports legacy config file', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      );

      const content = '''
name: My Brick

vars:
  - var1
  - var2
''';

      memoryFS.file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: ['var1', 'var2'],
      );

      expect(config.data(logger: mockLogger), data);

      verifyNoMoreInteractions(mockLogger);
    });

    test('warns when vars is incorrect type', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      );

      const content = '''
name: My Brick

vars: sup yo
''';

      memoryFS.file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: [],
      );

      expect(config.data(logger: mockLogger), data);

      verify(
        () => mockLogger.warn('`vars` is an unsupported type in `brick.yaml`'),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
    });

    test('returns when vars is not provided', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: memoryFS,
      );

      const content = '''
name: My Brick
''';

      memoryFS.file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: [],
      );

      expect(config.data(logger: mockLogger), data);

      verifyNoMoreInteractions(mockLogger);
    });

    test('returns data of config file', () {
      final config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
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

      expect(config.data(logger: mockLogger), data);

      verifyNoMoreInteractions(mockLogger);
    });
  });

  group('#props', () {
    test('instances are equal', () {
      final instance = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: MemoryFileSystem(),
      );

      final instance2 = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: const [],
        fileSystem: MemoryFileSystem(),
      );

      expect(instance, instance2);
    });
  });
}
