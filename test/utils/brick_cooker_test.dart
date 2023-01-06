import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:test/test.dart';

import 'package:brick_oven/utils/brick_cooker.dart';
import '../test_utils/fakes.dart';

void main() {
  group('$BrickCookerArgs', () {
    group('#outputDir', () {
      test('returns the output dir when provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{'output': 'output/dir'},
        );

        expect(command.outputDir, 'output/dir');
      });

      test('returns null when not provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{},
        );

        expect(command.outputDir, null);
      });
    });

    group('#isWatch', () {
      test('returns true when watch flag is provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{'watch': true},
        );

        expect(command.isWatch, true);
      });

      test('returns false when not provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{},
        );

        expect(command.isWatch, false);
      });
    });

    group('#shouldSync', () {
      test('returns true when sync flag is provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{'sync': true},
        );

        expect(command.shouldSync, true);
      });

      test('returns false when sync flag is provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{'sync': false},
        );

        expect(command.shouldSync, false);
      });

      test('returns true when not provided', () {
        final command = TestCommand(
          argResults: <String, dynamic>{},
        );

        expect(command.shouldSync, true);
      });
    });
  });
}

class TestCommand extends Command<int> with BrickCookerArgs {
  TestCommand({
    required Map<String, dynamic> argResults,
  }) : _argResults = argResults;

  final Map<String, dynamic> _argResults;

  @override
  ArgResults get argResults => FakeArgResults(data: _argResults);

  @override
  String get description => throw UnimplementedError();

  @override
  String get name => throw UnimplementedError();
}
