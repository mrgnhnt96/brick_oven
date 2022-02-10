import 'dart:io';

import 'package:brick_oven/brick_oven.dart';
import 'package:test/test.dart';

void main() {
  test('can be instanciated', () {
    expect(BrickArguments.new, returnsNormally);
  });

  group('#from', () {
    test('parses watch', () {
      const args = ['-w', '--watch'];

      for (final arg in args) {
        final instance = BrickArguments.from([arg]);

        expect(instance.watch, isTrue);
      }
    });

    test('parses output', () {
      const args = ['-o', '--output'];
      const outDir = 'out_dir';

      for (final arg in args) {
        final instance = BrickArguments.from([arg, outDir]);

        expect(instance.outputDir, outDir);
      }
    });

    test('parses help', () {
      const args = ['-h', '--help'];

      for (final arg in args) {
        BrickArguments.from([arg]);

        expect(exitCode, equals(0));
      }
    });

    test('throws when extra keys are provided', () {
      const args = [
        '-w --watch',
        '--watch -w',
        '-help',
        'some',
      ];

      for (final arg in args) {
        expect(
          () => BrickArguments.from([arg]),
          throwsA(isA<ArgumentError>()),
        );
      }
    });
  });
}
