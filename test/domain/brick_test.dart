// ignore_for_file: unnecessary_cast

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/brick_path.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/brick_watcher.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../utils/fakes.dart';
import '../utils/mocks.dart';

void main() {
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

      final result = Brick.fromYaml(brickName, yaml as YamlMap);

      final brick = Brick(
        configuredDirs: [BrickPath(name: const Name(dirName), path: dirPath)],
        configuredFiles: [BrickFile(filePath, name: const Name(fileName))],
        excludePaths: const [excludeDir],
        name: brickName,
        source: BrickSource(localPath: localPath),
      );

      expectLater(result, brick);
    });

    test('throws $ConfigException when extra keys are provided', () {
      final yaml = loadYaml('''
source: $localPath
vars:
''');

      expect(
        () => Brick.fromYaml(brickName, yaml as YamlMap),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when dirs is not a map', () {
      final yaml = loadYaml('''
source: $localPath
dirs:
  $dirPath
''');

      expect(
        () => Brick.fromYaml(brickName, yaml as YamlMap),
        throwsA(isA<ConfigException>()),
      );
    });

    test('throws $ConfigException when files is not a map', () {
      final yaml = loadYaml('''
source: $localPath
files:
  $filePath
''');

      expect(
        () => Brick.fromYaml(brickName, yaml as YamlMap),
        throwsA(isA<ConfigException>()),
      );
    });

    group('exclude', () {
      test('throws $ConfigException when type is not a list or string', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  path: $excludeDir
''');

        expect(
          () => Brick.fromYaml(brickName, yaml as YamlMap),
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
          Brick.fromYaml(brickName, yaml as YamlMap),
          Brick(
            excludePaths: const [excludeDir],
            configuredDirs: const [],
            configuredFiles: const [],
            name: brickName,
            source: BrickSource(localPath: localPath),
          ),
        );
      });

      test('parses string', () {
        final yaml = loadYaml('''
source: $localPath
exclude: $excludeDir
''');

        expect(
          Brick.fromYaml(brickName, yaml as YamlMap),
          Brick(
            excludePaths: const [excludeDir],
            configuredDirs: const [],
            configuredFiles: const [],
            name: brickName,
            source: BrickSource(localPath: localPath),
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
          () => Brick.fromYaml(brickName, yaml as YamlMap),
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
      late Logger mockLogger;
      late Progress mockProgress;

      setUp(() {
        fs = MemoryFileSystem();
        mockWatcher = MockBrickWatcher();

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

      Brick brick({bool mockWatch = false}) {
        return Brick.memory(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
            watcher: mockWatch ? mockWatcher : null,
          ),
          configuredDirs: const [],
          configuredFiles: const [],
          fileSystem: fs,
          logger: mockLogger,
        );
      }

      test('#stopWatching calls stop on the watcher', () async {
        final testBrick = brick(mockWatch: true);

        when(mockWatcher.stop).thenAnswer((_) => Future.value());

        verifyNever(mockWatcher.stop);

        await testBrick.source.watcher?.stop();

        verify(mockWatcher.stop).called(1);
      });

      group('#cook', () {
        test(
            'uses default directory bricks/{name}/__brick__ when path not provided',
            () {
          final testBrick = brick(mockWatch: true);

          final fakeSourcePath = fs.file(join(localPath, filePath));

          final targetFile = fs.file(join(brickPath, filePath));

          expect(targetFile.existsSync(), isFalse);

          fs.file(fakeSourcePath).createSync(recursive: true);

          testBrick.cook();

          expect(targetFile.existsSync(), isTrue);
        });

        test('uses provided path for output when provided', () {
          final testBrick = brick(mockWatch: true);

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

        test('is running watcher', () async {
          final testBrick = brick(mockWatch: true);

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

          // Because MemoryFileSystem doesn't support watching,
          // We are just checking if watcher is running.
          //
          // const newContent = '// new content';
          // sourceFile.writeAsStringSync(newContent);
          // expect(targetFile.readAsStringSync(), newContent);

          when(() => mockWatcher.isRunning).thenReturn(true);

          expect(testBrick.source.watcher?.isRunning, isTrue);
        });

        test('writes bricks when no watcher is available', () {
          final testBrick = brick();

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

      group('#stopWatching', () {
        test('stops watching files for updates', () {
          final testBrick = brick(mockWatch: true);

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

          when(() => mockWatcher.isRunning).thenReturn(true);

          expect(testBrick.source.watcher?.isRunning, isTrue);

          reset(mockWatcher);

          when(mockWatcher.stop).thenAnswer((_) => Future.value());

          testBrick.source.watcher?.stop();

          when(() => mockWatcher.isRunning).thenReturn(false);

          expect(testBrick.source.watcher?.isRunning, isFalse);
        });
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
          configuredDirs: const [],
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
        configuredDirs: const [],
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
        configuredDirs: const [],
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
        configuredDirs: const [],
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
}
