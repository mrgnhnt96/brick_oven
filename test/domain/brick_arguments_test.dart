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
