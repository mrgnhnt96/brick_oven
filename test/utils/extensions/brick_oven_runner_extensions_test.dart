// ignore_for_file: cascade_invocations

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/brick_oven_runner_extensions.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import '../../test_utils/mocks.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
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