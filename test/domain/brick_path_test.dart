import 'package:brick_oven/domain/brick_path.dart';
import 'package:test/test.dart';

void main() {
  group('#apply', () {
    const replacement = 'batman';

    BrickPath brickPath(String path, [String replacement = replacement]) {
      return BrickPath(
        path: path,
        name: replacement,
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
        group('without slashes', () {
          test('as starting position', () {
            final path = brickPath('path');
            const original = '/path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });

          test('as non starting position', () {
            final path = brickPath('to');
            const original = '/path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with starting slash', () {
          test('as starting position', () {
            final path = brickPath('/path');
            const original = '/path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });

          test('as non starting position', () {
            final path = brickPath('/to');
            const original = '/path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });
        });

        group('with ending slash', () {
          test('as starting position', () {
            final path = brickPath('path/');
            const original = '/path/to/some/file.png';
            final result = path.apply(original, originalPath: original);

            expect(result, original);
          });

          test('as non starting position', () {
            final path = brickPath('to/');
            const original = '/path/to/some/file.png';
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

        final layer = brickPath('foo');
        path = layer.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/bar/baz/foo',
        );
      });

      test('foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final layer = brickPath('foo/bar');
        path = layer.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/baz/foo/bar',
        );
      });

      test('foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final layer = brickPath('foo/bar/baz');
        path = layer.apply(path, originalPath: originalPath);

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

        final layer = brickPath('foo/bar/baz/foo');
        path = layer.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
        );
      });

      test('foo/bar/baz/foo/bar (bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final layer = brickPath('foo/bar/baz/foo/bar');
        path = layer.apply(path, originalPath: originalPath);

        expect(
          path,
          'foo/bar/baz/foo/{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}',
        );
      });

      test('foo/bar/baz/foo/bar/baz (baz)', () {
        const originalPath = 'foo/bar/baz/foo/bar/baz';
        var path = originalPath;

        final layer = brickPath('foo/bar/baz/foo/bar/baz');
        path = layer.apply(path, originalPath: originalPath);

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

        final layer = brickPath('foo');
        path = layer.apply(path, originalPath: originalPath);

        final layer2 = brickPath('foo/bar/baz/foo', replacement2);
        path = layer2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/bar/baz/{{#snakeCase}}{{{$replacement2}}}{{/snakeCase}}',
        );
      });

      test('foo & foo/bar (foo & bar)', () {
        const originalPath = 'foo/bar/baz/foo/bar';
        var path = originalPath;

        final layer = brickPath('foo');
        path = layer.apply(path, originalPath: originalPath);

        final layer2 = brickPath('foo/bar', replacement2);
        path = layer2.apply(path, originalPath: originalPath);

        expect(
          path,
          '{{#snakeCase}}{{{$replacement}}}{{/snakeCase}}/{{#snakeCase}}{{{$replacement2}}}{{/snakeCase}}/baz/foo/bar',
        );
      });
    });
  });
}
