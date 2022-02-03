import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';
import '../utils/to_yaml.dart';

void main() {
  const localPath = 'local_path';

  List<String> createFakeFiles(
    void Function(FileSystem) createFileSystem,
  ) {
    final fileSystem = MemoryFileSystem();
    createFileSystem(fileSystem);

    final fakePaths = [
      '$localPath/file1.dart',
      '$localPath/to/file2.dart',
      '$localPath/to/some/file3.dart',
    ];

    for (final file in fakePaths) {
      fileSystem.file(file).createSync(recursive: true);
    }

    return fakePaths;
  }

  test('can be instanciated', () {
    const instance = BrickSource(localPath: 'test');

    expect(instance, isA<BrickSource>());
  });

  group('#none', () {
    test('local path is null', () {
      const instance = BrickSource.none();

      expect(instance.localPath, isNull);
    });
  });

  group('#fromYaml', () {
    const path = 'test';

    group('localPath', () {
      test('should return when string provided', () {
        final instance = BrickSource.fromYaml(const YamlValue.string(path));

        expect(instance.localPath, path);
      });

      test('should return when yaml map provided', () {
        final yaml = FakeYamlMap(<String, dynamic>{'path': path});

        final instance = BrickSource.fromYaml(YamlValue.yaml(yaml));

        expect(instance.localPath, path);
      });

      test('should throw when extra keys in yaml map are provided', () {
        final yaml = const BrickSource(localPath: 'test').toYaml();
        yaml.value['extra'] = 'extra';

        expect(
          () => BrickSource.fromYaml(YamlValue.yaml(yaml)),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should return null when not provided', () {
        final instance = BrickSource.fromYaml(const YamlValue.none());

        expect(instance.localPath, isNull);
      });
    });
  });

  group('#files', () {
    test('should return no files when no source is provided', () {
      const instance = BrickSource.none();

      expect(instance.files(), isEmpty);
    });

    test('should return files from local directory', () {
      late BrickSource source;

      final fakePaths = createFakeFiles((fs) {
        source = BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        );
      });

      final files = source.files();

      expect(files, hasLength(fakePaths.length));

      for (final file in files) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
      }
    });
  });

  group('#sourceDir', () {
    test('should return local path when provided', () {
      final instance = BrickSource.memory(localPath: localPath);

      expect(instance.sourceDir, localPath);
    });
  });

  group('#mergeFilesAndConfig', () {
    test('should return all source files', () {
      late BrickSource source;

      final fakePaths = createFakeFiles((fs) {
        source = BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        );
      });

      final mergedFiles = source.mergeFilesAndConfig([]);

      expect(mergedFiles, hasLength(fakePaths.length));

      for (final file in mergedFiles) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
      }
    });

    test('should return all config files', () {
      const source = BrickSource(localPath: localPath);

      final configFiles = ['file1.dart', 'file2.dart'].map(BrickFile.new);

      final mergedFiles = source.mergeFilesAndConfig(configFiles);

      expect(mergedFiles, hasLength(configFiles.length));

      for (final file in mergedFiles) {
        expect(configFiles, contains(file));
      }
    });

    test('should return merged config files onto source files', () {
      late BrickSource source;

      final fakePaths = createFakeFiles((fs) {
        source = BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        );
      });

      final configFiles = <BrickFile>[];

      const prefix = 'prefix';
      const suffix = 'suffix';
      const variables = [Variable(name: 'name', placeholder: 'placeholder')];

      for (final path in fakePaths) {
        configFiles.add(
          BrickFile.config(
            path.substring('$localPath.'.length),
            prefix: prefix,
            suffix: suffix,
            variables: variables,
          ),
        );
      }

      final mergedFiles = source.mergeFilesAndConfig(configFiles);

      expect(mergedFiles, hasLength(fakePaths.length));

      for (final file in mergedFiles) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
        expect(file.prefix, prefix);
        expect(file.suffix, suffix);
        expect(file.variables.single, variables.single);
      }
    });
  });

  group('#fromSourcePath', () {
    test('should join source dir with files path', () {
      const source = BrickSource(localPath: localPath);
      const fileName = 'file.dart';

      const file = BrickFile(fileName);

      expect(source.fromSourcePath(file), join(localPath, fileName));
    });
  });

  group('#props', () {
    test('length should be 1', () {
      const source = BrickSource(localPath: localPath);

      expect(source.props, hasLength(1));
    });

    test('should contain local path', () {
      const source = BrickSource(localPath: localPath);

      expect(source.props.single, localPath);
    });
  });
}
