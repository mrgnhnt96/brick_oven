import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/analytics_extensions.dart';
import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';

const expectedUsage = '''
Generate your bricks 🧱 with this oven 🎛

Usage: brick_oven <command> [arguments]

Global options:
-h, --help           Print this usage information.
    --version        Print the current version
    --analytics      Toggle anonymous usage statistics.

          [false]    Disable anonymous usage statistics
          [true]     Enable anonymous usage statistics

Available commands:
  cook     Cook 👨‍🍳 bricks from the config file
  list     Lists all configured bricks from brick_oven.yaml
  update   Updates brick_oven to the latest version

Run "brick_oven help <command>" for more information about a command.''';

void main() {
  group('$BrickOvenRunner', () {
    late Logger mockLogger;
    late PubUpdater mockPubUpdater;
    late Analytics mockAnalytics;
    late BrickOvenRunner commandRunner;
    late FileSystem fs;

    setUp(() {
      printLogs = [];

      mockLogger = MockLogger();
      mockPubUpdater = MockPubUpdater();
      mockAnalytics = MockAnalytics()..stubMethods();
      fs = MemoryFileSystem();

      fs.file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(() => mockAnalytics.firstRun).thenReturn(false);

      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      commandRunner = BrickOvenRunner(
        logger: mockLogger,
        pubUpdater: mockPubUpdater,
        fileSystem: fs,
        analytics: mockAnalytics,
      );
    });

    test('time out is correct duration', () {
      expect(BrickOvenRunner.timeout, const Duration(milliseconds: 500));
    });

    group('run', () {
      group('analytics', () {
        test('can be enabled', () async {
          final result = await commandRunner.run(['--analytics', 'true']);

          verify(() => mockAnalytics.enabled = true).called(1);
          verify(() => mockLogger.info('analytics enabled.')).called(1);
          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

          expect(result, ExitCode.success.code);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });

        test('can be disabled', () async {
          final result = await commandRunner.run(['--analytics', 'false']);

          verify(() => mockAnalytics.enabled = false).called(1);

          verify(() => mockLogger.info('analytics disabled.')).called(1);
          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

          expect(result, ExitCode.success.code);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });

        test('asks for consent when first time running', () async {
          when(() => mockAnalytics.firstRun).thenReturn(true);
          when(
            () => mockLogger.chooseOne(
              any(),
              choices: any<List<String>>(named: 'choices'),
              defaultValue: any<String>(named: 'defaultValue'),
            ),
          ).thenAnswer((_) => AnalyticsX.yes);

          await overridePrint(() async {
            await commandRunner.run([]);
          });

          verify(() => mockAnalytics.askForConsent(mockLogger)).called(1);
          verify(() => mockAnalytics.enabled = true).called(1);
          verify(
            () => mockLogger.chooseOne(
              AnalyticsX.formatAsk(),
              choices: [AnalyticsX.yes, AnalyticsX.no],
              defaultValue: AnalyticsX.yes,
            ),
          ).called(1);

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });
      });

      test('handles $FormatException', () async {
        const exception = FormatException('oops!');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          pubUpdater: mockPubUpdater,
          analytics: mockAnalytics,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info('\n${commandRunner.usage}')).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockPubUpdater);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('handles $UsageException', () async {
        final exception = UsageException('oops!', 'usage');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          pubUpdater: mockPubUpdater,
          analytics: mockAnalytics,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.usage.code);

        verify(() => mockLogger.err(exception.message)).called(1);
        verify(() => mockLogger.info('\n${commandRunner.usage}')).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockPubUpdater);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('handles other exceptions', () async {
        final exception = Exception('oops!');

        final commandRunner = TestBrickOvenRunner(
          logger: mockLogger,
          fileSystem: fs,
          pubUpdater: mockPubUpdater,
          analytics: mockAnalytics,
          onRun: () {
            throw exception;
          },
        );

        final result = await commandRunner.run([]);

        expect(result, ExitCode.software.code);

        verify(() => mockLogger.err('$exception')).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockPubUpdater);
        verifyNoMoreInteractions(mockAnalytics);
      });

      test('handles no command', () async {
        await overridePrint(() async {
          final result = await commandRunner.run([]);

          expect(printLogs, equals([expectedUsage]));
          expect(result, equals(ExitCode.success.code));

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
          verify(() => mockAnalytics.firstRun).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
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

              verify(() => mockPubUpdater.getLatestVersion(packageName))
                  .called(1);
              verify(() => mockAnalytics.firstRun).called(1);

              verifyNoMoreInteractions(mockLogger);
              verifyNoMoreInteractions(mockPubUpdater);
              verifyNoMoreInteractions(mockAnalytics);
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

              verify(() => mockPubUpdater.getLatestVersion(packageName))
                  .called(1);
              verify(() => mockAnalytics.firstRun).called(1);

              verifyNoMoreInteractions(mockLogger);
              verifyNoMoreInteractions(mockPubUpdater);
              verifyNoMoreInteractions(mockAnalytics);
            });
          },
        );
      });

      test('--version outputs current version', () async {
        final result = await commandRunner.run(['--version']);

        expect(result, ExitCode.success.code);
        verify(() => mockLogger.alert(packageVersion)).called(1);

        verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
        verify(() => mockAnalytics.firstRun).called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockPubUpdater);
        verifyNoMoreInteractions(mockAnalytics);
      });

      group('#checkForUpdates', () {
        test('when analytics command is provided with true', () async {
          await commandRunner.run(['--analytics', 'true']);

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
          verify(() => mockLogger.info('analytics enabled.')).called(1);
          verify(() => mockAnalytics.enabled = true).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });

        test('when analytics command is provided with false', () async {
          await commandRunner.run(['--analytics', 'false']);

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
          verify(() => mockLogger.info('analytics disabled.')).called(1);
          verify(() => mockAnalytics.enabled = false).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });

        test('when version command is provided', () async {
          await commandRunner.run(['--version']);

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
          verify(() => mockLogger.alert(packageVersion)).called(1);
          verify(() => mockAnalytics.firstRun).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });

        test('when other command is provided', () async {
          await overridePrint(() async {
            await commandRunner.run(['cook', '--help']);
          });

          verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
          verify(() => mockAnalytics.firstRun).called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockPubUpdater);
          verifyNoMoreInteractions(mockAnalytics);
        });
      });
    });
  });
}

class TestBrickOvenRunner extends BrickOvenRunner {
  TestBrickOvenRunner({
    required super.logger,
    required super.fileSystem,
    required this.onRun,
    required super.pubUpdater,
    required super.analytics,
  });

  final void Function() onRun;

  @override
  Future<int> runCommand(ArgResults topLevelResults) async {
    onRun();

    return 0;
  }
}
