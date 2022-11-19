// ignore_for_file: cascade_invocations

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/src/version.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';
import 'package:usage/usage_io.dart';

import '../test_utils/mocks.dart';

void main() {
  final testPath = join('test', 'e2e');
  final fixturePath = join(testPath, 'fixtures');
  final sourcePath = join(testPath, 'sources');
  final bioSourcePath = join(sourcePath, 'bio');
  final bioFixturePath = join(fixturePath, 'bio');

  late Logger mockLogger;
  late Progress mockProgress;
  late PubUpdater mockPubUpdater;
  late Analytics mockAnalytics;
  late FileSystem memoryFileSystem;
  late FileSystem localFileSystem;

  setUp(() {
    mockLogger = MockLogger();
    mockProgress = MockProgress();
    mockPubUpdater = MockPubUpdater()..stubMethods();
    mockAnalytics = MockAnalytics()..stubMethods();

    when(() => mockLogger.progress(any())).thenReturn(mockProgress);

    memoryFileSystem = MemoryFileSystem();
    localFileSystem = const LocalFileSystem();
  });

  test('description', () async {
    final source = localFileSystem.directory(bioSourcePath);

    final files =
        source.listSync(recursive: true, followLinks: false).whereType<File>();

    for (final file in files) {
      final relativePath = relative(file.path, from: bioSourcePath);

      memoryFileSystem.file(relativePath)
        ..createSync(recursive: true)
        ..writeAsStringSync(file.readAsStringSync());
    }

    final brickYamlFixture = localFileSystem
        .file(join(bioFixturePath, 'brick.yaml'))
        .readAsStringSync();

    memoryFileSystem
        .file(join('brick.yaml'))
        .writeAsStringSync(brickYamlFixture);

    final brickOven = BrickOvenRunner(
      analytics: mockAnalytics,
      fileSystem: memoryFileSystem,
      logger: mockLogger,
      pubUpdater: mockPubUpdater,
    );

    final result = await brickOven.run(['cook', 'bio']);

    expect(result, ExitCode.success.code);

    final brickFixture = localFileSystem
        .directory(join(bioFixturePath, '__brick__'))
        .listSync()
        .whereType<File>();

    final brickResultPath = join('bricks', 'bio', '__brick__');

    for (final file in brickFixture) {
      final relativePath = relative(
        file.path,
        from: join(bioFixturePath, '__brick__'),
      );
      final actualFile =
          memoryFileSystem.file(join(brickResultPath, relativePath));

      expect(actualFile.existsSync(), isTrue);
      expect(actualFile.readAsStringSync(), file.readAsStringSync());
    }

    verifyInOrder([
      mockLogger.preheat,
      () => mockLogger.progress('Writing Brick: bio'),
      () => mockLogger.info('brick.yaml is in sync'),
      mockLogger.dingDing,
    ]);

    verify(() => mockProgress.complete('bio: cooked 1 file'));

    verify(() => mockPubUpdater.getLatestVersion(packageName));

    verify(() => mockAnalytics.firstRun);

    verify(
      () => mockAnalytics.sendEvent(
        'cook',
        'one',
        label: 'no-watch',
        value: 0,
        parameters: {
          'bricks': '1',
          'sync': 'true',
        },
      ),
    ).called(1);

    verify(
      () => mockAnalytics.waitForLastPing(timeout: BrickOvenRunner.timeout),
    ).called(1);

    verifyNoMoreInteractions(mockLogger);
    verifyNoMoreInteractions(mockProgress);
    verifyNoMoreInteractions(mockPubUpdater);
    verifyNoMoreInteractions(mockAnalytics);
  });
}

extension _PubUpdaterX on MockPubUpdater {
  void stubMethods() {
    when(() => getLatestVersion(any()))
        .thenAnswer((_) => Future.value(packageVersion));
  }
}
