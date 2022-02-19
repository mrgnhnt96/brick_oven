import 'package:args/args.dart';
import 'package:brick_oven/src/commands/cook_bricks/cook_all_bricks.dart';
import 'package:test/test.dart';

import '../../../utils/fakes.dart';

void main() {
  late CookAllBricks command;

  setUp(() {
    command = CookAllBricks();
  });

  group('$CookAllBricks', () {
    test('description displays correctly', () {
      expect(command.description, 'Cook all bricks.');
    });

    test('name displays correctly', () {
      expect(command.name, 'all');
    });

    group('#isWatch', () {
      test('returns true when watch flag is provided', () {
        final command =
            TestCookAllBricks(argResults: <String, dynamic>{'watch': true});

        expect(command.isWatch, isTrue);
      });

      test('returns false when watch flag is not provided', () {
        final command =
            TestCookAllBricks(argResults: <String, dynamic>{'watch': false});

        expect(command.isWatch, isFalse);
      });
    });

    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCookAllBricks(
          argResults: <String, dynamic>{'output': 'output/dir'},
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCookAllBricks(argResults: <String, dynamic>{});

        expect(command.outputDir, 'bricks');
      });
    });
  });
}

class TestCookAllBricks extends CookAllBricks {
  TestCookAllBricks({required Map<String, dynamic> argResults})
      : _argResults = argResults;
  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);
}
