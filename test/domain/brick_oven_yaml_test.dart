import 'package:brick_oven/domain/brick_oven_yaml.dart';
import 'package:file/file.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../utils/testing_env.dart';

void main() {
  var fs = setUpTestingEnvironment();
  late File configFile;

  setUp(() async {
    fs = setUpTestingEnvironment();

    final configPath = join(fs.currentDirectory.path, BrickOvenYaml.file);

    configFile = fs.file(configPath);

    await configFile.create(recursive: true);
  });

  tearDown(() {
    tearDownTestingEnvironment(fs);
  });

  group('$BrickOvenYaml', () {
    test('#file is brick_oven.yaml', () {
      expect(BrickOvenYaml.file, 'brick_oven.yaml');
    });

    test('#findNearest finds the brick_oven file', () {
      Directory directory(List<String> segments) {
        return fs.directory(joinAll([fs.currentDirectory.path, ...segments]));
      }

      final dirs = [
        directory(['some']),
        directory(['some', 'other']),
        directory(['some', 'other', 'path']),
      ];

      for (final dir in dirs) {
        final brickOvenYaml = BrickOvenYaml.findNearest(dir);

        expect(brickOvenYaml?.path, configFile.path);
      }
    });
  });
}
