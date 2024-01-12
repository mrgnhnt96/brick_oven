import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import '../../test_utils/mocks.dart';

void main() {
  const latestVersion = '0.0.0';
  late Logger mockLogger;
  late Progress mockProgress;
  late PubUpdater mockPubUpdater;
  late UpdateCommand updateCommand;

  setUp(() {
    mockLogger = MockLogger();
    mockProgress = MockProgress();
    mockPubUpdater = MockPubUpdater();

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    updateCommand = UpdateCommand(
      logger: mockLogger,
      pubUpdater: mockPubUpdater,
    );
  });

  group('$UpdateCommand', () {
    test('description displays correctly', () {
      expect(
        updateCommand.description,
        'Updates $packageName to the latest version',
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('name displays correctly', () {
      expect(updateCommand.name, 'update');
      expect(UpdateCommand.commandName, 'update');

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });
  });

  group('$packageName update', () {
    test('handles pub latest version query errors', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      final result = await updateCommand.run();

      expect(result, ExitCode.software.code);

      verify(() => mockLogger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to get latest version'));
      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
      verifyNever(
        () => mockPubUpdater.update(
          packageName: any(named: 'packageName'),
        ),
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('handles pub update errors', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(latestVersion));

      when(
        () => mockPubUpdater.update(packageName: any(named: 'packageName')),
      ).thenThrow(Exception('oops'));

      final result = await updateCommand.run();

      expect(result, equals(ExitCode.software.code));

      verify(() => mockLogger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to update $packageName'));
      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
      verify(
        () => mockPubUpdater.update(packageName: packageName),
      ).called(1);

      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(() => mockProgress.update('Updating to $latestVersion')).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('updates when newer version exists', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(latestVersion));

      when(
        () => mockPubUpdater.update(packageName: any(named: 'packageName')),
      ).thenAnswer((_) => Future.value(ProcessResult(0, 0, '', '')));

      final result = await updateCommand.run();

      verify(() => mockLogger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(() => mockProgress.update('Updating to $latestVersion')).called(1);
      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
      verify(() => mockPubUpdater.update(packageName: packageName)).called(1);
      verify(
        () => mockProgress.complete(
          'Successfully updated $packageName to $latestVersion',
        ),
      ).called(1);

      expect(result, equals(ExitCode.success.code));

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });

    test('does not update when already on latest version', () async {
      when(
        () => mockPubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) => Future.value(packageVersion));

      final result = await updateCommand.run();

      verify(() => mockLogger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(
        () => mockProgress
            .complete('$packageName is already at the latest version.'),
      ).called(1);
      verify(() => mockPubUpdater.getLatestVersion(packageName)).called(1);
      verifyNever(() => mockLogger.progress('Updating to $latestVersion'));
      verifyNever(() => mockPubUpdater.update(packageName: packageName));

      expect(result, ExitCode.success.code);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPubUpdater);
    });
  });
}
