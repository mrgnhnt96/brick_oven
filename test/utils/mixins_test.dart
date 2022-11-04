import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:brick_oven/utils/mixins.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../test_utils/print_override.dart';

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

      final listener = testConfigWatcher.watchForConfigChanges(
        configFile.path,
        onChange: () => hasChanged = true,
      );

      configFile.writeAsStringSync('update');

      await listener;

      expect(hasChanged, isTrue);
    });

    test('#cancelWatchers can be called', () async {
      final testConfigWatcher = TestConfigWatcher();

      expect(testConfigWatcher.cancelWatchers, returnsNormally);
    });
  });
}

class TestConfigWatcher with ConfigWatcherMixin {}
