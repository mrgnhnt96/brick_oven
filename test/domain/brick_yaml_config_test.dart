import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils/di.dart';

void main() {
  setUp(setupTestDi);

  test('can be instantiated', () {
    expect(
      () => const BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
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
          configPath: '',
        ),
        throwsA(isA<BrickConfigException>()),
      );
    });

    test('throws $BrickConfigException when yaml is error', () {
      expect(
        () => BrickYamlConfig.fromYaml(
          const YamlValue.error('error'),
          configPath: '',
        ),
        throwsA(isA<BrickConfigException>()),
      );
    });

    test('returns $BrickYamlConfig when yaml is string', () {
      final config = BrickYamlConfig.fromYaml(
        YamlValue.from('brick.yaml'),
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
        configPath: '',
      );

      const expected = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: ['ignore'],
      );

      expect(config, expected);
    });

    test('returns path with provided configPath', () {
      final yaml = loadYaml('''
path: brick.yaml
''');

      final config = BrickYamlConfig.fromYaml(
        YamlValue.from(yaml),
        configPath: join('path', 'to', 'config'),
      );

      final expected = BrickYamlConfig(
        path: join('path', 'to', 'config', 'brick.yaml'),
        ignoreVars: const [],
      );

      expect(config, expected);
    });
  });

  group('#data', () {
    test('return null when config file does not exist', () {
      const config = BrickYamlConfig(
        path: 'does_not_exist.yaml',
        ignoreVars: [],
      );

      expect(config.data, isNull);

      verify(
        () =>
            di<Logger>().warn('`brick.yaml` not found at does_not_exist.yaml'),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('return null when config file is not yaml', () {
      const config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      di<FileSystem>().file('brick.yaml').writeAsStringSync('not yaml');

      expect(config.data, isNull);

      verify(
        () => di<Logger>().warn('Error reading `brick.yaml`'),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('supports legacy config file', () {
      const config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      const content = '''
name: My Brick

vars:
  - var1
  - var2
''';

      di<FileSystem>().file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: ['var1', 'var2'],
      );

      expect(config.data, data);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('warns when vars is incorrect type', () {
      const config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      const content = '''
name: My Brick

vars: sup yo
''';

      di<FileSystem>().file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: [],
      );

      expect(config.data, data);

      verify(
        () =>
            di<Logger>().warn('`vars` is an unsupported type in `brick.yaml`'),
      ).called(1);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('returns when vars is not provided', () {
      const config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      const content = '''
name: My Brick
''';

      di<FileSystem>().file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: [],
      );

      expect(config.data, data);

      verifyNoMoreInteractions(di<Logger>());
    });

    test('returns data of config file', () {
      const config = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      const content = '''
name: My Brick

vars:
  var1:
  var2:
''';

      di<FileSystem>().file('brick.yaml').writeAsStringSync(content);

      const data = BrickYamlData(
        name: 'My Brick',
        vars: ['var1', 'var2'],
      );

      expect(config.data, data);

      verifyNoMoreInteractions(di<Logger>());
    });
  });

  group('#props', () {
    test('instances are equal', () {
      const instance = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      const instance2 = BrickYamlConfig(
        path: 'brick.yaml',
        ignoreVars: [],
      );

      expect(instance, instance2);
    });
  });
}
