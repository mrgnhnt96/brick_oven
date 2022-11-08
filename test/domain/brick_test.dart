// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';
import 'package:yaml/yaml.dart';

import '../test_utils/fakes.dart';
import '../test_utils/mocks.dart';
import '../test_utils/print_override.dart';
import '../test_utils/test_directory_watcher.dart';

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  const brickName = 'super_awesome';
  const localPath = 'localPath';
  final brickPath = join('bricks', brickName, '__brick__');
  const dirName = 'director_of_shield';
  const excludeDir = 'exclude_me';
  const fileName = 'nick_fury.dart';
  final dirPath = join('path', 'to', dirName);
  final filePath = join(dirPath, fileName);

  group('#fromYaml', () {
    test('parses when provided', () {
      final yaml = loadYaml('''
source: $localPath
dirs:
  $dirPath: $dirName
files:
  $filePath:
    name: $fileName
exclude:
  - $excludeDir
''');

      final result = Brick.fromYaml(YamlValue.from(yaml), brickName);

      final brick = Brick(
        configuredDirs: [BrickPath(name: const Name(dirName), path: dirPath)],
        configuredFiles: [BrickFile(filePath, name: const Name(fileName))],
        excludePaths: const [excludeDir],
        name: brickName,
        source: BrickSource(localPath: localPath),
        logger: mockLogger,
      );

      expectLater(result, brick);
    });

    group('throws $ConfigException', () {
      test('when yaml is error', () {
        expect(
          () => Brick.fromYaml(const YamlValue.error('error'), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      test('when yaml is not map', () {
        expect(
          () => Brick.fromYaml(
            const YamlValue.string('Jar Jar Binks'),
            brickName,
          ),
          throwsA(isA<ConfigException>()),
        );
      });

      test('when source is incorrect type', () {
        final yaml = loadYaml('''
source: ${1}
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      test('when extra keys are provided', () {
        final yaml = loadYaml('''
vars:
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      test('when dirs is not a map', () {
        final yaml = loadYaml('''
dirs:
  $dirPath
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      test('when files is not a map', () {
        final yaml = loadYaml('''
files:
  $filePath
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      group('brick config', () {
        test('throws $ConfigException when brick config is wrong type', () {
          final yaml = loadYaml('''
brick_config:
  - Hi
''');

          expect(
            () => Brick.fromYaml(YamlValue.from(yaml), brickName),
            throwsA(isA<ConfigException>()),
          );
        });

        test('runs gracefully when brick config is null', () {
          final yaml = loadYaml('''
brick_config:
''');

          expect(
            () => Brick.fromYaml(YamlValue.from(yaml), brickName),
            returnsNormally,
          );
        });

        test('returns provided brick config', () {
          final yaml = loadYaml('''
brick_config: brick.yaml
''');

          expect(
            Brick.fromYaml(YamlValue.from(yaml), brickName).brickYamlConfig,
            const BrickYamlConfig(path: 'brick.yaml'),
          );
        });
      });
    });

    group('exclude', () {
      test('when type is not a list or string', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  path: $excludeDir
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });

      test('parses list', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - $excludeDir
''');

        expect(
          Brick.fromYaml(YamlValue.from(yaml), brickName),
          Brick(
            excludePaths: const [excludeDir],
            name: brickName,
            source: BrickSource(localPath: localPath),
            logger: mockLogger,
          ),
        );
      });

      test('parses string', () {
        final yaml = loadYaml('''
source: $localPath
exclude: $excludeDir
''');

        expect(
          Brick.fromYaml(YamlValue.from(yaml), brickName),
          Brick(
            excludePaths: const [excludeDir],
            name: brickName,
            source: BrickSource(localPath: localPath),
            logger: mockLogger,
          ),
        );
      });

      test('throws $ConfigException non strings are provided', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - some/path
  - ${123}
  - ${true}
  - ${<String, dynamic>{}}
''');

        expect(
          () => Brick.fromYaml(YamlValue.from(yaml), brickName),
          throwsA(isA<ConfigException>()),
        );
      });
    });
  });

  // Watcher only listens to local files, so we need to mock the file system
  group(
    'watcher',
    () {
      late FileSystem fs;
      late BrickWatcher mockWatcher;
      late TestDirectoryWatcher testDirectoryWatcher;
      late Logger mockLogger;
      late Progress mockProgress;

      setUp(() {
        fs = MemoryFileSystem();
        mockWatcher = MockBrickWatcher();
        testDirectoryWatcher = TestDirectoryWatcher();

        when(() => mockWatcher.addEvent(any())).thenReturn(voidCallback());
        when(mockWatcher.start).thenAnswer((_) => Future.value());
        when(() => mockWatcher.hasRun).thenReturn(false);

        mockProgress = MockProgress();

        when(() => mockProgress.complete(any())).thenReturn(voidCallback());
        when(() => mockProgress.fail(any())).thenReturn(voidCallback());
        when(() => mockProgress.update(any())).thenReturn(voidCallback());

        mockLogger = MockLogger();

        when(() => mockLogger.progress(any())).thenReturn(mockProgress);
        when(() => mockLogger.success(any())).thenReturn(null);
      });

      tearDown(() {
        testDirectoryWatcher.close();
      });

      group('#cook', () {
        test(
            'uses default directory bricks/{name}/__brick__ when path not provided',
            () {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: mockWatcher,
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final fakeSourcePath = fs.file(join(localPath, filePath));

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          fs.file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook();

          expect(targetFile.existsSync(), isTrue);
        });

        test('uses provided path for output when provided', () {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: mockWatcher,
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final fakeSourcePath = fs.file(join(localPath, filePath));

          const output = 'out';

          final targetFile = fs.file(
            join(output, brickName, '__brick__', filePath),
          );

          expect(targetFile.existsSync(), isFalse);

          fs.file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook(watch: true, output: output);

          expect(targetFile.existsSync(), isTrue);
        });

        test('file gets updated on modify event', () async {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: BrickWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          const newContent = '// new content';
          sourceFile.writeAsStringSync(newContent);

          final event = WatchEvent(ChangeType.MODIFY, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.readAsStringSync(), newContent);
          expect(testBrick.source.watcher?.isRunning, isTrue);
        });

        test('file gets added on create event', () async {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: BrickWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          final targetFile = fs.file(join(brickPath, filePath));

          expect(sourceFile.existsSync(), isFalse);
          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final event = WatchEvent(ChangeType.ADD, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          expect(testBrick.source.watcher?.isRunning, isTrue);
        });

        test('file gets delete on delete event', () async {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: BrickWatcher.config(
                dirPath: localPath,
                watcher: testDirectoryWatcher,
              ),
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          final targetFile = fs.file(join(brickPath, filePath));

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          expect(sourceFile.existsSync(), isTrue);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          sourceFile.deleteSync();

          final event = WatchEvent(ChangeType.REMOVE, sourceFile.path);
          testDirectoryWatcher.triggerEvent(event);

          expect(targetFile.existsSync(), isFalse);

          expect(testBrick.source.watcher?.isRunning, isTrue);
        });

        test('writes bricks when no watcher is available', () {
          final testBrick = Brick.memory(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
            ),
            fileSystem: fs,
            logger: mockLogger,
          );

          final sourceFile = fs.file(join(localPath, filePath));

          const content = '// content';

          sourceFile
            ..createSync(recursive: true)
            ..writeAsStringSync(content);

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          testBrick.cook(watch: true);

          expect(targetFile.existsSync(), isTrue);
          expect(targetFile.readAsStringSync(), content);

          expect(testBrick.source.watcher?.isRunning, isNull);
        });
      });

      test('stops watching files for updates', () async {
        final testBrick = Brick.memory(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
            watcher: BrickWatcher.config(
              dirPath: localPath,
              watcher: testDirectoryWatcher,
            ),
          ),
          fileSystem: fs,
          logger: mockLogger,
        );

        final sourceFile = fs.file(join(localPath, filePath));

        const content = '// content';

        sourceFile
          ..createSync(recursive: true)
          ..writeAsStringSync(content);

        final targetFile = fs.file(join(brickPath, filePath));

        expect(targetFile.existsSync(), isFalse);

        testBrick.cook(watch: true);

        expect(targetFile.existsSync(), isTrue);
        expect(targetFile.readAsStringSync(), content);

        expect(testBrick.source.watcher?.isRunning, isTrue);

        await testBrick.source.watcher?.stop();

        expect(testBrick.source.watcher?.isRunning, isFalse);
      });
    },
  );

  group('#writeBrick', () {
    late FileSystem fs;
    late Logger mockLogger;
    late Progress mockProgress;

    setUp(() {
      fs = MemoryFileSystem();
      mockLogger = MockLogger();
      mockProgress = MockProgress();

      when(() => mockProgress.complete(any())).thenReturn(voidCallback());
      when(() => mockProgress.fail(any())).thenReturn(voidCallback());
      when(() => mockProgress.update(any())).thenReturn(voidCallback());

      when(() => mockLogger.progress(any())).thenReturn(mockProgress);
      when(() => mockLogger.success(any())).thenReturn(null);
    });

    test(
      'uses default directory bricks/{name}/__brick__ when path not provided',
      () {
        final testBrick = Brick.memory(
          name: brickName,
          logger: mockLogger,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
          ),
          configuredFiles: [BrickFile(filePath)],
          fileSystem: fs,
        );

        final fakeSourcePath = fs.file(
          testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
        );

        final targetFile = fs.file(join(brickPath, filePath));

        expect(targetFile.existsSync(), isFalse);

        fs.file(fakeSourcePath).createSync(recursive: true);

        testBrick.cook();

        expect(targetFile.existsSync(), isTrue);
      },
    );

    test('uses provided path for output when provided', () {
      final testBrick = Brick.memory(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        configuredFiles: [BrickFile(filePath)],
        fileSystem: fs,
      );

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
      );

      const output = 'out';

      final targetFile = fs.file(
        join(output, brickName, '__brick__', filePath),
      );

      expect(targetFile.existsSync(), isFalse);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook(output: output);

      expect(targetFile.existsSync(), isTrue);
    });

    test('deletes directory if exists', () {
      final testBrick = Brick.memory(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        configuredFiles: [BrickFile(filePath)],
        fileSystem: fs,
      );

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.configuredFiles.single),
      );

      final fakeUnneededFile = fs.file(join(brickPath, 'unneeded.dart'));

      expect(fakeUnneededFile.existsSync(), isFalse);

      fakeUnneededFile.createSync(recursive: true);

      expect(fakeUnneededFile.existsSync(), isTrue);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(fakeUnneededFile.existsSync(), isFalse);
    });

    test('loops through files to write', () {
      const files = ['file1.dart', 'file2.dart', 'file3.dart'];

      for (final file in files) {
        final fakeSourcePath = fs.file(join(localPath, file));

        fs.file(fakeSourcePath).createSync(recursive: true);
      }

      final testBrick = Brick.memory(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        configuredFiles: [for (final file in files) BrickFile(file)],
        fileSystem: fs,
      );

      for (final file in testBrick.configuredFiles) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isFalse);
      }

      testBrick.cook();

      for (final file in testBrick.configuredFiles) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isTrue);
      }
    });
  });

  group('#allBrickVariables', () {
    group('files', () {
      test('gets #variables from files', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredFiles: const [
            BrickFile.config(
              '',
              variables: [
                Variable(name: 'var1'),
                Variable(name: 'var2'),
                Variable(name: 'var3'),
              ],
            ),
            BrickFile.config(
              '',
              variables: [
                Variable(name: 'var4'),
                Variable(name: 'var5'),
                Variable(name: 'var6'),
              ],
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
            'var3',
            'var4',
            'var5',
            'var6',
          },
        );
      });

      test('gets #includeIf', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredFiles: const [
            BrickFile.config(
              '',
              includeIf: 'var1',
            ),
            BrickFile.config(
              '',
              includeIf: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );
      });

      test('gets #includeIfNot', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredFiles: const [
            BrickFile.config(
              '',
              includeIfNot: 'var1',
            ),
            BrickFile.config(
              '',
              includeIfNot: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );
      });
    });

    group('dirs', () {
      test('gets #names', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredDirs: [
            BrickPath(name: const Name('name1'), path: ''),
            BrickPath(name: const Name('name2'), path: ''),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'name1',
            'name2',
          },
        );
      });

      test('gets #includeIf', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredDirs: [
            BrickPath(
              path: '',
              includeIf: 'var1',
            ),
            BrickPath(
              path: '',
              includeIf: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );
      });

      test('gets #includeIfNot', () {
        final brick = Brick(
          name: '',
          source: const BrickSource.none(),
          logger: mockLogger,
          configuredDirs: [
            BrickPath(
              path: '',
              includeIfNot: 'var1',
            ),
            BrickPath(
              path: '',
              includeIfNot: 'var2',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
          },
        );
      });
    });
  });

  group('#checkBrickYamlConfig', () {
    late Logger mockLogger;
    late BrickYamlConfig mockBricYamlConfig;

    setUp(() {
      printLogs = [];

      mockLogger = MockLogger();
      mockBricYamlConfig = MockBrickYamlConfig();
    });

    test('returns when brickYamlConfig is null', () {
      Brick(
        name: '',
        source: const BrickSource.none(),
        logger: mockLogger,
      ).checkBrickYamlConfig();

      expect(printLogs, isEmpty);
    });

    test('warns when data returns null in reading brick.yaml file', () {
      when(mockBricYamlConfig.data).thenReturn(null);
      verifyNever(() => mockLogger.warn(any()));

      Brick(
        name: '',
        source: const BrickSource.none(),
        brickYamlConfig: mockBricYamlConfig,
        logger: mockLogger,
      ).checkBrickYamlConfig();

      verify(() => mockLogger.warn('Error reading `brick.yaml`')).called(1);
    });

    test('warns when names are not in sync', () {
      when(mockBricYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Master Skywalker', vars: []));

      verifyNever(() => mockLogger.warn(any()));

      Brick(
        name: 'Master Yoda',
        source: const BrickSource.none(),
        brickYamlConfig: mockBricYamlConfig,
        logger: mockLogger,
      ).checkBrickYamlConfig();

      verify(
        () => mockLogger.warn(
          '`name` (Master Skywalker) in brick.yaml does not '
          'match the name in brick_oven.yaml (Master Yoda)',
        ),
      ).called(1);

      verify(() => mockLogger.err('brick.yaml is out of sync')).called(1);
    });

    test('alerts when brick.yaml is in sync', () {
      when(mockBricYamlConfig.data)
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));

      verifyNever(() => mockLogger.info(any()));

      Brick(
        name: 'Count Dooku',
        source: const BrickSource.none(),
        brickYamlConfig: mockBricYamlConfig,
        logger: mockLogger,
      ).checkBrickYamlConfig();

      verifyNever(() => mockLogger.warn(any()));
      verifyNever(() => mockLogger.err(any()));
      verify(() => mockLogger.info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    group('alerts when brick.yaml is in out of sync', () {
      test('when brick.yaml contains extra variables', () {
        when(mockBricYamlConfig.data).thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: ['var1', 'var2'],
          ),
        );

        verifyNever(() => mockLogger.warn(any()));
        verifyNever(() => mockLogger.err(any()));

        Brick(
          name: 'Count Dooku',
          source: const BrickSource.none(),
          brickYamlConfig: mockBricYamlConfig,
          logger: mockLogger,
        ).checkBrickYamlConfig();

        verify(
          () => mockLogger.warn(
            darkGray.wrap(
              'Variables are defined in brick.yaml but not used in '
              'brick_oven.yaml: "var1", "var2"',
            ),
          ),
        ).called(1);

        verify(
          () => mockLogger.err('brick.yaml is out of sync'),
        ).called(1);
      });

      test('when brick_oven.yaml contains extra variables', () {
        when(mockBricYamlConfig.data).thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: [],
          ),
        );

        verifyNever(() => mockLogger.warn(any()));
        verifyNever(() => mockLogger.err(any()));

        Brick(
          name: 'Count Dooku',
          source: const BrickSource.none(),
          brickYamlConfig: mockBricYamlConfig,
          logger: mockLogger,
          configuredDirs: [
            BrickPath(
              name: const Name('var1'),
              includeIf: 'var2',
              path: '',
            ),
          ],
        ).checkBrickYamlConfig();

        verify(
          () => mockLogger.warn(
            darkGray.wrap(
              'Variables are defined in brick_oven.yaml but not used in '
              'brick.yaml: "var1", "var2"',
            ),
          ),
        ).called(1);

        verify(
          () => mockLogger.err('brick.yaml is out of sync'),
        ).called(1);
      });
    });
  });
}
