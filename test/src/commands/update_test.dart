import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/dependency_injection.dart';
import '../../test_utils/di.dart';
import '../../test_utils/mocks.dart';

void main() {
  const latestVersion = '0.0.0';
  late Progress mockProgress;
  late UpdateCommand updateCommand;

  setUp(() {
    setupTestDi();

    mockProgress = MockProgress();

    when(() => di<Logger>().progress(any())).thenReturn(mockProgress);

    updateCommand = UpdateCommand();
  });

  group('$UpdateCommand', () {
    test('description displays correctly', () {
      expect(
        updateCommand.description,
        'Updates brick_oven to the latest version',
      );

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('name displays correctly', () {
      expect(updateCommand.name, 'update');
      expect(UpdateCommand.commandName, 'update');

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });
  });

  group('package update', () {
    test('handles pub latest version query errors', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      final result = await updateCommand.run();

      expect(result, ExitCode.software.code);

      verify(() => di<Logger>().progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to get latest version'));
      verify(() => di<PubUpdater>().getLatestVersion('brick_oven')).called(1);
      verifyNever(
        () => di<PubUpdater>().update(
          packageName: any(named: 'packageName'),
        ),
      );

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('handles pub update errors', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(latestVersion));

      when(
        () => di<PubUpdater>().update(packageName: any(named: 'packageName')),
      ).thenThrow(Exception('oops'));

      final result = await updateCommand.run();

      expect(result, equals(ExitCode.software.code));

      verify(() => di<Logger>().progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to update brick_oven'));
      verify(() => di<PubUpdater>().getLatestVersion('brick_oven')).called(1);
      verify(
        () => di<PubUpdater>().update(packageName: 'brick_oven'),
      ).called(1);

      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(() => mockProgress.update('Updating to $latestVersion')).called(1);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('updates when newer version exists', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(latestVersion));

      when(
        () => di<PubUpdater>().update(packageName: any(named: 'packageName')),
      ).thenAnswer((_) => Future.value(ProcessResult(0, 0, '', '')));

      final result = await updateCommand.run();

      verify(() => di<Logger>().progress('Checking for updates')).called(1);
      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(() => mockProgress.update('Updating to $latestVersion')).called(1);
      verify(() => di<PubUpdater>().getLatestVersion('brick_oven')).called(1);
      verify(() => di<PubUpdater>().update(packageName: 'brick_oven'))
          .called(1);
      verify(
        () => mockProgress.complete(
          'Successfully updated brick_oven to $latestVersion',
        ),
      ).called(1);

      expect(result, equals(ExitCode.success.code));

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });

    test('does not update when already on latest version', () async {
      when(
        () => di<PubUpdater>().getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      final result = await updateCommand.run();

      verify(() => di<Logger>().progress('Checking for updates')).called(1);
      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(
        () => mockProgress
            .complete('brick_oven is already at the latest version.'),
      ).called(1);
      verify(() => di<PubUpdater>().getLatestVersion('brick_oven')).called(1);
      verifyNever(() => di<Logger>().progress('Updating to $latestVersion'));
      verifyNever(() => di<PubUpdater>().update(packageName: 'brick_oven'));

      expect(result, ExitCode.success.code);

      verifyNoMoreInteractions(di<Logger>());
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(di<PubUpdater>());
    });
  });
}
