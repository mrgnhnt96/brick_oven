import 'package:brick_oven/src/version.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/src/commands/update.dart';
import 'package:brick_oven/src/runner.dart';
import '../../test_utils/fakes.dart';
import '../../test_utils/mocks.dart';

class FakeProcessResult extends Fake implements ProcessResult {}

void main() {
  const latestVersion = '0.0.0';
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  group('$UpdateCommand', () {
    test('description displays correctly', () {
      expect(
        UpdateCommand(logger: mockLogger).description,
        'Updates brick_oven to the latest version',
      );
    });

    test('name displays correctly', () {
      expect(UpdateCommand(logger: mockLogger).name, 'update');
      expect(UpdateCommand.commandName, 'update');
    });
  });

  group('brick_oven update', () {
    late Logger logger;
    late PubUpdater pubUpdater;
    late BrickOvenRunner commandRunner;
    late Progress mockProgress;

    setUp(() {
      logger = MockLogger();
      pubUpdater = MockPubUpdater();
      mockProgress = MockProgress();

      final fs = MemoryFileSystem();

      fs.file(BrickOvenYaml.file)
        ..createSync(recursive: true)
        ..writeAsStringSync('bricks:');

      when(() => mockProgress.complete(any())).thenReturn(voidCallback());
      when(() => mockProgress.fail(any())).thenReturn(voidCallback());
      when(() => mockProgress.update(any())).thenReturn(voidCallback());

      when(() => logger.progress(any())).thenReturn(mockProgress);
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      when(
        () => pubUpdater.update(packageName: packageName),
      ).thenAnswer((_) => Future.value(FakeProcessResult()));

      commandRunner = BrickOvenRunner(
        logger: logger,
        pubUpdater: pubUpdater,
        fileSystem: fs,
      );
    });

    test('handles pub latest version query errors', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenThrow(Exception('oops'));

      final result = await commandRunner.run(['update']);

      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to get latest version'));
      verifyNever(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      );
    });

    test('handles pub update errors', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      when(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      ).thenThrow(Exception('oops'));

      final result = await commandRunner.run(['update']);

      expect(result, equals(ExitCode.software.code));

      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.fail('Failed to update brick_oven'));
      verify(
        () => pubUpdater.update(packageName: any(named: 'packageName')),
      ).called(1);
    });

    test('updates when newer version exists', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => latestVersion);

      when(() => logger.progress(any())).thenReturn(mockProgress);

      final result = await commandRunner.run(['update']);

      expect(result, equals(ExitCode.success.code));

      verify(() => logger.progress('Checking for updates')).called(1);
      verify(() => mockProgress.update('Successfully checked for updates'))
          .called(1);
      verify(() => mockProgress.update('Updating to $latestVersion')).called(1);
      verify(() => pubUpdater.update(packageName: packageName)).called(1);
      verify(
        () => mockProgress.complete(
          'Successfully updated brick_oven to $latestVersion',
        ),
      ).called(1);
    });

    test('does not update when already on latest version', () async {
      when(
        () => pubUpdater.getLatestVersion(any()),
      ).thenAnswer((_) async => packageVersion);

      when(() => logger.progress(any())).thenReturn(mockProgress);

      final result = await commandRunner.run(['update']);

      expect(result, equals(ExitCode.success.code));

      verify(
        () => mockProgress
            .complete('brick_oven is already at the latest version.'),
      ).called(1);
      verifyNever(() => logger.progress('Updating to $latestVersion'));
      verifyNever(() => pubUpdater.update(packageName: packageName));
    });
  });
}
