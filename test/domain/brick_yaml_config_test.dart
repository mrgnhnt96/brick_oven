import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';

void main() {
  late FileSystem memoryFS;
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();

    memoryFS = MemoryFileSystem();
  });

  test('can be instanciated', () {
    expect(
      () => BrickYamlConfig(
        path: 'brick.yaml',
        fileSystem: memoryFS,
      ),
      returnsNormally,
    );
  });

  group('#data', () {
    test('return null when config file does not exist', () {
      final config = BrickYamlConfig(
        path: 'does_not_exist.yaml',
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
        fileSystem: memoryFS,
      );

      memoryFS.file('brick.yaml').writeAsStringSync('not yaml');

      expect(config.data(logger: mockLogger), isNull);

      verify(
        () => mockLogger.warn('Error reading `brick.yaml`'),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
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

      expect(config.data(logger: mockLogger), data);

      verifyNoMoreInteractions(mockLogger);
    });
  });

  group('#props', () {
    test('instances are equal', () {
      final instance = BrickYamlConfig(
        path: 'brick.yaml',
        fileSystem: MemoryFileSystem(),
      );

      expect(instance.props.length, 1);
    });
  });
}
