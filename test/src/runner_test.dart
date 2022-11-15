import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';

const expectedUsage = [
  'Generate your bricks 🧱 with this oven 🎛\n',
  '\n',
  'Usage: brick_oven <command> [arguments]\n',
  '\n',
  'Global options:\n',
  '-h, --help       Print this usage information.\n',
  '    --version    Print the current version\n',
  '\n',
  'Available commands:\n',
  '  cook     Cook 👨‍🍳 bricks from the config file\n',
  '  list     Lists all configured bricks from brick_oven.yaml\n',
  '  update   Updates brick_oven to the latest version\n',
  '\n',
  'Run "brick_oven help <command>" for more information about a command.',
];

const latestVersion = '0.0.0';

const updateMessage = '''

+------------------------------------------------------------------------------------+
|                                                                                    |
|                   Update available! $packageVersion \u2192 $latestVersion                                  |
|  Changelog: https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-v$latestVersion |
|                             Run brick_oven update to update                        |
|                                                                                    |
+------------------------------------------------------------------------------------+
''';

void main() {
  group('$BrickOvenRunner', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late BrickOvenRunner commandRunner;
    late FileSystem fs;

    setUp(() {
      printLogs = [];
      logger = MockLogger();
      pubUpdater = MockPubUpdater();
      fs = MemoryFileSystem();

      fs.file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = BrickOvenRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        fileSystem: fs,
      );
    });

    test(
      'can be instantiated without an explicit pub updater instance',
      () {
        final commandRunner = BrickOvenRunner(
          fileSystem: fs,
          logger: MockLogger(),
        );
        expect(commandRunner, isNotNull);
      },
    );

    group('run', () {
      test('prompts for update when newer version exists', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenAnswer((_) async => latestVersion);

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.success.code));

        verify(() => logger.info(updateMessage)).called(1);
      });

      test('handles pub update errors gracefully', () async {
        when(
          () => pubUpdater.getLatestVersion(any()),
        ).thenThrow(Exception('oops'));

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.success.code));

        verifyNever(() => logger.info(updateMessage));
      });

      test('handles $FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;

        when(() => logger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.usage.code));

        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info(commandRunner.usage)).called(1);
      });

      test('handles $UsageException', () async {
        final exception = UsageException('oops!', commandRunner.usage);
        var isFirstInvocation = true;

        when(() => logger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.usage.code));

        verify(() => logger.err(exception.message)).called(1);
        verify(() => logger.info(commandRunner.usage)).called(1);
      });

      test('handles other exceptions', () async {
        final exception = Exception('oops!');
        var isFirstInvocation = true;

        when(() => logger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.software.code));

        verify(() => logger.err('$exception')).called(1);
      });

      test(
        'handles no command',
        overridePrint(() async {
          final result = await commandRunner.run([]);

          expect(printLogs, equals([expectedUsage.join()]));
          expect(result, equals(ExitCode.success.code));
        }),
      );

      group('help', () {
        test(
          '--help outputs usage',
          overridePrint(() async {
            final result = await commandRunner.run(['--help']);

            expect(printLogs, equals([expectedUsage.join()]));
            expect(result, equals(ExitCode.success.code));
          }),
        );

        test(
          '-h outputs usage',
          overridePrint(() async {
            final resultAbbr = await commandRunner.run(['-h']);

            expect(printLogs, equals([expectedUsage.join()]));
            expect(resultAbbr, equals(ExitCode.success.code));
          }),
        );
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);

          expect(result, equals(ExitCode.success.code));
          verify(() => logger.alert(packageVersion)).called(1);
        });
      });
    });
  });
}
