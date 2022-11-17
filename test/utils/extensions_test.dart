// ignore_for_file: cascade_invocations

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import 'package:brick_oven/utils/extensions.dart';

import '../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  group('LoggerX', () {
    group('#preheat', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.preheat();

        verify(() => mockLogger.info('\n🔥  Preheating...')).called(1);
      });
    });

    group('#configChanged', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.configChanged();

        verify(() => mockLogger.info('\n🔧  Configuration changed')).called(1);
      });
    });

    group('#fileChanged', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.fileChanged('brick');

        verify(
          () => mockLogger.info('\n📁  File changed (brick)'),
        ).called(1);
      });
    });

    group('#watching', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.watching();

        verify(
          () => mockLogger.info('\n👀 Watching config & source files...'),
        ).called(1);
      });
    });

    group('#dingDing', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        final date = DateTime(2021, 1, 1, 12);
        mockLogger.dingDing(date);

        verify(
          () => mockLogger.info('🔔  Ding Ding! (${date.formatted})'),
        ).called(1);
      });
    });

    group('#keyStrokes', () {
      test('calls info', () {
        verifyNever(() => mockLogger.info(any()));

        mockLogger.keyStrokes();

        verify(
          () => mockLogger.info('Press q to quit...'),
        ).called(1);

        verify(
          () => mockLogger.info('Press r to reload...'),
        ).called(1);
      });
    });
  });

  group('AnalyticsX', () {
    test('#formatAsk is equal to ask', () {
      expect(AnalyticsX.formatAsk(), AnalyticsX.ask);
    });

    test('#ask is formatted correctly', () {
      const expected = '''
+---------------------------------------------------+
|           Welcome to the Brick Oven!              |
+---------------------------------------------------+
| We would like to collect anonymous                |
| usage statistics in order to improve the tool.    |
| Would you like to opt-into help us improve? [y/n] |
+---------------------------------------------------+\n''';

      expect(AnalyticsX.ask, expected);
    });

    group('#askForConsent', () {
      test('handles accept response', () async {
        final mockAnalytics = MockAnalytics();

        when(() => mockAnalytics.firstRun).thenReturn(true);

        when(
          () => mockLogger.chooseOne(
            any<String>(),
            choices: any<List<String>>(named: 'choices'),
            defaultValue: any<String>(named: 'defaultValue'),
          ),
        ).thenReturn(AnalyticsX.yes);

        mockAnalytics.askForConsent(mockLogger);

        verify(() => mockAnalytics.enabled = true).called(1);
      });

      test('handles reject response', () {
        final mockAnalytics = MockAnalytics();

        when(() => mockAnalytics.firstRun).thenReturn(true);

        when(
          () => mockLogger.chooseOne(
            any<String>(),
            choices: any<List<String>>(named: 'choices'),
            defaultValue: any<String>(named: 'defaultValue'),
          ),
        ).thenReturn(AnalyticsX.no);

        mockAnalytics.askForConsent(mockLogger);

        verify(() => mockAnalytics.enabled = false).called(1);
      });
    });
  });

  group('BrickOvenRunnerX', () {
    late PubUpdater mockPubUpdater;

    setUp(() {
      mockPubUpdater = MockPubUpdater();
    });
    test('#update is correct value', () {
      const expected = '''

Update available! CURRENT_VERSION → NEW_VERSION
Changelog: https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-vNEW_VERSION
Run `brick_oven update` to update
''';

      expect(BrickOvenRunnerX.update, expected);
    });

    test('#formatUpdate is same as update', () {
      expect(
        BrickOvenRunnerX.formatUpdate('CURRENT_VERSION', 'NEW_VERSION'),
        BrickOvenRunnerX.update,
      );
    });

    test('prompts for update when newer version exists', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value('0.0.0'));

      final runner = BrickOvenRunner(logger: MockLogger());

      await runner.checkForUpdates(
        logger: mockLogger,
        updater: mockPubUpdater,
      );

      verify(
        () => mockLogger.info(
          BrickOvenRunnerX.formatUpdate(packageVersion, '0.0.0'),
        ),
      ).called(1);
    });

    test('does nothing when tool is up to date', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      final runner = BrickOvenRunner(logger: MockLogger());

      await runner.checkForUpdates(
        logger: mockLogger,
        updater: mockPubUpdater,
      );

      verifyNever(() => mockLogger.info(any()));
    });

    test('handles pub update errors gracefully', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      final runner = BrickOvenRunner(logger: MockLogger());

      expect(
        () => runner.checkForUpdates(
          logger: mockLogger,
          updater: mockPubUpdater,
        ),
        returnsNormally,
      );
    });
  });
}
