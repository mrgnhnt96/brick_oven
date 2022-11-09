import 'dart:async';

import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/utils/config_watcher_mixin.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

import '../test_utils/print_override.dart';
import '../test_utils/test_file_watcher.dart';

void main() {
  setUp(() {
    printLogs = [];
  });

  group('$ConfigWatcherMixin', () {
    late FileSystem fs;
    late File configFile;

    setUp(() async {
      fs = MemoryFileSystem();

      final configPath = join(fs.currentDirectory.path, BrickOvenYaml.file);

      configFile = fs.file(configPath);

      await configFile.create(recursive: true);
    });

    test('#watchForChanges should return true when file changes', () async {
      var hasChanged = false;
      final testConfigWatcher = TestConfigWatcher();
      final testFileWatcher =
          testConfigWatcher.watcher(configFile.path) as TestFileWatcher;

      final listener = testConfigWatcher.watchForConfigChanges(
        configFile.path,
        onChange: () => hasChanged = true,
      );

      configFile.writeAsStringSync('update');

      final event = WatchEvent(ChangeType.MODIFY, configFile.path);
      testFileWatcher.triggerEvent(event);

      await listener;

      expect(hasChanged, isTrue);

      testFileWatcher.close();
    });

    test('#watcher returns $FileWatcher', () {
      final testConfigWatcher = TestConfigWatcher();

      expect(
        testConfigWatcher.watcher(configFile.path, useTestWatcher: false),
        isA<FileWatcher>(),
      );
      expect(
        testConfigWatcher.watcher(configFile.path, useTestWatcher: false).path,
        configFile.path,
      );
    });

    group('#completers', () {
      test('#watchForConfigChanges adds to completers', () async {
        final testConfigWatcher = TestConfigWatcher();
        unawaited(testConfigWatcher.watchForConfigChanges(configFile.path));

        await Future<void>.delayed(Duration.zero);

        expect(testConfigWatcher.completers, isNotEmpty);
        expect(testConfigWatcher.completers, hasLength(1));
        expect(testConfigWatcher.completers.keys, [configFile.path]);
      });

      group('#cancelConfigWatchers', () {
        test('removes from completers', () async {
          final testConfigWatcher = TestConfigWatcher();

          unawaited(testConfigWatcher.watchForConfigChanges(configFile.path));

          // wait for the watcher to be added
          await Future<void>.delayed(Duration.zero);

          expect(testConfigWatcher.completers, isNotEmpty);
          expect(testConfigWatcher.completers, hasLength(1));
          expect(testConfigWatcher.completers.keys, [configFile.path]);

          await testConfigWatcher.cancelConfigWatchers(shouldQuit: false);

          expect(testConfigWatcher.completers, isEmpty);
        });

        test(
            'should return false when provided for #watchForconfigChanges return value',
            () async {
          final testConfigWatcher = TestConfigWatcher();

          final shouldQuitCompleter = Completer<bool>();

          unawaited(
            testConfigWatcher
                .watchForConfigChanges(configFile.path)
                .then(shouldQuitCompleter.complete),
          );

          // wait for the watcher to be added
          await Future<void>.delayed(Duration.zero);

          await testConfigWatcher.cancelConfigWatchers(shouldQuit: false);

          expect(await shouldQuitCompleter.future, isFalse);
        });

        test(
            'should return true when provided for #watchForconfigChanges return value',
            () async {
          final testConfigWatcher = TestConfigWatcher();

          final shouldQuitCompleter = Completer<bool>();

          unawaited(
            testConfigWatcher
                .watchForConfigChanges(configFile.path)
                .then(shouldQuitCompleter.complete),
          );

          // wait for the watcher to be added
          await Future<void>.delayed(Duration.zero);

          await testConfigWatcher.cancelConfigWatchers(shouldQuit: true);

          expect(await shouldQuitCompleter.future, isTrue);
        });
      });

      test('#watchForConfigChanges throws assertion when re-watching path',
          () async {
        final testConfigWatcher = TestConfigWatcher();

        unawaited(testConfigWatcher.watchForConfigChanges(configFile.path));

        await Future<void>.delayed(Duration.zero);

        expect(
          () => testConfigWatcher.watchForConfigChanges(configFile.path),
          throwsA(isA<AssertionError>()),
        );
      });
    });
  });
}

class TestConfigWatcher with ConfigWatcherMixin {
  final testFileWatcher = TestFileWatcher();

  @override
  FileWatcher watcher(String path, {bool useTestWatcher = true}) {
    if (useTestWatcher) {
      return testFileWatcher;
    }

    return super.watcher(path);
  }
}
