import 'package:brick_oven/utils/di.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

import 'package:brick_oven/src/runner.dart';
import 'package:brick_oven/utils/extensions/logger_extensions.dart';
import '../../test_utils/mocks.dart';

/// [brickName] will be used for
/// - Accessing fixture files
///   - test/integration/fixtures/[brickName]
/// - Accessing source files
///   - test/integration/sources/[brickName]
/// - Accessing running command
///   - brick_oven cook [brickName]
///
/// WARNING: it is expected to only have 1 brick configured within the brick_oven.yaml
Future<void> cook({
  required String brickName,
  required String command,
  required int numberOfFiles,
}) async {
  final mockProgress = MockProgress();
  setupDi();

  di
    ..registerLazySingleton<Logger>(MockLogger.new)
    ..registerLazySingleton<FileSystem>(MemoryFileSystem.new)
    ..registerLazySingleton<PubUpdater>(MockPubUpdater.new);

  when(() => di<Logger>().progress(any())).thenReturn(mockProgress);

  final testPath = join('test', 'e2e');
  final fixturePath = join(testPath, 'fixtures');
  final sourcePath = join(testPath, 'sources');

  const localFileSystem = LocalFileSystem();

  final brickFixturePath = join(fixturePath, brickName);
  final brickSourcePath = join(sourcePath, brickName);

  final source = localFileSystem.directory(brickSourcePath);

  final files =
      source.listSync(recursive: true, followLinks: false).whereType<File>();

  for (final file in files) {
    final relativePath = relative(file.path, from: brickSourcePath);

    final memoryFile = di<FileSystem>().file(relativePath)
      ..createSync(recursive: true);
    try {
      memoryFile.writeAsStringSync(file.readAsStringSync());
    } catch (_) {
      memoryFile.writeAsBytesSync(file.readAsBytesSync());
    }
  }

  final brickYamlContent = localFileSystem
      .file(join(brickFixturePath, 'brick.yaml'))
      .readAsStringSync();

  di<FileSystem>().file(join('brick.yaml')).writeAsStringSync(brickYamlContent);

  final brickOven = BrickOvenRunner();

  final result = await brickOven.run(['cook', command]);

  verifyInOrder([
    di<Logger>().preheat,
    () => di<Logger>().progress('Writing Brick: $brickName'),
    () => mockProgress.complete(
          '$brickName: cooked $numberOfFiles file${numberOfFiles > 1 ? 's' : ''}',
        ),
    () => di<Logger>().info('brick.yaml is in sync'),
    di<Logger>().dingDing,
    () => di<PubUpdater>().getLatestVersion(any()),
  ]);

  expect(result, ExitCode.success.code);

  final brickFixtureFiles = localFileSystem
      .directory(join(brickFixturePath, '__brick__'))
      .listSync(recursive: true)
      .whereType<File>();

  final brickResultPath = join('bricks', brickName, '__brick__');

  for (final file in brickFixtureFiles) {
    final relativePath = relative(
      file.path,
      from: join(brickFixturePath, '__brick__'),
    );
    final expectedFile =
        di<FileSystem>().file(join(brickResultPath, relativePath));

    expect(expectedFile.existsSync(), isTrue);

    dynamic content;
    dynamic expected;
    try {
      content = expectedFile.readAsStringSync();
      expected = file.readAsStringSync();
    } catch (_) {
      content = expectedFile.readAsBytesSync();
      expected = file.readAsBytesSync();
    }

    expect(content, expected);
  }

  verifyNoMoreInteractions(di<Logger>());
  verifyNoMoreInteractions(mockProgress);
  verifyNoMoreInteractions(di<PubUpdater>());
}
