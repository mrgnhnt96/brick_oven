// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/variable.dart';
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
  test('can be instantiated', () {
    expect(() => const Partial(path: 'path'), returnsNormally);
  });

  group('#fromYaml', () {
    test('throws $ConfigException if yaml is error', () {
      expect(
        () => Partial.fromYaml(const YamlError('err'), 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('returns $Partial when yaml is null', () {
      expect(
        Partial.fromYaml(const YamlNone(), 'path'),
        const Partial(path: 'path'),
      );
    });

    test('returns $Partial when yaml is invalid', () {
      expect(
        () => Partial.fromYaml(const YamlString('hiii'), 'path'),
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
          () => Partial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if yaml is not map', () {
        const content = '''
vars: hiii
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          () => Partial.fromYaml(yaml, 'path'),
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
          () => Partial.fromYaml(yaml, 'path'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('returns $Partial when vars is null', () {
        const content = '''
vars:
''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          Partial.fromYaml(yaml, 'path'),
          const Partial(path: 'path'),
        );
      });

      test('returns $Partial when vars are valid', () {
        const content = '''
vars:
  some:
  _ONE_: one

''';
        final yaml = YamlValue.from(loadYaml(content));
        expect(
          Partial.fromYaml(yaml, 'path'),
          const Partial(
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
    const instance = Partial(path: 'path/to/file.dart');

    expect(instance.name, 'file');
  });

  group('#fileName', () {
    test('returns the file name with extension', () {
      const instance = Partial(path: 'path/to/file.dart');

      expect(instance.fileName, 'file.dart');
    });

    test('returns the file name with generated extension', () {
      const instance = Partial(path: 'path/to/file.g.dart');

      expect(instance.fileName, 'file.g.dart');
    });
  });

  test('#toPartialFile, returns formatted partial file', () {
    const instance = Partial(path: 'path/to/file.dart');

    expect(instance.toPartialFile(), '{{~ file.dart }}');
  });

  test('#toPartialInput returns formatted partial input', () {
    const instance = Partial(path: 'path/to/file.dart');

    expect(instance.toPartialInput(), '{{> file.dart }}');
  });

  group('#writeTargetFile', () {
    const targetDir = 'bricks';
    const fileName = 'file.dart';
    const sourcePath = 'path/to/$fileName';
    const defaultContent = 'content';
    late File sourceFile;

    setUp(() {
      setupTestDi();

      sourceFile = di<FileSystem>().file(sourcePath)
        ..create(recursive: true)
        ..writeAsStringSync(defaultContent);
    });

    test('Throws $PartialException when #writeFile throws', () {
      const instance = TestBrickPartial(sourcePath);

      expect(
        () => instance.writeTargetFile(
          outOfFileVariables: [],
          partials: [],
          sourceFile: sourceFile,
          targetDir: '',
        ),
        throwsA(isA<PartialException>()),
      );

      verifyNoMoreInteractions(di<Logger>());
    });

    test('writes file on target dir root', () {
      const instance = Partial(path: 'path/to/file.dart');

      instance.writeTargetFile(
        outOfFileVariables: [],
        targetDir: targetDir,
        sourceFile: sourceFile,
        partials: [],
      );

      expect(
        di<FileSystem>().file(join(targetDir, '{{~ $fileName }}')).existsSync(),
        isTrue,
      );

      verifyNoMoreInteractions(di<Logger>());
    });
  });
}

class TestBrickPartial extends Partial {
  const TestBrickPartial(String path) : super(path: path);

  @override
  FileWriteResult writeFile({
    required List<Variable> outOfFileVariables,
    required File targetFile,
    required File sourceFile,
    required List<Variable> variables,
    required List<Partial> partials,
  }) {
    throw const FileException(file: 'file', reason: 'reason');
  }
}
