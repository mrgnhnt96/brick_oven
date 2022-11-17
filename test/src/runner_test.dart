import 'package:args/command_runner.dart';
import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
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
    late Logger mockLogger;
    late PubUpdater mockPubUpdater;
    late BrickOvenRunner commandRunner;
    late FileSystem fs;

    setUp(() {
      printLogs = [];
      mockLogger = MockLogger();
      mockPubUpdater = MockPubUpdater();
      fs = MemoryFileSystem();

      fs.file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      commandRunner = BrickOvenRunner(
        logger: mockLogger,
        pubUpdater: mockPubUpdater,
        fileSystem: fs,
      );
    });

    test('can be instantiated without an explicit pub updater instance', () {
      final commandRunner = BrickOvenRunner(
        fileSystem: fs,
        logger: MockLogger(),
      );
      expect(commandRunner, isNotNull);
    });

    test('time out is correct duration', () {
      expect(BrickOvenRunner.timeout, const Duration(milliseconds: 500));
    });

    group('run', () {
      group('analytics', () {
        test('can be enabled', () async {
          final analytics = MockAnalytics();

          when(() => analytics.firstRun).thenReturn(false);

          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: analytics,
          );

          final result = await commandRunner.run(['--analytics', 'true']);

          verify(() => analytics.enabled = true).called(1);

          verify(() => mockLogger.info('analytics enabled.')).called(1);

          expect(result, ExitCode.success.code);
        });

        test('can be disabled', () async {
          final analytics = MockAnalytics();

          when(() => analytics.firstRun).thenReturn(false);

          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: analytics,
          );

          final result = await commandRunner.run(['--analytics', 'false']);

          verify(() => analytics.enabled = false).called(1);

          verify(() => mockLogger.info('analytics disabled.')).called(1);

          expect(result, ExitCode.success.code);
        });

        test('asks for consent when first time running', () async {
          final analytics = MockAnalytics();

          when(() => analytics.firstRun).thenReturn(true);

          commandRunner = BrickOvenRunner(
            logger: mockLogger,
            pubUpdater: mockPubUpdater,
            fileSystem: fs,
            analytics: analytics,
          );

          await commandRunner.run([]);

          verify(() => analytics.askForConsent(mockLogger)).called(1);

          verify(
            () => mockLogger.chooseOne(
              AnalyticsX.formatAsk(),
              choices: [AnalyticsX.yes, AnalyticsX.no],
              defaultValue: AnalyticsX.yes,
            ),
          ).called(1);
        });
      });

      test('handles $FormatException', () async {
        const exception = FormatException('oops!');
        var isFirstInvocation = true;

        when(() => mockLogger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.usage.code));

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info(commandRunner.usage)).called(1);
      });

      test('handles $UsageException', () async {
        final exception = UsageException('oops!', commandRunner.usage);
        var isFirstInvocation = true;

        when(() => mockLogger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.usage.code));

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info(commandRunner.usage)).called(1);
      });

      test('handles other exceptions', () async {
        final exception = Exception('oops!');
        var isFirstInvocation = true;

        when(() => mockLogger.alert(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });

        final result = await commandRunner.run(['--version']);

        expect(result, equals(ExitCode.software.code));

        verify(() => mockLogger.err('$exception')).called(1);
      });

      test(
        'handles no command',
        () => overridePrint(() async {
          final result = await commandRunner.run([]);

          expect(printLogs, equals([expectedUsage.join()]));
          expect(result, equals(ExitCode.success.code));
        }),
      );

      group('help', () {
        test(
          '--help outputs usage',
          () async {
            await overridePrint(() async {
              final result = await commandRunner.run(['--help']);

              expect(printLogs, equals([expectedUsage.join()]));
              expect(result, equals(ExitCode.success.code));
            });
          },
        );

        test(
          '-h outputs usage',
          () {
            overridePrint(() async {
              final resultAbbr = await commandRunner.run(['-h']);

              expect(printLogs, equals([expectedUsage.join()]));
              expect(resultAbbr, equals(ExitCode.success.code));
            });
          },
        );
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);

          expect(result, equals(ExitCode.success.code));
          verify(() => mockLogger.alert(packageVersion)).called(1);
        });
      });
    });
  });
}
