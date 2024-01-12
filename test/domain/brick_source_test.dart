import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/di.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../test_utils/di.dart';

void main() {
  const localPath = 'local_path';

  setUp(setupTestDi);

  List<String> createFakeFiles() {
    final fakePaths = [
      join(localPath, 'file1.dart'),
      join(localPath, 'to', 'file2.dart'),
      join(localPath, 'to', 'some', 'file3.dart'),
    ];

    for (final file in fakePaths) {
      di<FileSystem>().file(file).createSync(recursive: true);
    }

    return fakePaths;
  }

  test('can be instantiated', () {
    final instance = BrickSource(localPath: 'test');

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

    group('source key', () {
      test('should return when provided', () {
        final yaml = loadYaml('''
$path
''') as String;
        final instance = BrickSource.fromYaml(
          YamlValue.from(yaml),
        );

        expect(instance.localPath, path);
      });

      test('should return when empty', () {
        final instance = BrickSource.fromYaml(
          YamlValue.from(YamlMap.wrap({'path': ''})),
        );

        expect(instance.localPath, isNull);
      });

      test(
          'should return when relative path when configPath is provided with source path',
          () {
        final instance = BrickSource.fromYaml(
          YamlValue.from('.'),
          configPath: 'path/to/config.yaml',
        );

        expect(instance.localPath, 'path/to');
      });

      test(
          'should throw $ConfigException when source is null and configPath is provided',
          () {
        BrickSource instance() {
          return BrickSource.fromYaml(
            YamlValue.from(null),
            configPath: 'path/to/config.yaml',
          );
        }

        expect(instance, throwsA(isA<ConfigException>()));
      });

      test(
          'should throw $ConfigException when path value is null and configPath is provided',
          () {
        final yaml = loadYaml('''
path:
''') as YamlMap;

        BrickSource instance() {
          return BrickSource.fromYaml(
            YamlValue.from(yaml),
            configPath: 'path/to/config.yaml',
          );
        }

        expect(instance, throwsA(isA<ConfigException>()));
      });

      test('should return when path key is provided', () {
        final yaml = loadYaml('''
path: $path
''') as YamlMap;

        final instance = BrickSource.fromYaml(
          YamlValue.yaml(yaml),
        );

        expect(instance.localPath, path);
      });

      test(
          'should throw $ConfigException when extra keys in yaml map are provided',
          () {
        final yaml = loadYaml('''
path: $path
extra: key
''') as YamlMap;

        expect(
          () => BrickSource.fromYaml(
            YamlValue.yaml(yaml),
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should throw $ConfigException when yaml is error', () {
        expect(
          () => BrickSource.fromYaml(
            const YamlError('error'),
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should return null when path value is not provided', () {
        final yaml = loadYaml('''
path:
''') as YamlMap;

        final instance = BrickSource.fromYaml(
          YamlValue.from(yaml),
        );

        expect(instance.localPath, isNull);
      });

      test('should throw $ConfigException when path is not type string', () {
        final yaml = loadYaml('''
path:
  - $path
''') as YamlMap;

        expect(
          () => BrickSource.fromYaml(
            YamlValue.yaml(yaml),
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('should return null when not provided', () {
        final instance = BrickSource.fromYaml(
          const YamlValue.none(),
        );

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
      const source = BrickSource.memory(
        localPath: localPath,
      );

      final fakePaths = createFakeFiles();

      final files = source.files();

      expect(files, hasLength(fakePaths.length));

      for (final file in files) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
      }
    });
  });

  group('#sourceDir', () {
    test('should return local path when provided', () {
      const instance = BrickSource.memory(
        localPath: localPath,
      );

      expect(instance.sourceDir, localPath);
    });
  });

  group('#mergeFilesAndConfig', () {
    test('should return all source files', () {
      const source = BrickSource.memory(
        localPath: localPath,
      );

      final fakePaths = createFakeFiles();

      final mergedFiles = source.mergeFilesAndConfig([]);

      expect(mergedFiles, hasLength(fakePaths.length));

      for (final file in mergedFiles) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
      }

      verifyNoMoreInteractions(di<Logger>());
    });

    test('should return no config file when source files do not exist', () {
      final source = BrickSource(
        localPath: localPath,
      );

      final configFiles = ['file1.dart', 'file2.dart'].map(BrickFile.new);

      verifyNever(() => di<Logger>().info(any()));
      verifyNever(() => di<Logger>().warn(any()));

      final mergedFiles = source.mergeFilesAndConfig(configFiles);

      verify(() => di<Logger>().info('')).called(2);
      verify(
        () => di<Logger>().warn(
          'The configured file "file1.dart" does not exist within local_path',
        ),
      ).called(1);
      verify(
        () => di<Logger>().warn(
          'The configured file "file2.dart" does not exist within local_path',
        ),
      ).called(1);

      expect(mergedFiles, hasLength(0));

      for (final file in mergedFiles) {
        expect(configFiles, isNot(contains(file)));
      }

      verifyNoMoreInteractions(di<Logger>());
    });

    test('should return all config files', () {
      const source = BrickSource.memory(
        localPath: localPath,
      );

      final files = createFakeFiles();

      final configFiles = files.map((e) {
        final path = e.replaceFirst('$localPath/', '');
        return BrickFile(path);
      });

      final mergedFiles = source.mergeFilesAndConfig(configFiles);

      expect(mergedFiles, hasLength(configFiles.length));

      for (final file in mergedFiles) {
        expect(configFiles, contains(file));
      }

      verifyNoMoreInteractions(di<Logger>());
    });

    test('should return merged config files onto source files', () {
      const source = BrickSource.memory(
        localPath: localPath,
      );

      final fakePaths = createFakeFiles();

      final configFiles = <BrickFile>[];

      const variables = [Variable(name: 'name', placeholder: 'placeholder')];

      for (final path in fakePaths) {
        configFiles.add(
          BrickFile.config(
            path.substring('$localPath.'.length),
            variables: variables,
          ),
        );
      }

      final mergedFiles = source.mergeFilesAndConfig(configFiles);

      expect(mergedFiles, hasLength(fakePaths.length));

      for (final file in mergedFiles) {
        expect(fakePaths, contains('$localPath$separator${file.path}'));
        // expect(file.prefix, prefix);
        // expect(file.suffix, suffix);
        expect(file.variables.single, variables.single);
      }
    });

    test(
      'should exclude files that match or are children of excluded paths',
      () {
        final excludedPaths = [
          'excluded/**',
          'other/file.dart',
        ];

        final files = [
          'file1.dart',
          'file2.dart',
          'excluded/file1.dart',
          'excluded/file2.dart',
          'other/file.dart',
        ];

        for (final file in files) {
          di<FileSystem>().file(file).createSync(recursive: true);
        }

        const source = BrickSource.memory(
          localPath: '.',
        );

        final brickFiles = source.mergeFilesAndConfig(
          [],
          excludedPaths: excludedPaths,
        ).toList();

        expect(brickFiles.length, 2);
        expect(brickFiles[0].path, 'file1.dart');
        expect(brickFiles[1].path, 'file2.dart');

        verifyNoMoreInteractions(di<Logger>());
      },
    );

    test(
        'should include files that are followed by paths that should be excluded',
        () {
      final excludedPaths = [
        '.history/**',
        '.idea/**',
        'mobile_app.iml',
        'brick_oven.yaml',
        'derry.yaml',
      ];

      final files = [
        '.history/file1.dart',
        '.idea/file2.dart',
        'mobile_app.iml',
        'brick_oven.yaml',
        'derry.yaml',
        'android/app/src/main/kotlin/com/example/mobile_app/MainActivity.kt',
        'ios/Runner/AppDelegate.swift',
        'lib/main.dart',
      ];

      for (final file in files) {
        di<FileSystem>().file(file).createSync(recursive: true);
      }

      const source = BrickSource.memory(
        localPath: '.',
      );

      final brickFiles = source.mergeFilesAndConfig(
        [],
        excludedPaths: excludedPaths,
      ).toList();

      final paths = brickFiles.map((e) => e.path);

      expect(paths.length, 3);
      expect(
        paths,
        contains(
          'android/app/src/main/kotlin/com/example/mobile_app/MainActivity.kt',
        ),
      );
      expect(paths, contains('ios/Runner/AppDelegate.swift'));
      expect(paths, contains('lib/main.dart'));

      verifyNoMoreInteractions(di<Logger>());
    });
  });

  group('#fromSourcePath', () {
    test('should join source dir with files path', () {
      final source = BrickSource(
        localPath: localPath,
      );
      const fileName = 'file.dart';

      const file = BrickFile(fileName);

      expect(source.fromSourcePath(file.path), join(localPath, fileName));
    });
  });
}
