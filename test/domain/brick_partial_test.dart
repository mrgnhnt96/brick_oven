// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:brick_oven/domain/brick_partial.dart';
import 'package:yaml/yaml.dart';

import '../test_utils/mocks.dart';

void main() {
  test('can be instanciated', () {
    expect(() => const BrickPartial(path: 'path'), returnsNormally);
  });

  group('#fromYaml', () {
    test('throws $ConfigException if yaml is error', () {
      expect(
        () => BrickPartial.fromYaml(const YamlError('err'), 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('returns $BrickPartial when yaml is null', () {
      expect(
        BrickPartial.fromYaml(const YamlNone(), 'path'),
        const BrickPartial(path: 'path'),
      );
    });

    test('returns $BrickPartial when yaml is invalid', () {
      expect(
        () => BrickPartial.fromYaml(const YamlString('hiii'), 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    group('#vars', () {
      test('throws $ConfigException if yaml is error', () {
        const content = '''
vars: ${1}
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if yaml is not map', () {
        const content = '''
vars: hiii
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if var is invalid', () {
        const content = '''
vars:
  some: ${1}
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => BrickPartial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('returns $BrickPartial when vars is null', () {
        const content = '''
vars:
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          BrickPartial.fromYaml(yaml, 'path'),
          const BrickPartial(path: 'path'),
        );
      });

      test('returns $BrickPartial when vars are valid', () {
        const content = '''
vars:
  some:
  one: _ONE_

''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          BrickPartial.fromYaml(yaml, 'path'),
          const BrickPartial(
            path: 'path',
            variables: [
              Variable(name: 'some'),
              Variable(name: 'one', placeholder: '_ONE_'),
            ],
          ),
        );
      });
    });
  });

  test('#name returns file name without extension', () {
    const instance = BrickPartial(path: 'path/to/file.dart');

    expect(instance.name, 'file');
  });

  group('#fileName', () {
    test('returns the file name with extension', () {
      const instance = BrickPartial(path: 'path/to/file.dart');

      expect(instance.fileName, 'file.dart');
    });

    test('returns the file name with generated extension', () {
      const instance = BrickPartial(path: 'path/to/file.g.dart');

      expect(instance.fileName, 'file.g.dart');
    });
  });

  test('#toPartialFile, returns formatted partial file', () {
    const instance = BrickPartial(path: 'path/to/file.dart');

    expect(instance.toPartialFile(), '{{~ file.dart }}');
  });

  test('#toPartialInput returns formatted partial input', () {
    const instance = BrickPartial(path: 'path/to/file.dart');

    expect(instance.toPartialInput(), '{{> file.dart }}');
  });

  group('#writeTargetFile', () {
    late FileSystem fs;
    late Logger mockLogger;
    const targetDir = 'bricks';
    const fileName = 'file.dart';
    const sourcePath = 'path/to/$fileName';
    const defaultContent = 'content';
    late File sourceFile;

    setUp(() {
      mockLogger = MockLogger();

      fs = MemoryFileSystem();
      sourceFile = fs.file(sourcePath)
        ..create(recursive: true)
        ..writeAsStringSync(defaultContent);
    });

    test('Throws $PartialException when #writeFile throws', () {
      const instance = TestBrickPartial(sourcePath);

      expect(
        () => instance.writeTargetFile(
          additionalVariables: [],
          partials: [],
          sourceFile: sourceFile,
          targetDir: '',
          fileSystem: fs,
          logger: mockLogger,
        ),
        throwsA(isA<PartialException>()),
      );
    });

    test('writes file on target dir root', () {
      const instance = BrickPartial(path: 'path/to/file.dart');

      instance.writeTargetFile(
        additionalVariables: [],
        targetDir: targetDir,
        sourceFile: sourceFile,
        partials: [],
        fileSystem: fs,
        logger: mockLogger,
      );

      expect(fs.file(join(targetDir, '{{~ $fileName }}')).existsSync(), isTrue);
    });
  });
}

class TestBrickPartial extends BrickPartial {
  const TestBrickPartial(String path) : super(path: path);

  @override
  FileWriteResult writeFile({
    required File targetFile,
    required File sourceFile,
    required List<Variable> variables,
    required List<BrickPartial> partials,
    required FileSystem? fileSystem,
    required Logger logger,
  }) {
    throw const FileException(file: 'file', reason: 'reason');
  }
}
