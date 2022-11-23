// ignore_for_file: cascade_invocations

import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils/mocks.dart';

void main() {
  const defaultFileName = 'file';
  const defaultFile = '$defaultFileName.dart';
  final defaultPath = join('path', 'to', defaultFile);

  const fileExtensions = {
    'file.dart': '.dart',
    'file.dart.mustache': '.dart.mustache',
    'file.mustache': '.mustache',
    'file.js': '.js',
    'file.md': '.md',
  };

  late MockLogger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  group('$BrickFile unnamed ctor', () {
    final instance = BrickFile(defaultPath);

    test('can be instanciated', () {
      expect(instance, isA<BrickFile>());
    });

    test('variables is an empty list', () {
      expect(instance.variables, isEmpty);
    });

    test('prefix is null', () {
      expect(instance.name?.prefix, isNull);
    });

    test('suffix is null', () {
      expect(instance.name?.suffix, isNull);
    });

    test('providedName is null', () {
      expect(instance.name?.value, isNull);
    });

    test('include if is null', () {
      expect(instance.includeIf, isNull);
    });

    test('include if not is null', () {
      expect(instance.includeIfNot, isNull);
    });
  });

  group('#fromYaml', () {
    test('throws $ConfigException on null value', () {
      expect(
        () => BrickFile.fromYaml(const YamlValue.none(), path: 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException on incorrect type', () {
      expect(
        () => BrickFile.fromYaml(YamlValue.from(''), path: 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException on incorrect type', () {
      expect(
        () => BrickFile.fromYaml(YamlValue.from(''), path: 'path'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('gets files name when not provided value in the name key', () {
      const fileName = 'file';
      const ext = '.dart';
      const file = '$fileName$ext';
      final paths = [
        join('path', file),
        join('path', 'to', file),
        join('path', 'to', 'some', file),
      ];

      for (final path in paths) {
        final yaml = loadYaml('''
name:
''') as YamlMap;

        final file = BrickFile.fromYaml(YamlValue.from(yaml), path: path);

        expect(
          file.formatName(),
          '{{{$fileName}}}$ext',
        );
      }
    });

    test('can parse all provided values', () {
      final yaml = loadYaml('''
name:
  value: George
  prefix: Mr.
  suffix: Sr.

vars:
  name: value
''') as YamlMap;

      final instance =
          BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

      expect(instance.variables, hasLength(1));
      expect(instance.path, defaultPath);
      expect(instance.name?.prefix, 'Mr.');
      expect(instance.name?.suffix, 'Sr.');
      expect(instance.name?.value, 'George');
    });

    test('can parse include if', () {
      final yaml = loadYaml('''
include_if: check
''') as YamlMap;

      final instance =
          BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

      expect(instance.includeIf, 'check');
    });

    test('can parse include if not', () {
      final yaml = loadYaml('''
include_if_not: check
''') as YamlMap;

      final instance =
          BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

      expect(instance.includeIfNot, 'check');
    });

    test('can parse empty variables', () {
      final yaml = loadYaml('''
name:
''') as YamlMap;

      final instance =
          BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

      expect(instance.variables, isEmpty);

      final yaml2 = loadYaml('''
vars:
''') as YamlMap;

      final instance2 =
          BrickFile.fromYaml(YamlValue.from(yaml2), path: defaultPath);

      expect(instance2.variables, isEmpty);
    });

    test('throws $ConfigException if include_if is not configured correctly',
        () {
      final yaml = loadYaml('''
include_if:
  - check
''') as YamlMap;

      expect(
        () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test(
        'throws $ConfigException if include_if_not is not configured correctly',
        () {
      final yaml = loadYaml('''
include_if_not:
  - check
''') as YamlMap;

      expect(
        () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException if yaml is error', () {
      expect(
        () => BrickFile.fromYaml(
          const YamlValue.error('error'),
          path: defaultPath,
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException if yaml is incorrect type', () {
      expect(
        () => BrickFile.fromYaml(
          const YamlValue.string('Hi, hows it going?'),
          path: defaultPath,
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test(
        'throws $ConfigException if include_if and include_if_not are both used',
        () {
      final yaml = loadYaml('''
include_if: check
include_if_not: check
''') as YamlMap;

      expect(
        () => BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: defaultPath,
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    group('name', () {
      test('can parse when key is not provided', () {
        final yaml = loadYaml('''
vars:
''') as YamlMap;

        final instance =
            BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

        expect(instance.name, isNull);
      });

      test('can parse when string provided', () {
        final yaml = loadYaml('''
name: Alfalfa
''') as YamlMap;

        final instance =
            BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

        expect(instance.name?.value, 'Alfalfa');
      });

      test('can parse when map is provided', () {
        final yaml = loadYaml('''
name:
  value: Mickie Ds
''') as YamlMap;

        final instance =
            BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

        expect(instance.name?.value, 'Mickie Ds');
      });

      test('can parse when value is not provided', () {
        final yaml = loadYaml('''
name:
''') as YamlMap;

        final instance =
            BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

        expect(instance.name?.value, defaultFileName);
      });

      test('throws $ConfigException when not configured correctly', () {
        final yaml = loadYaml('''
name:
  value:
    - 1
''') as YamlMap;

        expect(
          () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
          throwsA(isA<ConfigException>()),
        );
      });
    });

    group('variables', () {
      test('return with vars empty when not provided', () {
        final yaml = loadYaml('''
name:
''') as YamlMap;
        final instance =
            BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath);

        expect(instance.variables, isEmpty);
      });

      test('throws $ConfigException if vars is not of map', () {
        final yaml = loadYaml('''
vars:
  - name
''') as YamlMap;

        expect(
          () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
          throwsA(isA<ConfigException>()),
        );
      });

      test('throws $ConfigException if vars value is not configured correctly',
          () {
        final yaml = loadYaml('''
vars:
  name:
    - value
''') as YamlMap;

        expect(
          () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
          throwsA(isA<ConfigException>()),
        );
      });
    });
  });

  test('throws if extra keys are provided', () {
    final yaml = loadYaml('''
yooooo:
''') as YamlMap;

    expect(
      () => BrickFile.fromYaml(YamlValue.from(yaml), path: defaultPath),
      throwsA(isA<ConfigException>()),
    );
  });

  group('#formatName', () {
    const defaultFile = 'file.dart';
    const defaultPath = defaultFile;
    const name = 'name';
    const prefix = 'prefix';
    const suffix = 'suffix';

    test('return the file name formatted when no provided name', () {
      const instance = BrickFile(defaultFile);

      expect(instance.formatName(), defaultFile);
    });

    test('return the provided name', () {
      final instance = BrickFile.config(defaultPath, name: Name(name));

      expect(instance.formatName(), '{{{$name}}}.dart');
    });

    test('prepends the prefix', () {
      final instance = BrickFile.config(
        defaultPath,
        name: Name(name, prefix: prefix),
      );

      expect(instance.formatName(), '$prefix{{{$name}}}.dart');
    });

    test('appends the suffix', () {
      final instance = BrickFile.config(
        defaultPath,
        name: Name(name, suffix: suffix),
      );

      expect(instance.formatName(), '{{{$name}}}$suffix.dart');
    });

    test('formats the name to mustache format when provided', () {
      final instance = BrickFile.config(
        defaultPath,
        name: Name(name, tag: MustacheTag.snakeCase),
      );

      expect(
        instance.formatName(),
        '{{#snakeCase}}{{{$name}}}{{/snakeCase}}.dart',
      );
    });

    test('does not format the name to mustache format when not provided', () {
      final instance = BrickFile.config(defaultPath, name: Name(name));

      expect(
        instance.formatName(),
        contains('{{{$name}}}'),
      );
    });

    test('includes the extension', () {
      for (final file in fileExtensions.keys) {
        final expected = fileExtensions[file]!;
        final instance = BrickFile.config(file);

        expect(instance.formatName(), endsWith(expected));
      }
    });

    group('#include_if', () {
      test('returns name wrapped in if without formatting or configured name',
          () {
        const instance = BrickFile.config(
          defaultPath,
          includeIf: 'check',
        );

        expect(instance.formatName(), '{{#check}}$defaultPath{{/check}}');
      });

      test('returns name wrapped in if with configured name', () {
        final instance = BrickFile.config(
          defaultPath,
          name: Name(name),
          includeIf: 'check',
        );

        expect(
          instance.formatName(),
          '{{#check}}{{{$name}}}.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name and formatting',
          () {
        final instance = BrickFile.config(
          defaultPath,
          name: Name(name, tag: MustacheTag.snakeCase),
          includeIf: 'check',
        );

        expect(
          instance.formatName(),
          '{{#check}}{{#snakeCase}}{{{$name}}}{{/snakeCase}}.dart{{/check}}',
        );
      });
    });

    group('#include_if_not', () {
      test('returns name wrapped in if without formatting or configured name',
          () {
        const instance = BrickFile.config(
          defaultPath,
          includeIfNot: 'check',
        );

        expect(instance.formatName(), '{{^check}}$defaultPath{{/check}}');
      });

      test('returns name wrapped in if with configured name', () {
        final instance = BrickFile.config(
          defaultPath,
          name: Name(name),
          includeIfNot: 'check',
        );

        expect(
          instance.formatName(),
          '{{^check}}{{{$name}}}.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name and formatting',
          () {
        final instance = BrickFile.config(
          defaultPath,
          name: Name(name, tag: MustacheTag.snakeCase),
          includeIfNot: 'check',
        );

        expect(
          instance.formatName(),
          '{{^check}}{{#snakeCase}}{{{$name}}}{{/snakeCase}}.dart{{/check}}',
        );
      });
    });
  });

  group('#extension', () {
    test('returns the extension', () {
      for (final file in fileExtensions.keys) {
        final expected = fileExtensions[file];
        final instance = BrickFile.config(file);

        expect(instance.extension, expected);
      }
    });

    test('returns multi extension', () {
      final extensions =
          List<String>.generate(10, (index) => "${'.g' * index}.dart");

      for (final extension in extensions) {
        final fileName = 'file$extension';
        final instance = BrickFile.config(fileName);

        expect(instance.extension, extension);
      }
    });
  });

  group('#writeTargetFiles', () {
    late FileSystem fileSystem;
    late File sourceFile;
    const sourceFilePath = 'source.dart';
    const content = 'content';

    BrickDir brickPath({
      String? name,
      String? path,
    }) {
      return BrickDir(
        name: Name(name ?? 'name'),
        path: path ?? defaultPath,
      );
    }

    setUp(() {
      fileSystem = MemoryFileSystem();
      sourceFile = fileSystem.file(sourceFilePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(content);
    });

    test('Throws $FileException when #writeFile throws', () {
      const instance = TestBrickFile(defaultFile);

      expect(
        () => instance.writeTargetFile(
          outOfFileVariables: [],
          partials: [],
          sourceFile: sourceFile,
          dirs: [],
          targetDir: '',
          fileSystem: fileSystem,
          logger: mockLogger,
        ),
        throwsA(isA<FileException>()),
      );

      verifyNoMoreInteractions(mockLogger);
    });

    test('writes a file on the root level', () {
      const instance = BrickFile.config(defaultFile);

      final result = instance.writeTargetFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        dirs: [],
        targetDir: '',
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(result, const FileWriteResult.empty());

      final newFile = fileSystem.file(defaultFile);

      expect(newFile.existsSync(), isTrue);

      verifyNoMoreInteractions(mockLogger);
    });

    test('writes a file on a nested level', () {
      const instance = BrickFile.config(defaultFile);

      final result = instance.writeTargetFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        dirs: [],
        targetDir: 'nested',
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(result, const FileWriteResult.empty());

      final newFile = fileSystem.file(
        join(
          'nested',
          defaultFile,
        ),
      );

      verifyNoMoreInteractions(mockLogger);

      expect(newFile.existsSync(), isTrue);
    });

    test('updates path with configured directory', () {
      final instance = BrickFile.config(defaultPath);
      const replacement = 'something';
      final dir = brickPath(name: replacement, path: join('path', 'to'));

      final result = instance.writeTargetFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        dirs: [dir],
        targetDir: '',
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedVariables: {'something'},
          usedPartials: {},
        ),
      );

      final newFile = fileSystem.file(
        join(
          'path',
          '{{{$replacement}}}',
          defaultFile,
        ),
      );

      verifyNoMoreInteractions(mockLogger);

      expect(newFile.existsSync(), isTrue);
    });

    test('updates file name when provided', () {
      const replacement = 'something';
      final instance = BrickFile.config(defaultPath, name: Name(replacement));

      final result = instance.writeTargetFile(
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        dirs: [],
        targetDir: '',
        fileSystem: fileSystem,
        logger: mockLogger,
      );

      expect(
        result,
        const FileWriteResult(
          usedVariables: {replacement},
          usedPartials: {},
        ),
      );

      final newFile = fileSystem.file(
        join(
          'path',
          'to',
          '{{{$replacement}}}.dart',
        ),
      );

      verifyNoMoreInteractions(mockLogger);

      expect(newFile.existsSync(), isTrue);
    });
  });
}

class TestBrickFile extends BrickFile {
  const TestBrickFile(String path)
      : super.config(
          path,
        );

  @override
  FileWriteResult writeFile({
    required List<Variable> outOfFileVariables,
    required File targetFile,
    required File sourceFile,
    required List<Variable> variables,
    required List<Partial> partials,
    required FileSystem? fileSystem,
    required Logger logger,
  }) {
    throw const FileException(file: 'file', reason: 'reason');
  }
}
