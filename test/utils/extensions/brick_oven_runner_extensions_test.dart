// ignore_for_file: cascade_invocations

import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:brick_oven/utils/extensions/brick_oven_runner_extensions.dart';
import '../../test_utils/di.dart';

void main() {
  late BrickOvenRunner brickOvenRunner;

  const versionMessage = '''

Update available! CURRENT_VERSION → NEW_VERSION
Changelog: https://github.com/mrgnhnt96/brick_oven/releases/tag/brick_oven-vNEW_VERSION
Run `brick_oven update` to update
''';

  setUp(() {
    setupTestDi();

    brickOvenRunner = BrickOvenRunner();
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
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value('0.0.0'));

      await brickOvenRunner.checkForUpdates();

      verify(
        () => di<Logger>().info(
          BrickOvenRunnerX.formatUpdate(packageVersion, '0.0.0'),
        ),
      ).called(1);

      verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('does nothing when tool is up to date', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      await brickOvenRunner.checkForUpdates();

      verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('handles pub update errors gracefully', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      expect(
        () => brickOvenRunner.checkForUpdates(),
        returnsNormally,
      );

      verify(() => di<PubUpdater>().getLatestVersion(any())).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(di<PubUpdater>());
    });
  });
}
