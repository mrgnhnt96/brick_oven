import 'package:brick_oven/utils/dependency_injection.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

import 'mocks.dart';

void setupTestDi() {
  setupDi();

  di
    ..registerLazySingleton<Logger>(MockLogger.new)
    ..registerLazySingleton<FileSystem>(MemoryFileSystem.new)
    ..registerLazySingleton<PubUpdater>(MockPubUpdater.new);
}
