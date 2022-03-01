import 'package:path/path.dart';
import 'package:test/test.dart';

import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import '../utils/fakes.dart';

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
    test('throws when path points to a file', () {
      expect(
        () => BrickPath.fromYaml(
          '$dirPath/file.dart',
          const YamlValue.none(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when extra keys are provided', () {
      final yaml = FakeYamlMap(
        <String, dynamic>{'name': 'name', 'path': 'path'},
      );

      expect(
        () => BrickPath.fromYaml(dirPath, YamlValue.yaml(yaml)),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('name is the highest level from path when null is provided', () {
      final brickPath = BrickPath.fromYaml(dirPath, const YamlValue.none());

      expect(brickPath.name.value, highestLevel);
    });

    test('returns name from yaml map', () {
      final yaml = FakeYamlMap(<String, dynamic>{'name': 'name'});

      final brickPath = BrickPath.fromYaml(dirPath, YamlValue.yaml(yaml));

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

    BrickPath brickPath(String path, [String replacement = replacement]) {
      return BrickPath(
        path: path,
        name: Name(replacement),
      );
    }

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
        String toSnake(String name) {
          return '{{#snakeCase}}{{{$name}}}{{/snakeCase}}';
        }

        group('without slashes', () {
          test('as starting position', () {
            const dir = 'path';
            const filePath = '/to/some/file.png';

            final path = brickPath(dir);
            const original = '$dir$filePath';

            final result = path.apply(original, originalPath: original);

            expect(result, '${toSnake(replacement)}$filePath');
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

            expect(result, '${toSnake(replacement)}$filePath');
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

            expect(result, '${toSnake(replacement)}$filePath');
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
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/bar/baz/foo',
        );
      });

      test('foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo/bar');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/baz/foo/bar',
        );
      });

      test('foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/foo/bar/baz',
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
          'foo/bar/baz/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
        );
      });

      test('foo/bar/baz/foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz/foo/bar');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
        );
      });

      test('foo/bar/baz/foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final brick = brickPath('foo/bar/baz/foo/bar/baz');
        path = brick.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/bar/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
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

        final brick2 = brickPath('foo/bar/baz/foo', replacement2);
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/bar/baz/{{#snakeCase}}{{{$replacement2}}}{{/snakeCase}}',
        );
      });

      test('foo & foo/bar (foo & bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final brick = brickPath('foo');
        path = brick.apply(path, originalPath: originalPath);

        final brick2 = brickPath('foo/bar', replacement2);
        path = brick2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/{{#snakeCase}}{{{$replacement2}}}{{/snakeCase}}/baz/foo/bar',
        );
      });
    });
  });

  group('#props', () {
    final brick = BrickPath(name: const Name('foo'), path: 'bar/baz');

    test('length should be 3', () {
      expect(brick.props.length, 3);
    });

    test('should contain name', () {
      expect(brick.props.contains(const Name('foo')), isTrue);
    });

    test('should contain path', () {
      expect(brick.props.contains('bar/baz'), isTrue);
    });

    test('should contain placeholder', () {
      expect(brick.props.contains('baz'), isTrue);
    });
  });
}
