// ignore_for_file: unnecessary_cast

import 'dart:async';

import 'package:brick_oven/domain/brick.dart';
import 'package:brick_oven/domain/brick_file.dart';
import 'package:brick_oven/domain/partial.dart';
import 'package:brick_oven/domain/brick_dir.dart';
import 'package:brick_oven/domain/brick_source.dart';
import 'package:brick_oven/domain/source_watcher.dart';
import 'package:brick_oven/domain/brick_yaml_config.dart';
import 'package:brick_oven/domain/brick_yaml_data.dart';
import 'package:brick_oven/domain/name.dart';
import 'package:brick_oven/domain/variable.dart';
import 'package:brick_oven/domain/yaml_value.dart';
import 'package:brick_oven/src/exception.dart';
import 'package:brick_oven/utils/constants.dart';
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

    registerFallbackValue(mockLogger);
  });

  const brickName = 'super_awesome';
  const localPath = 'localPath';
  final brickPath = join('bricks', brickName, '__brick__');
  const dirName = 'director_of_shield';
  final dirPath = join('path', 'to', dirName);
  const excludeDir = 'exclude_me';
  const fileName = 'nick_fury.dart';
  final filePath = join(dirPath, fileName);
  const partialName = 'partial.dart';
  final partialPath = join(dirPath, partialName);

  group('#fromYaml', () {
    test('parses when provided', () {
      final yaml = loadYaml('''
source: $localPath
dirs:
  $dirPath: $dirName
files:
  $filePath:
    name: $fileName
partials:
  $partialPath:
    vars:
      one:
exclude:
  - $excludeDir
''');

      final result = Brick.fromYaml(
        YamlValue.from(yaml),
        brickName,
        fileSystem: MemoryFileSystem(),
        logger: mockLogger,
      );

      final brick = Brick(
        dirs: [BrickDir(name: Name(dirName), path: dirPath)],
        files: [BrickFile(filePath, name: Name(fileName))],
        exclude: const [excludeDir],
        name: brickName,
        source: BrickSource(
          localPath: localPath,
          fileSystem: MemoryFileSystem(),
        ),
        partials: [
          Partial(
            path: partialPath,
            variables: const [Variable(name: 'one')],
          )
        ],
        fileSystem: MemoryFileSystem(),
        logger: mockLogger,
      );

      expect(result, brick);

      verifyNoMoreInteractions(mockLogger);
    });

    group('throws $BrickException', () {
      test('when yaml is error', () {
        expect(
          () => Brick.fromYaml(
            const YamlValue.error('error'),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when yaml is not map', () {
        expect(
          () => Brick.fromYaml(
            const YamlValue.string('Jar Jar Binks'),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when source is incorrect type', () {
        final yaml = loadYaml('''
source: ${1}
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when extra keys are provided', () {
        final yaml = loadYaml('''
vars:
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when dirs is not a map', () {
        final yaml = loadYaml('''
dirs:
  $dirPath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when files is not a map', () {
        final yaml = loadYaml('''
files:
  $filePath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<FileException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('when partials is not a map', () {
        final yaml = loadYaml('''
partials:
  $partialPath
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      group('brick config', () {
        test('runs gracefully when brick config is null', () {
          final yaml = loadYaml('''
brick_config:
''');

          expect(
            () => Brick.fromYaml(
              YamlValue.from(yaml),
              brickName,
              fileSystem: MemoryFileSystem(),
              logger: mockLogger,
            ),
            returnsNormally,
          );

          verifyNoMoreInteractions(mockLogger);
        });

        test('returns provided brick config', () {
          final yaml = loadYaml('''
brick_config: brick.yaml
''');

          expect(
            Brick.fromYaml(
              YamlValue.from(yaml),
              brickName,
              fileSystem: MemoryFileSystem(),
              logger: mockLogger,
            ).brickYamlConfig,
            BrickYamlConfig(
              path: 'brick.yaml',
              ignoreVars: const [],
              fileSystem: MemoryFileSystem(),
            ),
          );

          verifyNoMoreInteractions(mockLogger);
        });
      });
    });

    test('#defaultVariables has correct values', () {
      const expected = [
        Variable(name: '.', placeholder: kIndexValue),
      ];

      expect(Brick.defaultVariables, expected);
    });

    group('exclude', () {
      test('when type is not a list or string', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  path: $excludeDir
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('parses list', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - $excludeDir
''');

        expect(
          Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          Brick(
            exclude: const [excludeDir],
            name: brickName,
            source: BrickSource(
              localPath: localPath,
              fileSystem: MemoryFileSystem(),
            ),
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('parses string', () {
        final yaml = loadYaml('''
source: $localPath
exclude: $excludeDir
''');

        expect(
          Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          Brick(
            exclude: const [excludeDir],
            name: brickName,
            source: BrickSource(
              localPath: localPath,
              fileSystem: MemoryFileSystem(),
            ),
            logger: mockLogger,
            fileSystem: MemoryFileSystem(),
          ),
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('throws $BrickException non strings are provided', () {
        final yaml = loadYaml('''
source: $localPath
exclude:
  - some/path
  - ${123}
  - ${true}
  - ${<String, dynamic>{}}
''');

        expect(
          () => Brick.fromYaml(
            YamlValue.from(yaml),
            brickName,
            fileSystem: MemoryFileSystem(),
            logger: mockLogger,
          ),
          throwsA(isA<BrickException>()),
        );

        verifyNoMoreInteractions(mockLogger);
      });
    });
  });

  // Watcher only listens to local files, so we need to mock the file system
  group(
    'watcher',
    () {
      late FileSystem fs;
      late SourceWatcher mockWatcher;
      late TestDirectoryWatcher testDirectoryWatcher;
      late Logger mockLogger;
      late Progress mockProgress;

      setUp(() {
        fs = MemoryFileSystem();
        mockWatcher = MockSourceWatcher();
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
          final testBrick = Brick(
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

          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockWatcher);
        });

        test('uses provided path for output when provided', () {
          final testBrick = Brick(
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

          verify(() => mockWatcher.addEvent(any())).called(2);

          verify(mockWatcher.start).called(1);
          verify(() => mockWatcher.hasRun).called(1);

          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
          verifyNoMoreInteractions(mockWatcher);
        });

        test('file gets updated on modify event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: SourceWatcher.config(
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

          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
        });

        test('file gets added on create event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: SourceWatcher.config(
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
          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
        });

        test('file gets delete on delete event', () async {
          final testBrick = Brick(
            name: brickName,
            source: BrickSource.memory(
              localPath: localPath,
              fileSystem: fs,
              watcher: SourceWatcher.config(
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

          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
        });

        test('writes bricks when no watcher is available', () {
          final testBrick = Brick(
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

          verify(() => mockLogger.progress('Writing Brick: super_awesome'))
              .called(1);

          verifyNoMoreInteractions(mockLogger);
        });

        test('prints warning if excess variables exist', () {
          verifyNever(() => mockLogger.warn(any()));

          fs.file(join('path', 'file1.dart')).createSync(recursive: true);

          fs.file(join('path', 'file2.dart')).createSync(recursive: true);

          fs.file('partial').createSync(recursive: true);

          final brick = Brick(
            name: 'BRICK',
            source: BrickSource(
              localPath: '.',
              fileSystem: fs,
            ),
            logger: mockLogger,
            fileSystem: fs,
            partials: const [
              Partial(
                path: 'partial',
                variables: [Variable(name: 'partialVar')],
              ),
            ],
            dirs: [
              BrickDir(
                path: 'path',
                includeIf: 'dirIncludeIf',
                name: Name('dirName', section: 'dirSection'),
              ),
              BrickDir(
                path: 'path',
                includeIfNot: 'dirIncludeIfNot',
                name: Name('dirName', invertedSection: 'dirInvertedSection'),
              ),
            ],
            files: [
              BrickFile.config(
                join('path', 'file1.dart'),
                includeIf: 'fileIncludeIf',
                name: Name('fileName1', section: 'fileSection'),
                variables: const [Variable(name: 'fileVar1')],
              ),
              BrickFile.config(
                join('path', 'file2.dart'),
                name: Name('fileName2', invertedSection: 'fileInvertedSection'),
                includeIfNot: 'fileIncludeIfNot',
                variables: const [Variable(name: 'fileVar2')],
              ),
            ],
          );

          // ignore: cascade_invocations
          brick.cook();

          const vars = '"fileVar1", '
              '"fileVar2", '
              '"partialVar", '
              '"dirSection", '
              '"dirIncludeIf", '
              '"dirInvertedSection", '
              '"dirIncludeIfNot"';

          verify(
            () => mockLogger
                .warn('Unused variables ("fileVar1") in `./path/file1.dart`'),
          ).called(1);
          verify(
            () => mockLogger
                .warn('Unused variables ("fileVar2") in `./path/file2.dart`'),
          ).called(1);
          verify(() => mockLogger.warn('Unused variables ($vars) in BRICK'))
              .called(1);
          verify(() => mockLogger.progress('Writing Brick: BRICK')).called(1);

          verify(() => mockLogger.warn('Unused partials ("partial") in BRICK'))
              .called(1);

          verify(
            () => mockLogger
                .warn('Unused variables ("partialVar") in `./partial`'),
          ).called(1);

          verifyNoMoreInteractions(mockLogger);
        });

        test('does not print warning if excess variables do not exist', () {
          verifyNever(() => mockLogger.warn(any()));

          fs.file(join('path', 'file1.dart'))
            ..createSync(recursive: true)
            ..writeAsStringSync('fileVar1');

          fs.file(join('path', 'to', 'file2.dart'))
            ..createSync(recursive: true)
            ..writeAsStringSync('fileVar2');

          fs.file('partial')
            ..createSync(recursive: true)
            ..writeAsStringSync('partialVar');

          final brick = Brick(
            name: 'BRICK',
            source: BrickSource(
              localPath: '.',
              fileSystem: fs,
            ),
            logger: mockLogger,
            fileSystem: fs,
            partials: const [
              Partial(
                path: 'partial',
                variables: [Variable(name: 'partialVar')],
              ),
            ],
            dirs: [
              BrickDir(
                path: 'path',
                includeIf: 'dirIncludeIf',
                name: Name('dirName', section: 'dirSection'),
              ),
              BrickDir(
                path: join('path', 'to'),
                includeIfNot: 'dirIncludeIfNot',
                name: Name('dirName', invertedSection: 'dirInvertedSection'),
              ),
            ],
            files: [
              BrickFile.config(
                join('path', 'file1.dart'),
                includeIf: 'fileIncludeIf',
                name: Name('fileName1', section: 'fileSection'),
                variables: const [Variable(name: 'fileVar1')],
              ),
              BrickFile.config(
                join('path', 'to', 'file2.dart'),
                name: Name('fileName2', invertedSection: 'fileInvertedSection'),
                includeIfNot: 'fileIncludeIfNot',
                variables: const [Variable(name: 'fileVar2')],
              ),
            ],
          );

          // ignore: cascade_invocations
          brick.cook();

          verifyNoMoreInteractions(mockLogger);
        });
      });

      test('stops watching files for updates', () async {
        final testBrick = Brick(
          name: brickName,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
            watcher: SourceWatcher.config(
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

        verify(() => mockLogger.progress('Writing Brick: super_awesome'))
            .called(1);

        verifyNoMoreInteractions(mockLogger);
      });
    },
  );

  group('#cook', () {
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

      registerFallbackValue(MockLogger());
      registerFallbackValue(MockFile());
      registerFallbackValue(MemoryFileSystem());
    });

    test('throws $BrickException when duplicate partials exist', () {
      final brick = Brick(
        name: 'Brick',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: fs,
        partials: [
          Partial(
            path: join(localPath, filePath),
          ),
          Partial(
            path: join(localPath, 'to', filePath),
          ),
        ],
      );

      expect(
        brick.cook,
        throwsA(
          isA<BrickException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate partials ("$fileName") in Brick'),
          ),
        ),
      );

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    test('throws $BrickException when partial #writeFile throws', () {
      final mockPartial = MockBrickPartial();

      when(() => mockPartial.fileName).thenReturn(fileName);
      when(() => mockPartial.path).thenReturn(filePath);

      when(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).thenThrow(
        const PartialException(partial: 'this one', reason: 'for no reason'),
      );

      final brick = Brick(
        name: 'Brick',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: fs,
        partials: [mockPartial],
      );

      expect(
        brick.cook,
        throwsA(isA<BrickException>()),
      );

      verify(
        () => mockProgress.fail(
          '(Brick) Failed to write partial: $filePath',
        ),
      ).called(1);
      verify(() => mockLogger.progress('Writing Brick: Brick')).called(1);

      verify(() => mockPartial.path).called(3);
      verify(() => mockPartial.fileName).called(2);

      verify(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPartial);
    });

    test('throws $Exception when partial #writeFile throws', () {
      final mockPartial = MockBrickPartial();

      when(() => mockPartial.fileName).thenReturn(fileName);
      when(() => mockPartial.path).thenReturn(filePath);

      when(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).thenThrow(
        Exception('error'),
      );

      final brick = Brick(
        name: 'Brick',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: fs,
        partials: [mockPartial],
      );

      expect(
        brick.cook,
        throwsA(isA<Exception>()),
      );

      verify(
        () => mockProgress.fail(
          '(Brick) Failed to write partial: $filePath',
        ),
      ).called(1);
      verify(() => mockLogger.progress('Writing Brick: Brick')).called(1);
      verify(() => mockPartial.path).called(3);
      verify(() => mockPartial.fileName).called(2);

      verify(
        () => mockPartial.writeTargetFile(
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          outOfFileVariables: any(named: 'outOfFileVariables'),
        ),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockPartial);
    });

    test('throws $BrickException when file #writefile throws', () {
      final mockFile = MockBrickFile();
      final mockSource = MockBrickSource();

      when(
        () =>
            mockSource.mergeFilesAndConfig(any(), logger: any(named: 'logger')),
      ).thenReturn([mockFile]);

      when(
        () => mockSource.fromSourcePath(any()),
      ).thenReturn('');

      when(mockFile.formatName).thenReturn(fileName);
      when(() => mockFile.path).thenReturn(filePath);
      when(() => mockFile.variables).thenReturn([]);

      when(
        () => mockFile.writeTargetFile(
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).thenThrow(
        const FileException(file: 'this one', reason: 'for no reason'),
      );

      final brick = Brick(
        name: 'Brick',
        source: mockSource,
        logger: mockLogger,
        fileSystem: fs,
        files: [mockFile],
      );

      expect(
        brick.cook,
        throwsA(isA<BrickException>()),
      );

      verify(() => mockProgress.fail('(Brick) Failed to write file: $filePath'))
          .called(1);
      verify(() => mockLogger.progress('Writing Brick: Brick')).called(1);
      verify(() => mockFile.path).called(3);
      verify(
        () => mockFile.writeTargetFile(
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).called(1);

      verify(() => mockSource.watcher).called(1);
      verify(
        () => mockSource.mergeFilesAndConfig([mockFile], logger: mockLogger),
      ).called(1);
      verify(
        () => mockSource.fromSourcePath(filePath),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockFile);
      verifyNoMoreInteractions(mockSource);
    });

    test('throws $Exception when file #writefile throws', () {
      final mockFile = MockBrickFile();
      final mockSource = MockBrickSource();

      when(
        () =>
            mockSource.mergeFilesAndConfig(any(), logger: any(named: 'logger')),
      ).thenReturn([mockFile]);

      when(
        () => mockSource.fromSourcePath(any()),
      ).thenReturn('');

      when(mockFile.formatName).thenReturn(fileName);
      when(() => mockFile.path).thenReturn(filePath);
      when(() => mockFile.variables).thenReturn([]);

      when(
        () => mockFile.writeTargetFile(
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).thenThrow(
        Exception('error'),
      );

      final brick = Brick(
        name: 'Brick',
        source: mockSource,
        logger: mockLogger,
        fileSystem: fs,
        files: [mockFile],
      );

      expect(
        brick.cook,
        throwsA(isA<Exception>()),
      );

      verify(() => mockProgress.fail('(Brick) Failed to write file: $filePath'))
          .called(1);
      verify(() => mockLogger.progress('Writing Brick: Brick')).called(1);
      verify(() => mockFile.path).called(3);
      verify(
        () => mockFile.writeTargetFile(
          outOfFileVariables: any(named: 'outOfFileVariables'),
          targetDir: any(named: 'targetDir'),
          logger: any(named: 'logger'),
          fileSystem: any(named: 'fileSystem'),
          partials: any(named: 'partials'),
          sourceFile: any(named: 'sourceFile'),
          dirs: any(named: 'dirs'),
        ),
      ).called(1);

      verify(() => mockSource.watcher).called(1);
      verify(
        () => mockSource.mergeFilesAndConfig([mockFile], logger: mockLogger),
      ).called(1);
      verify(
        () => mockSource.fromSourcePath(filePath),
      ).called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
      verifyNoMoreInteractions(mockFile);
      verifyNoMoreInteractions(mockSource);
    });

    test(
        'uses default directory bricks/{name}/__brick__ when path not provided',
        () {
      final testBrick = Brick(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        files: [BrickFile(filePath)],
        fileSystem: fs,
      );

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      final targetFile = fs.file(join(brickPath, filePath));

      expect(targetFile.existsSync(), isFalse);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(targetFile.existsSync(), isTrue);

      verify(() => mockLogger.progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    test('uses provided path for output when provided', () {
      final testBrick = Brick(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        files: [BrickFile(filePath)],
        fileSystem: fs,
      );

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      const output = 'out';

      final targetFile = fs.file(
        join(output, brickName, '__brick__', filePath),
      );

      expect(targetFile.existsSync(), isFalse);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook(output: output);

      expect(targetFile.existsSync(), isTrue);

      verify(() => mockLogger.progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    test('deletes directory if exists', () {
      final testBrick = Brick(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        files: [BrickFile(filePath)],
        fileSystem: fs,
      );

      final fakeSourcePath = fs.file(
        testBrick.source.fromSourcePath(testBrick.files.single.path),
      );

      final fakeUnneededFile = fs.file(join(brickPath, 'unneeded.dart'));

      expect(fakeUnneededFile.existsSync(), isFalse);

      fakeUnneededFile.createSync(recursive: true);

      expect(fakeUnneededFile.existsSync(), isTrue);

      fs.file(fakeSourcePath).createSync(recursive: true);

      testBrick.cook();

      expect(fakeUnneededFile.existsSync(), isFalse);

      verify(() => mockLogger.progress('Writing Brick: super_awesome'))
          .called(1);
      verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
          .called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    test('loops through files to write', () {
      const files = ['file1.dart', 'file2.dart', 'file3.dart'];

      for (final file in files) {
        final fakeSourcePath = fs.file(join(localPath, file));

        fs.file(fakeSourcePath).createSync(recursive: true);
      }

      final testBrick = Brick(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        files: [for (final file in files) BrickFile(file)],
        fileSystem: fs,
      );

      for (final file in testBrick.files) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isFalse);
      }

      testBrick.cook();

      for (final file in testBrick.files) {
        expect(fs.file(join(brickPath, file.path)).existsSync(), isTrue);
      }

      verify(() => mockLogger.progress('Writing Brick: super_awesome'))
          .called(1);

      verify(() => mockProgress.complete('super_awesome: cooked 3 files'))
          .called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    test('loops through partials to write', () {
      const files = ['file1.dart', 'path/file2.dart', 'path/to/file3.dart'];

      for (final file in files) {
        final fakeSourcePath = fs.file(join(localPath, file));

        fs.file(fakeSourcePath).createSync(recursive: true);
      }

      final testBrick = Brick(
        name: brickName,
        logger: mockLogger,
        source: BrickSource.memory(
          localPath: localPath,
          fileSystem: fs,
        ),
        partials: [for (final file in files) Partial(path: file)],
        fileSystem: fs,
      );

      for (final partial in testBrick.partials) {
        expect(
          fs.file(join(brickPath, partial.toPartialFile())).existsSync(),
          isFalse,
        );
      }

      testBrick.cook();

      for (final partial in testBrick.partials) {
        expect(
          fs.file(join(brickPath, partial.toPartialFile())).existsSync(),
          isTrue,
        );

        expect(
          fs.file(join(brickPath, partial.path)).existsSync(),
          isFalse,
        );
      }

      verify(() => mockLogger.progress('Writing Brick: super_awesome'))
          .called(1);
      verify(
        () => mockLogger.warn(
          'Unused partials ("file1.dart", "file2.dart", "file3.dart") in super_awesome',
        ),
      ).called(1);

      verify(() => mockProgress.complete('super_awesome: cooked 3 files'))
          .called(1);

      verifyNoMoreInteractions(mockLogger);
      verifyNoMoreInteractions(mockProgress);
    });

    group('#defaultVariables write', () {
      test('files', () {
        const filePath = 'file1.dart';
        const file = BrickFile.config(
          filePath,
          variables: [Variable(name: 'name', placeholder: '_VAL_')],
        );

        fs.file(join(localPath, filePath))
          ..createSync(recursive: true)
          ..writeAsStringSync('_VAL_ $kIndexValue');

        final targetFile = fs.file(join(brickPath, file.path));

        Brick(
          name: brickName,
          logger: mockLogger,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
          ),
          files: const [file],
          fileSystem: fs,
        ).cook();

        const expected = '{{name}} {{.}}';

        expect(targetFile.readAsStringSync(), expected);

        verify(() => mockLogger.progress('Writing Brick: super_awesome'))
            .called(1);

        verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
            .called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockProgress);
      });

      test('partials', () {
        const file = 'file1.dart';
        const partial = Partial(path: file);

        fs.file(join(localPath, file))
          ..createSync(recursive: true)
          ..writeAsStringSync(kIndexValue);

        final targetFile = fs.file(join(brickPath, partial.toPartialFile()));

        Brick(
          name: brickName,
          logger: mockLogger,
          source: BrickSource.memory(
            localPath: localPath,
            fileSystem: fs,
          ),
          partials: const [partial],
          fileSystem: fs,
        ).cook();

        const expected = '{{.}}';

        expect(targetFile.readAsStringSync(), expected);

        verify(() => mockLogger.progress('Writing Brick: super_awesome'))
            .called(1);
        verify(
          () => mockLogger
              .warn('Unused partials ("file1.dart") in super_awesome'),
        ).called(1);

        verify(() => mockProgress.complete('super_awesome: cooked 1 file'))
            .called(1);

        verifyNoMoreInteractions(mockLogger);
        verifyNoMoreInteractions(mockProgress);
      });
    });
  });

  group('#allBrickVariables', () {
    test('ignores dot annotation', () {
      final brick = Brick(
        name: '',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
        files: const [
          BrickFile.config(
            '',
            variables: [
              Variable(name: 'var1.sup'),
              Variable(name: 'var1.yo'),
              Variable(name: 'var1.hi'),
            ],
          ),
        ],
      );

      expect(brick.allBrickVariables(), {'var1'});

      verifyNoMoreInteractions(mockLogger);
    });

    group('files', () {
      test('gets #variables from files', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          files: const [
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #variables from partials', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          partials: const [
            Partial(
              path: '',
              variables: [
                Variable(name: 'var1'),
                Variable(name: 'var2'),
                Variable(name: 'var3'),
              ],
            ),
            Partial(
              path: '',
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #includeIf', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          files: const [
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #includeIfNot', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          files: const [
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #name', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          files: [
            BrickFile.config(
              '',
              name: Name('var1', section: 'section'),
            ),
            BrickFile.config(
              '',
              name: Name('var2', invertedSection: 'invertedSection'),
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'var1',
            'var2',
            'section',
            'invertedSection',
          },
        );

        verifyNoMoreInteractions(mockLogger);
      });
    });

    group('dirs', () {
      test('gets #names', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          dirs: [
            BrickDir(name: Name('name1', section: 'section'), path: ''),
            BrickDir(
              name: Name('name2', invertedSection: 'invertedSection'),
              path: '',
            ),
          ],
        );

        expect(
          brick.allBrickVariables(),
          {
            'name1',
            'name2',
            'section',
            'invertedSection',
          },
        );

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #includeIf', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          dirs: [
            BrickDir(
              path: '',
              includeIf: 'var1',
            ),
            BrickDir(
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

        verifyNoMoreInteractions(mockLogger);
      });

      test('gets #includeIfNot', () {
        final brick = Brick(
          name: '',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          dirs: [
            BrickDir(
              path: '',
              includeIfNot: 'var1',
            ),
            BrickDir(
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
    late BrickYamlConfig mockBrickYamlConfig;

    setUp(() {
      printLogs = [];

      mockBrickYamlConfig = MockBrickYamlConfig();
    });

    test('returns when shouldSync is false', () {
      Brick(
        name: '',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: false);

      expect(printLogs, isEmpty);
    });

    test('returns when brickYamlConfig is null', () {
      Brick(
        name: '',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);

      expect(printLogs, isEmpty);
    });

    test('warns when data returns null in reading brick.yaml file', () {
      when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
          .thenReturn(null);
      verifyNever(() => mockLogger.warn(any()));

      Brick(
        name: '',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        brickYamlConfig: mockBrickYamlConfig,
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);
    });

    test('warns when names are not in sync', () {
      when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
          .thenReturn(const BrickYamlData(name: 'Master Skywalker', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => mockLogger.warn(any()));

      Brick(
        name: 'Master Yoda',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        brickYamlConfig: mockBrickYamlConfig,
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);

      verify(
        () => mockLogger.warn(
          '`name` (Master Skywalker) in brick.yaml does not '
          'match the name in brick_oven.yaml (Master Yoda)',
        ),
      ).called(1);

      verify(() => mockLogger.err('brick.yaml is out of sync')).called(1);
    });

    test('alerts when brick.yaml is in sync', () {
      when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => mockLogger.info(any()));

      Brick(
        name: 'Count Dooku',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        brickYamlConfig: mockBrickYamlConfig,
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => mockLogger.warn(any()));
      verifyNever(() => mockLogger.err(any()));
      verify(() => mockLogger.info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    test('ignores extra default variables', () {
      when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));

      when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

      verifyNever(() => mockLogger.info(any()));

      Brick(
        name: 'Count Dooku',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        files: [
          BrickFile.config(
            '',
            variables: [
              ...Brick.defaultVariables,
              const Variable(name: '_INDEX_VALUE_'),
              const Variable(name: '.'),
            ],
          ),
        ],
        brickYamlConfig: mockBrickYamlConfig,
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => mockLogger.warn(any()));
      verifyNever(() => mockLogger.err(any()));
      verify(() => mockLogger.info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    test('ignores $BrickYamlConfig.ignoreVars from sync', () {
      when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
          .thenReturn(const BrickYamlData(name: 'Count Dooku', vars: []));
      when(() => mockBrickYamlConfig.ignoreVars).thenReturn(['favorite_color']);

      verifyNever(() => mockLogger.info(any()));

      Brick(
        name: 'Count Dooku',
        source: BrickSource.none(
          fileSystem: MemoryFileSystem(),
        ),
        files: const [
          BrickFile.config(
            '',
            variables: [
              Variable(name: 'favorite_color', placeholder: '_FAVORITE_COLOR_'),
            ],
          ),
        ],
        brickYamlConfig: mockBrickYamlConfig,
        logger: mockLogger,
        fileSystem: MemoryFileSystem(),
      ).checkBrickYamlConfig(shouldSync: true);

      verifyNever(() => mockLogger.warn(any()));
      verifyNever(() => mockLogger.err(any()));
      verify(() => mockLogger.info(darkGray.wrap('brick.yaml is in sync')))
          .called(1);
    });

    group('alerts when brick.yaml is in out of sync', () {
      test('when brick.yaml contains extra variables', () {
        when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
            .thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: ['var1', 'var2'],
          ),
        );

        when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

        verifyNever(() => mockLogger.warn(any()));
        verifyNever(() => mockLogger.err(any()));

        Brick(
          name: 'Count Dooku',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          brickYamlConfig: mockBrickYamlConfig,
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
        ).checkBrickYamlConfig(shouldSync: true);

        verify(
          () => mockLogger.warn(
            darkGray.wrap(
              'Variables ("var1", "var2") exist in brick.yaml but not in brick_oven.yaml',
            ),
          ),
        ).called(1);

        verify(
          () => mockLogger.err('brick.yaml is out of sync'),
        ).called(1);
      });

      test('when brick_oven.yaml contains extra variables', () {
        when(() => mockBrickYamlConfig.data(logger: any(named: 'logger')))
            .thenReturn(
          const BrickYamlData(
            name: 'Count Dooku',
            vars: [],
          ),
        );

        when(() => mockBrickYamlConfig.ignoreVars).thenReturn([]);

        verifyNever(() => mockLogger.warn(any()));
        verifyNever(() => mockLogger.err(any()));

        Brick(
          name: 'Count Dooku',
          source: BrickSource.none(
            fileSystem: MemoryFileSystem(),
          ),
          brickYamlConfig: mockBrickYamlConfig,
          logger: mockLogger,
          fileSystem: MemoryFileSystem(),
          dirs: [
            BrickDir(
              name: Name('var1'),
              includeIf: 'var2',
              path: '',
            ),
          ],
        ).checkBrickYamlConfig(shouldSync: true);

        verify(
          () => mockLogger.warn(
            darkGray.wrap(
              'Variables ("var1", "var2") exist in brick_oven.yaml but not in brick.yaml',
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
