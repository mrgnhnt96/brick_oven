import 'package:brick_oven/enums/mustache_format.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:yaml/yaml.dart';

void main() {
  const highestLevel = 'dir';
  const dirPath = 'path/to/some/$highestLevel';

  group('$BrickPath unnamed ctor', () {
    test('can be instanciated', () {
      expect(
        () => BrickPath(name: const Name(highestLevel), path: dirPath),
        returnsNormally,
      );
    });

    test('removes leading and trailing slashes from path', () {
      final brickPath = BrickPath(name: const Name('name'), path: '/$dirPath');

      expect(brickPath.path, dirPath);

      final brickPath2 = BrickPath(name: const Name('name'), path: '$dirPath/');

      expect(brickPath2.path, dirPath);
    });

    test('placeholder is the highest level from path', () {
      final brickPath = BrickPath(name: const Name('name'), path: '/$dirPath');

      expect(brickPath.placeholder, highestLevel);
    });
  });

  group('#fromYaml', () {
    test('throws when yaml is error', () {
      expect(
        () => BrickPath.fromYaml(const YamlValue.error('error'), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws when path points to a file', () {
      expect(
        () => BrickPath.fromYaml(const YamlValue.none(), '$dirPath/file.dart'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws when extra keys are provided', () {
      final yaml = loadYaml('''
name: name
path: path
''') as YamlMap;

      expect(
        () => BrickPath.fromYaml(YamlValue.yaml(yaml), dirPath),
        throwsA(isA<ConfigException>()),
      );
    });

    test('name is the highest level from path when null is provided', () {
      final brickPath = BrickPath.fromYaml(const YamlValue.none(), dirPath);

      expect(brickPath.name.value, highestLevel);
    });

    test('returns name from yaml map', () {
      final yaml = loadYaml('''
name: name
''') as YamlMap;

      final brickPath = BrickPath.fromYaml(YamlValue.yaml(yaml), dirPath);

      expect(brickPath.name.value, 'name');
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
      expect(BrickPath.separatorPattern, isA<RegExp>());
    });

    test('#separatePath separates path into segments', () {
      for (final path in paths.keys) {
        final segments = paths[path];

        expect(BrickPath.separatePath(path).length, segments);
      }
    });
  });

  group('#slashPattern', () {
    test('returns a RegExp', () {
      expect(BrickPath.slashPattern, isA<RegExp>());
    });

    test('#cleanPath removes slashes from beginning and end of path', () {
      for (final path in paths.keys) {
        final cleanPath = BrickPath.cleanPath(path);
        separator;

        expect(cleanPath, isNot(startsWith('/')));
        expect(cleanPath, isNot(startsWith(r'\')));
        expect(cleanPath, isNot(endsWith('/')));
        expect(cleanPath, isNot(endsWith(r'\')));
      }
    });
  });

  test('#configuredParts returns segmented path', () {
    for (final path in paths.keys) {
      final segments = paths[path];
      final brickPath = BrickPath(name: const Name('name'), path: path);

      expect(brickPath.configuredParts.length, segments);
    }
  });

  group('#apply', () {
    const replacement = 'batman';

    BrickPath brickPath(String path, {MustacheFormat? format, String? name}) {
      return BrickPath(
        path: path,
        name: Name(name ?? replacement, format: format),
      );
    }

    test('formats the path when provided', () {
      const original = '/path/to/other/file.png';
      final brick = brickPath(
        'path',
        format: MustacheFormat.snakeCase,
      );

      expect(
        brick.apply(original, originalPath: original),
        '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/to/other/file.png',
      );
    });

    group('return original path when', () {
      test('parts do not match', () {
        final path = brickPath('/path/to/some');
        const original = '/path/to/other/file.png';
        final result = path.apply(original, originalPath: original);
        expect(result, original);
      });

      test('brick path is not a directory', () {
        final path = brickPath('/path/to/some/file.png');
        const original = '/path/to/some/file.png';
        final result = path.apply(original, originalPath: original);

        expect(result, original);
      });

      group('brick path is not more than 1 level', () {
        String toFormat(String name) {
          return '{{{$name}}}';
        }

        group('without slashes', () {
          test('as starting position', () {
            const dir = 'path';
            const filePath = '/to/some/file.png';

            final path = brickPath(dir);
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = brickPath('to');
            const original = 'path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with starting slash', () {
          test('as starting position', () {
            const dir = '/path';
            const filePath = '/to/some/file.png';

            final path = brickPath(dir);
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = brickPath('/to');
            const original = 'path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with ending slash', () {
          test('as starting position', () {
            const dir = 'path/';
            const filePath = '/to/some/file.png';

            final path = brickPath(dir);
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toFormat(replacement)}$filePath');
          });

          test('as non starting position', () {
            final path = brickPath('to/');
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

        final brick = brickPath('foo');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/bar/baz/foo',
        );
      });

      test('foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo/bar');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/{{{$replacement}}}/baz/foo/bar',
        );
      });

      test('foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz');
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

        final brick = brickPath('foo/bar/baz/foo');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/{{{$replacement}}}',
        );
      });

      test('foo/bar/baz/foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz/foo/bar');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/{{{$replacement}}}',
        );
      });

      test('foo/bar/baz/foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz/foo/bar/baz');
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

        final brick = brickPath('foo');
        path = brick.apply(path, originalPath: originalPath);

        final brick2 = brickPath('foo/bar/baz/foo', name: replacement2);
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/bar/baz/{{{$replacement2}}}',
        );
      });

      test('foo & foo/bar (foo & bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo');
        path = brick.apply(path, originalPath: originalPath);

        final brick2 = brickPath('foo/bar', name: replacement2);
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{{$replacement}}}/{{{$replacement2}}}/baz/foo/bar',
        );
      });
    });
  });
}
