import 'dart:io';

import 'package:file/file.dart' as file;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:watcher/watcher.dart';

import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/src/key_press_listener.dart';
import 'package:brick_oven/src/version.dart';

class MockKeyPressListener extends Mock implements KeyPressListener {}

class MockLogger extends Mock implements Logger {}

class MockPubUpdater extends Mock implements PubUpdater {}

class MockSourceWatcher extends Mock implements SourceWatcher {}

class MockProgress extends Mock implements Progress {}

class MockFileWatcher extends Mock implements FileWatcher {}

class MockStdout extends Mock implements Stdout {}

class MockStdin extends Mock implements Stdin {}

class MockFile extends Mock implements file.File {}

class MockDirectoryWatcher extends Mock implements DirectoryWatcher {}

extension PubUpdaterX on MockPubUpdater {
  void stubMethods() {
    when(() => getLatestVersion(any()))
        .thenAnswer((_) => Future.value(packageVersion));
  }
}
