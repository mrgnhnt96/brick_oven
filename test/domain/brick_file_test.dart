// ignore_for_file: cascade_invocations

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_url.dart';
import 'package:brick_oven/domain/content_replacement.dart';
import 'package:brick_oven/domain/file_write_result.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';
import '../test_utils/mocks.dart';

void main() {
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

  test('can be instantiated', () {
    expect(BrickFile(join('path', 'to', 'file.dart')), isA<BrickFile>());
  });

  test('throws assertion error when includeIf and includeIfNot are both set',
      () {
    expect(
      () => BrickFile.config(
        'path',
        includeIf: 'check',
        includeIfNot: 'checkNot',
      ),
      throwsA(isA<AssertionError>()),
    );
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

      final instance = BrickFile.fromYaml(
        YamlValue.from(yaml),
        path: join('path', 'to', 'file.dart'),
      );

      expect(instance.variables, hasLength(1));
      expect(instance.path, join('path', 'to', 'file.dart'));
      expect(instance.name?.prefix, 'Mr.');
      expect(instance.name?.suffix, 'Sr.');
      expect(instance.name?.value, 'George');
    });

    test('can parse include if', () {
      final yaml = loadYaml('''
include_if: check
''') as YamlMap;

      final instance = BrickFile.fromYaml(
        YamlValue.from(yaml),
        path: join('path', 'to', 'file.dart'),
      );

      expect(instance.includeIf, 'check');
    });

    test('can parse include if not', () {
      final yaml = loadYaml('''
include_if_not: check
''') as YamlMap;

      final instance = BrickFile.fromYaml(
        YamlValue.from(yaml),
        path: join('path', 'to', 'file.dart'),
      );

      expect(instance.includeIfNot, 'check');
    });

    test('can parse empty variables', () {
      final yaml = loadYaml('''
name:
''') as YamlMap;

      final instance = BrickFile.fromYaml(
        YamlValue.from(yaml),
        path: join('path', 'to', 'file.dart'),
      );

      expect(instance.variables, isEmpty);

      final yaml2 = loadYaml('''
vars:
''') as YamlMap;

      final instance2 = BrickFile.fromYaml(
        YamlValue.from(yaml2),
        path: join('path', 'to', 'file.dart'),
      );

      expect(instance2.variables, isEmpty);
    });

    test('throws $ConfigException if include_if is not configured correctly',
        () {
      final yaml = loadYaml('''
include_if:
  - check
''') as YamlMap;

      expect(
        () => BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        ),
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
        () => BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException if yaml is error', () {
      expect(
        () => BrickFile.fromYaml(
          const YamlValue.error('error'),
          path: join('path', 'to', 'file.dart'),
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException if yaml is incorrect type', () {
      expect(
        () => BrickFile.fromYaml(
          const YamlValue.string('Hi, hows it going?'),
          path: join('path', 'to', 'file.dart'),
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
          path: join('path', 'to', 'file.dart'),
        ),
        throwsA(isA<ConfigException>()),
      );
    });

    group('name', () {
      test('can parse when key is not provided', () {
        final yaml = loadYaml('''
vars:
''') as YamlMap;

        final instance = BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        );

        expect(instance.name, isNull);
      });

      test('can parse when string provided', () {
        final yaml = loadYaml('''
name: Alfalfa
''') as YamlMap;

        final instance = BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        );

        expect(instance.name?.value, 'Alfalfa');
      });

      test('can parse when map is provided', () {
        final yaml = loadYaml('''
name:
  value: Mickie Ds
''') as YamlMap;

        final instance = BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        );

        expect(instance.name?.value, 'Mickie Ds');
      });

      test('can parse when value is not provided', () {
        final yaml = loadYaml('''
name:
''') as YamlMap;

        final instance = BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        );

        expect(instance.name?.value, 'file');
      });

      test('throws $ConfigException when not configured correctly', () {
        final yaml = loadYaml('''
name:
  value:
    - 1
''') as YamlMap;

        expect(
          () => BrickFile.fromYaml(
            YamlValue.from(yaml),
            path: join('path', 'to', 'file.dart'),
          ),
          throwsA(isA<ConfigException>()),
        );
      });
    });

    group('variables', () {
      test('return with vars empty when not provided', () {
        final yaml = loadYaml('''
name:
''') as YamlMap;
        final instance = BrickFile.fromYaml(
          YamlValue.from(yaml),
          path: join('path', 'to', 'file.dart'),
        );

        expect(instance.variables, isEmpty);
      });

      test('throws $ConfigException if vars is not of map', () {
        final yaml = loadYaml('''
vars:
  - name
''') as YamlMap;

        expect(
          () => BrickFile.fromYaml(
            YamlValue.from(yaml),
            path: join('path', 'to', 'file.dart'),
          ),
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
          () => BrickFile.fromYaml(
            YamlValue.from(yaml),
            path: join('path', 'to', 'file.dart'),
          ),
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
      () => BrickFile.fromYaml(
        YamlValue.from(yaml),
        path: join('path', 'to', 'file.dart'),
      ),
      throwsA(isA<ConfigException>()),
    );
  });

  group('#formatName', () {
    test('return the file name formatted when no provided name', () {
      const instance = BrickFile('file.dart');

      expect(instance.formatName(), 'file.dart');
    });

    test('return the provided name', () {
      final instance =
          BrickFile.config(join('path', 'to', 'file.dart'), name: Name('name'));

      expect(instance.formatName(), '{{{name}}}.dart');
    });

    test('prepends the prefix', () {
      final instance = BrickFile.config(
        join('path', 'to', 'file.dart'),
        name: Name('name', prefix: 'prefix'),
      );

      expect(instance.formatName(), 'prefix{{{name}}}.dart');
    });

    test('appends the suffix', () {
      final instance = BrickFile.config(
        join('path', 'to', 'file.dart'),
        name: Name('name', suffix: 'suffix'),
      );

      expect(instance.formatName(), '{{{name}}}suffix.dart');
    });

    test('formats the name to mustache format when provided', () {
      final instance = BrickFile.config(
        join('path', 'to', 'file.dart'),
        name: Name('name', tag: MustacheTag.snakeCase),
      );

      expect(
        instance.formatName(),
        '{{#snakeCase}}{{{name}}}{{/snakeCase}}.dart',
      );
    });

    test('does not format the name to mustache format when not provided', () {
      final instance =
          BrickFile.config(join('path', 'to', 'file.dart'), name: Name('name'));

      expect(
        instance.formatName(),
        contains('{{{name}}}'),
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
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          includeIf: 'check',
        );

        expect(
          instance.formatName(),
          '{{#check}}file.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name', () {
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          name: Name('name'),
          includeIf: 'check',
        );

        expect(
          instance.formatName(),
          '{{#check}}{{{name}}}.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name and formatting',
          () {
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          name: Name('name', tag: MustacheTag.snakeCase),
          includeIf: 'check',
        );

        expect(
          instance.formatName(),
          '{{#check}}{{#snakeCase}}{{{name}}}{{/snakeCase}}.dart{{/check}}',
        );
      });
    });

    group('#include_if_not', () {
      test('returns name wrapped in if without formatting or configured name',
          () {
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          includeIfNot: 'check',
        );

        expect(
          instance.formatName(),
          '{{^check}}file.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name', () {
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          name: Name('name'),
          includeIfNot: 'check',
        );

        expect(
          instance.formatName(),
          '{{^check}}{{{name}}}.dart{{/check}}',
        );
      });

      test('returns name wrapped in if with configured name and formatting',
          () {
        final instance = BrickFile.config(
          join('path', 'to', 'file.dart'),
          name: Name('name', tag: MustacheTag.snakeCase),
          includeIfNot: 'check',
        );

        expect(
          instance.formatName(),
          '{{^check}}{{#snakeCase}}{{{name}}}{{/snakeCase}}.dart{{/check}}',
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

  group('#newPathForFile', () {
    test('returns when path', () {
      const file = BrickFile('path/to/file.dart');

      final pathContent = file.newPathForFile(urls: [], dirs: []);

      const expected = ContentReplacement(
        content: 'path/to/file.dart',
        used: {},
        data: {'url': null},
      );

      expect(pathContent, expected);
    });

    test('returns when path is url', () {
      final url = BrickUrl('path/to/url');

      const file = BrickFile('path/to/url');

      final pathContent = file.newPathForFile(urls: [url], dirs: []);

      final expected = ContentReplacement(
        content: 'path/to/{{{% url %}}}',
        used: const {'url'},
        data: {'url': url},
      );

      expect(pathContent, expected);
    });

    test('returns when path is dir', () {
      const file = BrickFile('path/to/dir');

      final pathContent = file.newPathForFile(
        urls: [],
        dirs: [
          BrickDir(
            path: 'path/to/dir',
            name: Name('my_dir'),
          ),
        ],
      );

      const expected = ContentReplacement(
        content: 'path/to/{{{my_dir}}}',
        used: {'my_dir'},
        data: {'url': null},
      );

      expect(pathContent, expected);
    });

    test('applies dirs to path', () {
      final file = BrickFile('path/to/dir/file.dart', name: Name('file'));

      final pathContent = file.newPathForFile(
        urls: [],
        dirs: [
          BrickDir(
            path: 'path/to',
            name: Name('to'),
          ),
          BrickDir(
            path: 'path/to/dir',
            name: Name('dir'),
          ),
          BrickDir(
            path: 'path',
            name: Name('path'),
          ),
        ],
      );

      const expected = ContentReplacement(
        content: '{{{path}}}/{{{to}}}/{{{dir}}}/{{{file}}}.dart',
        used: {'path', 'to', 'dir', 'file'},
        data: {'url': null},
      );

      expect(pathContent, expected);
    });

    test('applies dirs to url', () {
      final url = BrickUrl('path/to/dir/url');
      const file = BrickFile('path/to/dir/url');

      final pathContent = file.newPathForFile(
        urls: [url],
        dirs: [
          BrickDir(
            path: 'path/to',
            name: Name('to'),
          ),
          BrickDir(
            path: 'path/to/dir',
            name: Name('dir'),
          ),
          BrickDir(
            path: 'path',
            name: Name('path'),
          ),
        ],
      );

      final expected = ContentReplacement(
        content: '{{{path}}}/{{{to}}}/{{{dir}}}/{{{% url %}}}',
        used: const {'path', 'to', 'dir', 'url'},
        data: {'url': url},
      );

      expect(pathContent, expected);
    });
  });

  group('#writeTargetFiles', () {
    late FileSystem memoryFileSystem;

    setUp(() {
      memoryFileSystem = MemoryFileSystem();
    });

    test('Throws $FileException when #writeFile throws', () {
      const instance = TestBrickFile.throws('file.dart');

      expect(
        () => instance.writeTargetFile(
          urls: [],
          outOfFileVariables: [],
          partials: [],
          sourceFile: memoryFileSystem.file('file.dart'),
          dirs: [],
          targetDir: '',
          fileSystem: memoryFileSystem,
          logger: mockLogger,
        ),
        throwsA(isA<FileException>()),
      );

      verifyNoMoreInteractions(mockLogger);
    });

    test('returns used variables from write file', () {
      final instance = BrickFile.config(
        'path/to/file.dart',
        variables: const [Variable(name: 'var')],
        includeIf: 'check',
        name: Name('name'),
      );

      final sourceFile = memoryFileSystem.file('file.dart');

      sourceFile
        ..createSync(recursive: true)
        ..writeAsStringSync('var\npartials.file');

      final result = instance.writeTargetFile(
        urls: [],
        outOfFileVariables: [],
        partials: const [
          Partial(path: 'path/to/file.dart'),
        ],
        sourceFile: sourceFile,
        dirs: [
          BrickDir(
            path: 'path/to',
            name: Name('to'),
          ),
        ],
        targetDir: '',
        fileSystem: memoryFileSystem,
        logger: mockLogger,
      );

      const expected = FileWriteResult(
        usedPartials: {'path/to/file.dart'},
        usedVariables: {'var', 'name', 'check', 'to'},
      );

      expect(result, expected);

      verifyNoMoreInteractions(mockLogger);
    });

    test('returns used variables from write url', () {
      const instance = BrickFile.config('path/to/url');

      final sourceFile = memoryFileSystem.file('file');

      sourceFile.createSync(recursive: true);

      final result = instance.writeTargetFile(
        urls: [BrickUrl('path/to/url')],
        outOfFileVariables: [],
        partials: [],
        sourceFile: sourceFile,
        dirs: [
          BrickDir(
            path: 'path/to',
            name: Name('to'),
          ),
        ],
        targetDir: '',
        fileSystem: memoryFileSystem,
        logger: mockLogger,
      );

      const expected = FileWriteResult(
        usedPartials: {},
        usedVariables: {'url', 'to'},
      );

      expect(result, expected);

      verifyNoMoreInteractions(mockLogger);
    });
  });

  group('#nameVariables', () {
    test('returns all variables associated with the name', () {
      final instance = BrickFile.config(
        'path',
        includeIf: 'check',
        name: Name('name', section: 'section'),
        variables: const [
          Variable(name: 'var'),
        ],
      );

      expect(instance.nameVariables, {'check', 'name', 'section'});

      final instance2 = BrickFile.config(
        'path',
        includeIfNot: 'check',
        name: Name('name', invertedSection: 'section'),
        variables: const [
          Variable(name: 'var'),
        ],
      );

      expect(instance2.nameVariables, {'check', 'name', 'section'});
    });
  });
}

class TestBrickFile extends BrickFile {
  const TestBrickFile.throws(String path) : super.config(path);

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
