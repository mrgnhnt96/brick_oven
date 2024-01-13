import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../test_utils/di.dart';
import '../test_utils/print_override.dart';

const expectedUsage = '''
Generate your bricks 🧱 with this oven 🎛

Usage: brick_oven <command> [arguments]

Global options:
-h, --help       Print this usage information.
    --version    Print the current version

Available commands:
  cook     Cook 👨‍🍳 bricks from the config file
  list     Lists all configured bricks from brick_oven.yaml
  update   Updates brick_oven to the latest version

Run "brick_oven help <command>" for more information about a command.''';

void main() {
  setUp(setupTestDi);

  group('$BrickOvenRunner', () {
    late BrickOvenRunner commandRunner;

    setUp(() {
      printLogs = [];

      di<FileSystem>().file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      commandRunner = BrickOvenRunner();
    });

    group('run', () {
      test('handles $FormatException', () async {
        const exception = FormatException('oops!');

        final commandRunner = TestBrickOvenRunner(
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => di<Logger>().err(exception.message)).called(1);
        verify(() => di<Logger>().info('\n${commandRunner.usage}')).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(di<PubUpdater>());
      });

      test('handles $UsageException', () async {
        final exception = UsageException('oops!', 'usage');

        final commandRunner = TestBrickOvenRunner(
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => di<Logger>().err(exception.message)).called(1);
        verify(() => di<Logger>().info('\n${commandRunner.usage}')).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(di<PubUpdater>());
      });

      test('handles other exceptions', () async {
        final exception = Exception('oops!');

        final commandRunner = TestBrickOvenRunner(
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.software.code);

        verify(() => di<Logger>().err('$exception')).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(di<PubUpdater>());
      });

      test('handles no command', () async {
        await overridePrint(() async {
          final result = await commandRunner.run([]);

          expect(printLogs.length, equals(1));
          expect(printLogs.first, expectedUsage);
          expect(result, equals(ExitCode.success.code));

          verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);
        });
      });

      group('help', () {
        test(
          '--help outputs usage',
          () async {
            await overridePrint(() async {
              final result = await commandRunner.run(['--help']);

              expect(printLogs, [expectedUsage]);
              expect(result, ExitCode.success.code);

              verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

              verifyNoMoreInteractions(di<Logger>());
              verifyNoMoreInteractions(di<PubUpdater>());
            });
          },
        );

        test(
          '-h outputs usage',
          () {
            overridePrint(() async {
              final resultAbbr = await commandRunner.run(['-h']);

              expect(printLogs, [expectedUsage]);
              expect(resultAbbr, ExitCode.success.code);

              verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

              verifyNoMoreInteractions(di<Logger>());
              verifyNoMoreInteractions(di<PubUpdater>());
            });
          },
        );
      });

      test('--version outputs current version', () async {
        final result = await commandRunner.run(['--version']);

        expect(result, ExitCode.success.code);
        verify(() => di<Logger>().alert(packageVersion)).called(1);

        verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

        verifyNoMoreInteractions(di<Logger>());
        verifyNoMoreInteractions(di<PubUpdater>());
      });

      group('#checkForUpdates', () {
        test('when version command is provided', () async {
          await commandRunner.run(['--version']);

          verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);
          verify(() => di<Logger>().alert(packageVersion)).called(1);

          verifyNoMoreInteractions(di<Logger>());
          verifyNoMoreInteractions(di<PubUpdater>());
        });

        test('when other command is provided', () async {
          await overridePrint(() async {
            await commandRunner.run(['cook', '--help']);
          });

          verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

          verifyNoMoreInteractions(di<Logger>());
          verifyNoMoreInteractions(di<PubUpdater>());
        });
      });
    });
  });
}

class TestBrickOvenRunner extends BrickOvenRunner {
  TestBrickOvenRunner({
    required this.onRun,
  });

  final void Function() onRun;

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    onRun();

    return 0;
  }
}
