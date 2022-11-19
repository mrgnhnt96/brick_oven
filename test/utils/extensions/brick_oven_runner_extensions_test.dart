// ignore_for_file: cascade_invocations

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/brick_oven_runner_extensions.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import '../../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;
  late BrickOvenRunner brickOvenRunner;
  late PubUpdater mockPubUpdater;
  late Analytics mockAnalytics;

  const versionMessage = '''

Update available! CURRENT_VERSION → NEW_VERSION
Changelog: https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-vNEW_VERSION
Run `brick_oven update` to update
''';

  setUp(() {
    mockLogger = MockLogger();
    mockPubUpdater = MockPubUpdater();
    mockAnalytics = MockAnalytics();

    when(() => mockAnalytics.firstRun).thenReturn(false);

    brickOvenRunner = BrickOvenRunner(
      logger: mockLogger,
      pubUpdater: mockPubUpdater,
      analytics: mockAnalytics,
      fileSystem: MemoryFileSystem(),
    );
  });

  group('BrickOvenRunnerX', () {
    test('#update is correct value', () {
      expect(BrickOvenRunnerX.update, versionMessage);
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

      await brickOvenRunner.checkForUpdates(
        logger: mockLogger,
        updater: mockPubUpdater,
      );

      verify(
        () => mockLogger.info(
          BrickOvenRunnerX.formatUpdate(packageVersion, '0.0.0'),
        ),
      ).called(1);

      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockPubUpdater);
      verifyNoMoreInteractions(mockAnalytics);
    });

    test('does nothing when tool is up to date', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      await brickOvenRunner.checkForUpdates(
        logger: mockLogger,
        updater: mockPubUpdater,
      );

      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockPubUpdater);
      verifyNoMoreInteractions(mockAnalytics);
    });

    test('handles pub update errors gracefully', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      expect(
        () => brickOvenRunner.checkForUpdates(
          logger: mockLogger,
          updater: mockPubUpdater,
        ),
        returnsNormally,
      );

      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockPubUpdater);
      verifyNoMoreInteractions(mockAnalytics);
    });
  });
}
