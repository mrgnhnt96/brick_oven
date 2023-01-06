import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/enums/mustache_tag.dart';
import 'package:brick_oven/src/exception.dart';

void main() {
  const highestLevel = 'dir';
  const dirPath = 'path/to/some/$highestLevel';

  group('$BrickDir unnamed ctor', () {
    test('can be instantiated', () {
      expect(
        () => BrickDir(name: Name(highestLevel), path: dirPath),
        returnsNormally,
      );
    });

    test('throws assertion error when file path is provided', () {
      expect(
        () => BrickDir(path: '/path/to/some/file.png'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertion error when includeIf and includeIfNot are both set',
        () {
      expect(
        () => BrickDir(
          path: dirPath,
          includeIf: 'check',
          includeIfNot: 'checkNot',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('removes leading and trailing slashes from path', () {
      final brickPath = BrickDir(name: Name('name'), path: '/$dirPath');

      expect(brickPath.path, dirPath);

      final brickPath2 = BrickDir(name: Name('name'), path: './$dirPath');

      expect(brickPath2.path, dirPath);

      final brickPath3 = BrickDir(name: Name('name'), path: '$dirPath/');

      expect(brickPath3.path, dirPath);
    });
  });

  group('#fromYaml', () {
    test('throws $ConfigException when file path is provided', () {
      expect(
        () => BrickDir.fromYaml(const YamlValue.none(), 'path/to/file.png'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when yaml is error', () {
      expect(
        () => BrickDir.fromYaml(const YamlValue.error('error'), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when path points to a file', () {
      expect(
        () => BrickDir.fromYaml(const YamlValue.none(), '$dirPath/file.dart'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when extra keys are provided', () {
      final yaml = loadYaml('''
name: name
path: path
''') as YamlMap;

      expect(
        () => BrickDir.fromYaml(YamlValue.yaml(yaml), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('can parse include if', () {
      final yaml = loadYaml('''
include_if: check
''') as YamlMap;

      final instance = BrickDir.fromYaml(YamlValue.from(yaml), dirPath);

      expect(instance.includeIf, 'check');
    });

    test('can parse include if not', () {
      final yaml = loadYaml('''
include_if_not: check
''') as YamlMap;

      final instance = BrickDir.fromYaml(YamlValue.from(yaml), dirPath);

      expect(instance.includeIfNot, 'check');
    });

    test('throws $ConfigException when null is provided', () {
      expect(
        () => BrickDir.fromYaml(const YamlValue.none(), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when yaml is not a map', () {
      expect(
        () => BrickDir.fromYaml(YamlValue.list(YamlList()), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when name is not configured correctly', () {
      final yaml = loadYaml('''
name:
  name: name
''') as YamlMap;

      expect(
        () => BrickDir.fromYaml(YamlValue.from(yaml), dirPath),
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
        () => BrickDir.fromYaml(YamlValue.from(yaml), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException if include_if is not configured correctly',
        () {
      final yaml = loadYaml('''
include_if:
  - check
''') as YamlMap;

      expect(
        () => BrickDir.fromYaml(YamlValue.from(yaml), dirPath),
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
        () => BrickDir.fromYaml(YamlValue.from(yaml), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('returns name from yaml map', () {
      final yaml = loadYaml('''
name: name
''') as YamlMap;

      final brickPath = BrickDir.fromYaml(YamlValue.yaml(yaml), dirPath);

      expect(brickPath.name?.value, 'name');
    });

    test('returns name from string', () {
      final yaml = loadYaml('''
name
''');

      final brickPath = BrickDir.fromYaml(YamlValue.from(yaml), dirPath);

      expect(brickPath.name?.value, 'name');
    });
  });

  const paths = {
    'path/to/some/dir': 4,
    'path/to/some/dir/': 4,
    '/path/to/some/dir': 4,
    '/path/to/some/dir/': 4,
    '/path/to/some/dir/file.dart': 5,
    '/path/to/some/dir/file.dart/': 5,
    '//path/to/some/dir': 4,
    '//path/to/some/dir//': 4,
    '///path/to/some/dir///': 4,
    '//path/to/some/dir//file.dart': 5,
    r'path\to\some\dir': 4,
    r'path\to\some\dir\': 4,
    r'\path\to\some\dir': 4,
    r'\path\to\some\dir\': 4,
    r'\path\to\some\dir\file.dart': 5,
    r'\path\to\some\dir\file.dart\': 5,
    r'\\path\to\some\dir': 4,
    r'\\path\to\some\dir\\': 4,
    r'\\path\to\some\dir\\file.dart': 5,
  };

  group('#separatorPattern', () {
    test('returns a RegExp', () {
      expect(BrickDir.separatorPattern, isA<RegExp>());
    });

    test('separates path into segments', () {
      for (final path in paths.keys) {
        final segments = paths[path];

        expect(BrickDir.separatePath(path).length, segments);
      }
    });

    test('ignores mustache tag separators', () {
      const paths = {
        'path/to/{{#check}}{{{value}}}{{/check}/dir': 4,
        'path/{{to}}/{{#check}}{{{value}}}{{/check}/dir': 4,
        '{{^if}}path{{/if}}/{{to}}/{{#check}}{{{value}}}{{/check}/dir': 4,
      };

      for (final path in paths.keys) {
        final segments = paths[path];

        expect(BrickDir.separatePath(path).length, segments);
      }
    });
  });

  group('#leadingAndTrailingSlashPattern', () {
    test('returns a RegExp', () {
      expect(BrickDir.leadingAndTrailingSlashPattern, isA<RegExp>());
    });

    test('#cleanPath removes slashes from beginning and end of path', () {
      for (final path in paths.keys) {
        final cleanPath = BrickDir.cleanPath(path);
        separator;

        expect(cleanPath, isNot(startsWith('/')));
        expect(cleanPath, isNot(startsWith(r'\')));
        expect(cleanPath, isNot(endsWith('/')));
        expect(cleanPath, isNot(endsWith(r'\')));
      }
    });
  });

  group('#apply', () {
    const replacement = 'batman';

    test('formats the path when provided', () {
      const original = '/path/to/other/file.png';
      final brick = BrickDir(
        path: 'path',
        name: Name(replacement, tag: MustacheTag.snakeCase),
      );

      expect(
        brick.apply(original, originalPath: original),
        '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/to/other/file.png',
      );
    });

    group('return original path when', () {
      test('parts do not match', () {
        final path = BrickDir(path: '/path/to/some');

        const original = '/path/to/other/file.png';
        final result = path.apply(original, originalPath: original);
        expect(result, original);
      });

      test('paths do not match', () {
        const originalPath = 'test/android_tests.dart';
        var path = originalPath;

        final brick = BrickDir(path: 'android');
        path = brick.apply(path, originalPath: originalPath);

        expect(path, 'test/android_tests.dart');
      });

      group('brick path is not more than 1 level', () {
        String toFormat(String name) {
          return '{{{$name}}}';
        }

        group('without slashes', () {
          test('as starting position', () {
            const dir = 'path';
            const filePath = '/to/some/file.png';

            final path = BrickDir(
              path: dir,
              name: Name(replacement),
            );

            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = BrickDir(path: 'to');
            const original = 'path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with starting slash', () {
          test('as starting position', () {
            const dir = '/path';
            const filePath = '/to/some/file.png';

            final path = BrickDir(
              path: dir,
              name: Name(replacement),
            );
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = BrickDir(
              path: '/to',
              name: Name(replacement),
            );
            const original = 'path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with ending slash', () {
          test('as starting position', () {
            const dir = 'path/';
            const filePath = '/to/some/file.png';

            final path = BrickDir(
              path: dir,
              name: Name(replacement),
            );
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = BrickDir(path: 'to/');
            const original = 'path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });
      });
    });

    group('replaces only the first occurrence', () {
      test('foo (foo)', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/bar/baz/foo',
        );
      });

      test('foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/{{{$replacement}}}/baz/foo/bar',
        );
      });

      test('foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar/baz',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/{{{$replacement}}}/foo/bar/baz',
        );
      });
    });

    group('replaces only the second occurrence', () {
      test('foo/bar/baz/foo (foo)', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar/baz/foo',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/{{{$replacement}}}',
        );
      });

      test('foo/bar/baz/foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar/baz/foo/bar',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/{{{$replacement}}}',
        );
      });

      test('foo/bar/baz/foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar/baz/foo/bar/baz',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/bar/{{{$replacement}}}',
        );
      });
    });

    group('replaces the first and second occurrences', () {
      const replacement2 = 'superman';
      test('foo & foo/bar/baz/foo (foo & foo)', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        final brick2 =
            BrickDir(path: 'foo/bar/baz/foo', name: Name(replacement2));
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/bar/baz/{{{$replacement2}}}',
        );
      });

      test('foo & foo/bar (foo & bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement),
        );
        path = brick.apply(path, originalPath: originalPath);

        final brick2 = BrickDir(path: 'foo/bar', name: Name(replacement2));
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/{{{$replacement2}}}/baz/foo/bar',
        );
      });
    });

    group('#includeIf', () {
      test('wraps path with include if without name configuration', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          includeIf: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#check}}foo{{/check}}/bar/baz/foo',
        );
      });

      test('wraps nested path with include if without name configuration', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo/bar/baz/foo',
          includeIf: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/{{#check}}foo{{/check}}',
        );
      });

      test('wraps path with include if with name configuration', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement),
          includeIf: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#check}}{{{$replacement}}}{{/check}}/bar/baz/foo',
        );
      });

      test('wraps path with include if with name configuration and formatting',
          () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement, tag: MustacheTag.snakeCase),
          includeIf: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#check}}{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}{{/check}}/bar/baz/foo',
        );
      });
    });

    group('#includeIfNot', () {
      test('wraps path with include if not without name configuration', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          includeIfNot: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{^check}}foo{{/check}}/bar/baz/foo',
        );
      });

      test('wraps path with include if not with name configuration', () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement),
          includeIfNot: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{^check}}{{{$replacement}}}{{/check}}/bar/baz/foo',
        );
      });

      test(
          'wraps path with include if not with name configuration and formatting',
          () {
        const originalPath = 'foo/bar/baz/foo';
        var path = originalPath;

        final brick = BrickDir(
          path: 'foo',
          name: Name(replacement, tag: MustacheTag.snakeCase),
          includeIfNot: 'check',
        );
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{^check}}{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}{{/check}}/bar/baz/foo',
        );
      });
    });
  });

  group('#variables', () {
    test('returns all variables associated with the name', () {
      final instance = BrickDir(
        path: 'path',
        includeIf: 'check',
        name: Name('name', section: 'section'),
      );

      expect(instance.variables, {'check', 'name', 'section'});

      final instance2 = BrickDir(
        path: 'path',
        includeIfNot: 'check',
        name: Name('name', invertedSection: 'section'),
      );

      expect(instance2.variables, {'check', 'name', 'section'});
    });
  });
}
